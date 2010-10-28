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
   
    # Queries the document list for a particular title. Titles can be either 
    # full or partial matches. Matches are returned as an array of ids.
    #
    # @param [String] query   The title to be matched
    # @param [Hash]   options Search options
    # @option options [Symbol] :exact Setting this to `true` will force an
    #   exact match, with a maximum of one id returned
    #
    # @return [Array] An array of matched ids. No matches return an empty array
    def search(query, options = {})
      title    = query.gsub(/\s+/, '+')
      headers  = base_headers(false)
      url      = "#{GOOGLE_FEED_URL}?title=#{title}"
      url     << "&title-exact=true" if options[:exact]
      response = get_request(url, headers)
      
      response.kind_of?(Net::HTTPOK) ? extract_ids(response.body) : []
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

    # Deletes a document referenced by id.
    #
    # @param [String] id An id matching a document
    #
    # @return [Boolean] `true` if delete was successful, `false` otherwise
    def delete(id)
      headers = base_headers(false)
      headers['If-Match'] = '*' # We don't care if others have modified
  
      url  = ''
      url << GOOGLE_FEED_URL
      url << "/#{Dewey::Utils.escape(id)}?delete=true"

      response = delete_request(url, headers)
  
      response.kind_of?(Net::HTTPOK)
    end
    
    # The same as delete, except that it will raise `Dewey::DeweyException` if
    # the request fails.
    # 
    # @see #delete
    def delete!(id)
      delete(id) || raise(DeweyException, "Unable to delete document")
    end

    [:search, :put, :get, :delete].each do |method|
      aliased = "no_auto_authenticate_#{method.to_s}".to_sym 
      alias_method aliased, method
      
      self.class_eval(%Q{
        def #{method} *args
          authenticate! unless authenticated?
          #{aliased}(*args)
        end
      })
    end

    # Convenience method for `put`, `get`, `delete`.
    #
    # @param [File] file The file that will be converted
    # @param [Hash] options Options for conversion
    # @option options [Symbol] :title  The title that the file will be stored
    #   under. Only useful if the conversion fails.
    # @option options [Symbol] :format Format to convert to.
    #
    # @return [Tempfile] The converted file
    #
    # @see #put
    # @see #get
    # @see #delete
    def convert(file, options = {})
      id = put(file, options[:title])
      converted = get(id, options[:format])
  
      delete(id)
  
      converted
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
