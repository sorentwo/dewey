require 'uri'
require 'net/https'
require 'open-uri'
require 'rexml/document'
require 'tempfile'

module Dewey
  class << self
    
    # Set the authentication strategy. You can currently only use ClientAuth,
    # but you must provide +email+ and +password+ options. You must set up
    # authentication before using any file operations.
    #
    def authentication(strategy, options)
      case strategy
      when :client
        @@authenticator = Dewey::ClientAuth.new(options[:email], options[:password])
      end
    end
    
    # Report whether Dewey has both an authentication strategy selected, and has
    # been authenticated. Delegates to the chosen authenticator.
    #
    def authenticated?
      !@@authenticator.nil? && @@authenticator.authenticated?
    end
    
    # Tell the authentication strategy to authenticate. Not necessary though, as
    # any file operation will authenticate automatically.
    #
    def authenticate!
      @@authenticator.authenticate!
    end
   
    def search(query, options = {})
      authenticate! unless authenticated?
      
      title    = query.gsub(/\s+/, '+')
      headers  = base_headers(false)
      url      = "#{GOOGLE_FEED_URL}?title=#{title}"
      url     << "&title-exact=true" if options[:exact]
      response = get_request(url, headers)
      
      case response
      when Net::HTTPOK
        extract_ids(response.body)
      else
        nil
      end
    end

    # Upload a file to the account. A successful upload will return the resource
    # id, which is useful for downloading the file without doing a title search.
    #
    # @param [File] file    An IOStream object that responds to path, size
    # @param [Hash] options Options for uploading the file
    # @option options [Symbol] :title An alternative title, to be used instead
    #                                 of the filename
    # 
    # @return [String, Boolean] The id if upload was successful, false otherwise
    def put(file, options = {})
      authenticate! unless authenticated?
  
      extension = File.extname(file.path).sub('.', '')
      basename  = File.basename(file.path, ".#{extension}")
      mimetype  = Dewey::Mime.mime_type(file)
      service   = Dewey::Mime.guess_service(mimetype)
      title     = options[:title] || basename
  
      raise DeweyException, "Invalid file type: #{extension}" unless Dewey::Validation.valid_upload_format?(extension, service)
  
      headers = base_headers
      headers['Content-Length'] = File.size?(file).to_s
      headers['Slug']           = Dewey::Utils.escape(title)
      headers['Content-Type']   = mimetype unless mimetype =~ /Can't expand summary_info/
  
      # Rewind the file in the case of multiple uploads, or conversions
      file.rewind
  
      response = post_request(GOOGLE_FEED_URL, file.read.to_s, headers)
 
      if response.kind_of?(Net::HTTPCreated)
        extract_ids(response.body).first
      else
        false
      end
    end

    # Download a file. You may optionally specify a format for export.
    #
    # @param [String] id       A resource id, for example `document:12345`
    # @param [Hash]   options  Options for downloading the document
    # @option options [Symbol] :format The output format
    # 
    # @return [Tempfile] The downloaded file
    #
    # @see Dewey::Validation::DOCUMENT_EXPORT_FORMATS
    # @see Dewey::Validation::SPREADSHEET_EXPORT_FORMATS
    # @see Dewey::Validation::PRESENTATION_EXPORT_FORMATS
    def get(id, options = {})
      authenticate! unless authenticated?
  
      # This is pretty hackish. Will need re-working with presentation support
      spreadsheet = !! id.match(/^spreadsheet/)
      
      id.sub!(/[a-z]+:/, '')
      
      format = options[:format].to_s

      url  = ''
      url << (spreadsheet ? GOOGLE_SPREADSHEET_URL : GOOGLE_DOCUMENT_URL)
      url << (spreadsheet ? "?key=#{id}" : "?docID=#{id}")
      url << "&exportFormat=#{format}" unless format.blank?
  
      headers = base_headers
  
      file = Tempfile.new([id, format].join('.'))
      file.binmode
  
      open(url, headers) { |data| file.write data.read }
  
      file
    end

    # Deletes a document referenced either by resource id.
    # * id - A resource id or exact file name matching a document in the account
    #
    def delete(id)
      authenticate! unless authenticated?
  
      headers = base_headers(false)
      headers['If-Match'] = '*' # We don't care if others have modified
  
      url  = ''
      url << GOOGLE_FEED_URL
      url << "/#{Dewey::Utils.escape(id)}?delete=true"

      response = delete_request(url, headers)
  
      case response
      when Net::HTTPOK
        true
      else
        false
      end
    end
    
    # The same as delete, except that it will raise +Dewey::DeweyException+ if
    # the request fails.
    #
    def delete!(id)
      delete(id) || raise(DeweyException, "Unable to delete document")
    end

    # Convenience method for +put+, +get+, +delete+. Returns a Tempfile
    # with in the provided type. Note that if you omit the format option it will
    # simply upload the file and return it.
    # * file    - The file that will be converted
    # * options - Takes :title and :format. See +upload+ for title, and +download+ for format.
    #
    def convert(file, options = {})
      rid = put(file, options[:title])
      con = get(rid, options[:format])
  
      delete(rid)
  
      con
    end

    protected
   
    def get_request(url, headers) #:nodoc:
      http_request(:get, url, headers)
    end

    def post_request(url, data, headers) #:nodoc:
      http_request(:post, url, headers, data)
    end

    def delete_request(url, headers) #:nodoc:
      http_request(:delete, url, headers)
    end

    def http_request(method, url, headers, data = nil) #:nodoc:      
      url = URI.parse(url) if url.kind_of? String

      connection = (url.scheme == 'https') ? Net::HTTPS.new(url.host, url.port) : Net::HTTP.new(url.host, url.port)
      full_path  = url.path
      full_path << "?#{url.query}" unless url.query.nil?

      case method
      when :get
        connection.get(full_path, headers)
      when :post
        connection.post(full_path, data, headers)
      when :delete
        connection.delete(full_path, headers)
      else
        raise DeweyException, "Invalid request type. Valid options are :get, :post and :delete"
      end
    end

    # A hash of default headers. Considers authentication and put/post headers.
    #
    # @param [Boolean] form If true the Content-Type will be set accordingly
    # @return [Hash] Headers hash
    def base_headers(form = true) #:nodoc:
      base = {}
      base['GData-Version'] = '3.0'
      base['Content-Type']  = 'application/x-www-form-urlencoded'         if form
      base['Authorization'] = "GoogleLogin auth=#{@@authenticator.token}" if authenticated?
  
      base
    end

    # Parse the XML returned to pull out one or more document ids.
    #
    # @param  [String] response An XML feed document
    # @return [Array]  Array of document ids
    def extract_ids(response) #:nodoc:
      xml = REXML::Document.new(response)
      xml.elements.collect('//id') { |e| e.text.gsub('%3A', ':') }.reject(&:blank?)
    end
  end
end
