require 'uri'
require 'net/https'
require 'open-uri'
require 'rexml/document'
require 'tempfile'

module Dewey
  class Document
    attr_accessor :account, :password, :token
  
    # Options specified in +opts+ consist of:
    #
    # * :account - The Google Doc's account that will be used for authentication.
    #   This will most typically be a gmail account, i.e. +example@gmail.com+
    # * :password - The password for the Google Doc's account.
    def initialize(options = {})
      @account  = options[:account]
      @password = options[:password]
    end
  
    # Returns true if this instance has been authorized
    def authorized?
      !! @token
    end
  
    # Gets an authorization token for this instance. Raises an error if no
    # credentials have been provided, +false+ if authorization fails, and +true+ if
    # authorization is successful.
    def authorize!
      if @account.nil? || @password.nil?
        raise DeweyException, "Account or password missing."
      end
    
      url = URI.parse(GOOGLE_LOGIN_URL)
      params = { 'accountType' => 'HOSTED_OR_GOOGLE', 'Email' => @account,
                 'Passwd' => @password, 'service'=> 'writely' }
    
      response = Net::HTTPS.post_form(url, params)
    
      case response
      when Net::HTTPSuccess
        @token = response.body.split('=').last
        true
      when Net::HTTPForbidden
        false
      else
        raise DeweyException, "Unexpected response: #{response}"
      end
    end
  
    # Upload a file to the account. A successful upload will return the resource
    # id, which is useful for downloading the file without doing a title search.
    # * file  - A File reference
    # * title - An alternative title, to be used instead of the filename
    def put(file, title = nil)
      authorize! unless authorized?
    
      extension = File.extname(file.path).sub('.', '')
      basename  = File.basename(file.path, ".#{extension}")
      mimetype  = Dewey::Mime.mime_type(file)
      service   = Dewey::Mime.guess_service(mimetype)
    
      title ||= basename
    
      raise DeweyException, "Invalid file type: #{extension}" unless Dewey::Validation.valid_upload_format?(extension, service)
    
      headers = base_headers
      headers['Content-Length'] = File.size?(file).to_s
      headers['Slug']           = Dewey::Utils.escape(title)
      headers['Content-Type']   = mimetype unless mimetype =~ /Can't expand summary_info/
    
      # Rewind the file in the case of multiple uploads, or conversions
      file.rewind
    
      response = post_request(GOOGLE_FEED_URL, file.read.to_s, headers)
    
      case response
      when Net::HTTPCreated
        extract_rid(response.body)
      else
        false
      end
    end
  
    alias :upload :put
  
    # Download, or export more accurately, a file to a specified format
    # * rid    - A resource id, for example +document:12345+
    # * format - The output format, see *_EXPORT_FORMATS for possiblibilites
    def get(rid, format = nil)
      authorize! unless authorized?
    
      spreadsheet = !! rid.match(/^spreadsheet/)
      id = rid.sub(/[a-z]+:/, '')
    
      url  = ''
      url << (spreadsheet ? GOOGLE_SPREADSHEET_URL : GOOGLE_DOCUMENT_URL)
      url << (spreadsheet ? "?key=#{id}" : "?docID=#{id}")
      url << "&exportFormat=#{format.to_s}" unless format.nil?
    
      headers = base_headers
    
      file = Tempfile.new([rid, format].join('.'))
      file.binmode
    
      open(url, headers) { |data| file.write data.read }
    
      file
    end
  
    alias :download :get
  
    # Deletes a document referenced either by resource id or by name.
    # * id - A resource id or exact file name matching a document in the account
    def delete(id)
      authorize! unless authorized?
    
      headers = base_headers
      headers['If-Match'] = '*' # We don't care if others have modified
    
      url = GOOGLE_FEED_URL + "/#{Dewey::Utils.escape(id)}?delete=true"
      response = delete_request(url, headers)
    
      case response
      when Net::HTTPOK
        true
      else
        false
      end
    end
  
    # Convenience method for +put+, +get+, +delete+. Returns a Tempfile
    # with in the provided type. Note that if you omit the format option it will
    # simply upload the file and return it.
    # * file    - The file that will be converted
    # * options - Takes :title and :format. See +upload+ for title, and +download+
    #             for format.
    def convert(file, options = {})
      rid = put(file, options[:title])
      con = get(rid, options[:format])
    
      delete(rid)
    
      con
    end
  
    private
  
    def post_request(url, data, headers) #:nodoc:
      http_request(:post, url, headers, data)
    end
  
    def delete_request(url, headers) #:nodoc:
      http_request(:delete, url, headers)
    end
  
    def http_request(method, url, headers, data = nil) #:nodoc:      
      url = URI.parse(url) if url.kind_of? String

      connection = (url.scheme == 'https') ? Net::HTTPS.new(url.host, url.port) : Net::HTTP.new(url.host, url.port)
    
      case method
      when :post
        connection.post(url.path, data, headers)
      when :delete
        connection.delete(url.path, headers)
      else
        raise DeweyException, "Invalid request type. Valid options are :post and :delete"
      end
    end
  
    def base_headers #:nodoc:
      base = {}
      base['GData-Version'] = '3.0'
      base['Content-Type']  = 'application/x-www-form-urlencoded'
      base['Authorization'] = "GoogleLogin auth=#{@token}" if authorized?
    
      base
    end
  
    def extract_rid(response) #:nodoc:
      xml = REXML::Document.new(response)
    
      begin
        "#{$1}:#{$2}" if xml.elements['//id'].text =~ /.*(document|spreadsheet|presentation)%3A([0-9a-zA-Z_-]+)$/
      rescue 
        raise DeweyException, "id could not be extracted from: #{response}"
      end
    end
  end
end