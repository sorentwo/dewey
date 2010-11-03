require 'uri'
require 'net/https'
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
      response = http_request(:get, url, headers)
      
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
    # @return [String, nil] The id if upload was successful, nil otherwise
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
  
      response = http_request(:post, GOOGLE_FEED_URL, headers, file.read.to_s)
 
      if response.kind_of?(Net::HTTPCreated)
        extract_ids(response.body).first
      else
        nil
      end
    end

    # The same as `put`, except it will raise an exception if the request fails.
    #
    # @see put
    def put!(file, options = {})
      put(file, options) || raise(DeweyException, "Unable to put document")
    end

    # Download a file. You may optionally specify a format for export.
    #
    # @param [String] query    A resource id or title, `document:12345` or
    #                          `My Document` for example
    # @param [Hash]   options  Options for downloading the document
    # @option options [Symbol] :format The output format
    # 
    # @return [Tempfile, nil] The downloaded file, otherwise `nil` if the file
    #                         couldn't be found.
    #
    # @see Dewey::Validation::DOCUMENT_EXPORT_FORMATS
    # @see Dewey::Validation::SPREADSHEET_EXPORT_FORMATS
    # @see Dewey::Validation::PRESENTATION_EXPORT_FORMATS
    def get(query, options = {})
      resource_id = is_id?(query) ? query : search(query, :exact => true).first

      return nil if resource_id.nil?

      service, id = resource_id.split(':')
      format      = options[:format].to_s
      url         = ''

      case service
      when 'document'
        url << GOOGLE_DOCUMENT_URL
        url << "?docID=#{id}"
      when 'drawing'
        url << GOOGLE_DRAWING_URL
        url << "?docID=#{id}"
      when 'presentation'
        url << GOOGLE_PRESENTATION_URL
        url << "?docID=#{id}"
      when 'spreadsheet'
        url << GOOGLE_SPREADSHEET_URL
        url << "?key=#{id}"
      else
        raise DeweyException, "Invalid service: #{service}"
      end

      unless format.empty?
        if Dewey::Validation.valid_export_format?(format, service)
          url << "&exportFormat=#{format}"
          url << "&format=#{format}"       if service == 'document'
          url << "&gid=#{options[:sheet]}" if service == 'spreadsheet' && options[:sheet]
        else
          raise DeweyException, "Invalid format: #{format}" 
        end
      end

      response = http_request(:get, url, base_headers(true, service))
      
      if response.kind_of?(Net::HTTPOK)
        file = Tempfile.new([id, format].join('.'))
        file.binmode
        file.write(response.body)
        file.rewind
        file
      else
        nil
      end
    end

    # Deletes a document. The default behavior is to delete the document
    # permanently, rather than trashing it. 
    #
    # @param [String] query    A resource id or title. If a title is provided
    #                          a search will be performed automatically.
    # @param [Hash]   options  Options for deleting the document
    # @option options [Symbol] :trash If `true` the resource will be sent to
    #                          the trash, rather than being permanently deleted.
    #
    # @return [Boolean] `true` if delete was successful, `false` otherwise
    def delete(query, options = {})

      # We use 'If-Match' => '*' to make sure we delete regardless of others
      headers = base_headers(false).merge({'If-Match' => '*'}) 
      trash   = options.delete(:trash) || false
      id      = (is_id?(query)) ? query : search(query, :exact => true).first
      
      return false if id.nil?

      url   = "#{GOOGLE_FEED_URL}/#{Dewey::Utils.escape(id)}"
      url << "?delete=true" unless trash

      response = http_request(:delete, url, headers)
  
      response.kind_of?(Net::HTTPOK)
    end
    
    # The same as delete, except that it will raise `Dewey::DeweyException` if
    # the request fails.
    # 
    # @see #delete
    def delete!(query, options = {})
      delete(query, options) || raise(DeweyException, "Unable to delete document")
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

    # Present for simplified testing
    def authenticator #:nodoc:
      @@authenticator
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
    def base_headers(form = true, service = nil) #:nodoc:
      base = {}
      base['GData-Version'] = '3.0'
      base['Content-Type']  = 'application/x-www-form-urlencoded'         if form
      base['Authorization'] = "GoogleLogin auth=#{authenticator.token(service)}"
  
      base
    end

    # Parse the XML returned to pull out one or more document ids.
    #
    # @param  [String] response An XML feed document
    # @return [Array]  Array of document ids
    def extract_ids(response) #:nodoc:
      xml = REXML::Document.new(response)
      xml.elements.collect('//entry//id') { |e| e.text.split('/').last.gsub('%3A', ':') }
    end

    # Is the string an id or a search query?
    def is_id?(string)
      string.match(/^[a-z]+:.+$/)
    end
  end
end
