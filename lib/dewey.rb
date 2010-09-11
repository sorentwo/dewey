require 'uri'
require 'net/https'
require 'open-uri'
require 'rexml/document'
require 'tempfile'
require 'dewey/https'
require 'dewey/mime'
require 'dewey/utils'

module Dewey
  GOOGLE_BASE_URL  = "https://www.google.com"
  GOOGLE_DOCS_URL  = "https://docs.google.com"
  GOOGLE_SPRD_URL  = "https://spreadsheets.google.com"
  GOOGLE_LOGIN_URL = GOOGLE_BASE_URL + "/accounts/ClientLogin"
  GOOGLE_FEED_URL  = GOOGLE_DOCS_URL + "/feeds/default/private/full"
  
  GOOGLE_DOCUMENT_URL    = GOOGLE_DOCS_URL + "/feeds/download/documents/Export"
  GOOGLE_SPREADSHEET_URL = GOOGLE_SPRD_URL + "/feeds/download/spreadsheets/Export"
  
  GOOGLE_SERVICES = { :document => 'writely', :spreadsheet => 'wise' }
  
  DOCUMENT_EXPORT_FORMATS     = %w(txt odt pdf html rtf doc png zip)
  PRESENTATION_EXPORT_FORMATS = %w(swf pdf png ppt)
  SPREADSHEET_EXPORT_FORMATS  = %W(xls csv pdf ods tsv html)
  
  class DeweyException < Exception
  end
  
  # Doc
  # This base class handles authentication and requests
  #
  class Document
    attr_accessor :account, :password, :service, :token, :cached
    
    # Determine wether or not a format is available for download.
    #
    # * format  - The file format to check, i.e. 'txt', 'doc', 'pdf'
    # * service - The service that would be used. Must be document, presentation,
    #   or spreadsheet.
    def self.valid_upload_format?(format, service = :document)
      case service
      when :document     then Dewey::DOCUMENT_MIMETYPES.has_key?(format.to_sym)
      when :presentation then Dewey::PRESENTATION_MIMETYPES.has_key?(format.to_sym)
      when :spreadsheet  then Dewey::SPREADSHEET_MIMETYPES.has_key?(format.to_sym)
      else
        raise DeweyException, "Unknown service: #{service}"
      end
    end
    
    # Determine whether or not a format is available for export.
    #
    # * format  - The file format to check, i.e. 'txt', 'doc', 'pdf'
    # * service - The service that would be used. Must be document, presentation,
    #   or spreadsheet.
    def self.valid_export_format?(format, service = :document)
      case service
      when :document     then DOCUMENT_EXPORT_FORMATS.include?(format)
      when :presentation then PRESENTATION_EXPORT_FORMATS.include?(format)
      when :spreadsheet  then SPREADSHEET_EXPORT_FORMATS.include?(format)
      else
        raise DeweyException, "Unknown service: #{service}"
      end
    end
    
    # Create a new Doc object
    # Options specified in +opts+ consist of:
    #
    # * :account - The Google Doc's account that will be used for authentication.
    #   This will most typically be a gmail account, i.e. +example@gmail.com+
    # * :password - The password for the Google Doc's account.
    # * :service - The default service to connect to, either :document or :spreadsheet
    def initialize(options = {})
      @account  = options[:account]
      @password = options[:password]
      @service  = options[:service] || :document
      @cached   = {}
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
                 'Passwd' => @password, 'service'=> GOOGLE_SERVICES[@service] }
      
      response = Net::HTTPS.post_form(url, params)
      
      case response
      when Net::HTTPSuccess
        @token = response.body.split(/=/).last
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
    def upload(file, title = nil)
      extension = File.extname(file.path).sub('.', '')
      basename  = File.basename(file.path, ".#{extension}")
      mimetype  = Dewey::Mime.mime_type(file)
      service   = Dewey::Mime.guess_service(mimetype)
      
      title ||= basename
      
      raise DeweyException, "Invalid file type: #{extension}" unless Dewey::Document.valid_upload_format?(extension, service)
      
      headers = base_headers
      headers['Content-Length'] = File.size?(file).to_s
      headers['Slug']           = Dewey::Utils.escape(title)
      headers['Content-Type']   = mimetype unless mimetype =~ /Can't expand summary_info/
      
      # Rewind the file in the case of multiple uploads, or conversions
      file.rewind
      
      response = post_request(GOOGLE_FEED_URL, file.read.to_s, headers)
      
      case response
      when Net::HTTPCreated
        rid = @cached[basename] = extract_rid(response.body)
      else
        nil
      end
    end
    
    # Download, or export more accurately, a file to a specified format
    # * id     - A resource id or exact file name matching a document in the account
    # * format - The output format, see *_EXPORT_FORMATS for possiblibilites
    def download(id, format = nil)
      spreadsheet = !! id.match(/spreadsheet/)
      
      url  = (spreadsheet ? GOOGLE_SPREADSHEET_URL : GOOGLE_DOCUMENT_URL)
      url << (spreadsheet ? "?key=#{id}" : "?docID=#{id}")
      url << "&exportFormat=#{format.to_s}" unless format.nil?
      
      headers = base_headers
      
      file = Tempfile.new([id, format].join('.'))
      file.binmode
      
      open(url, headers) { |data| file.write data.read }
      
      file
    end
    
    # Deletes a document referenced either by resource id or by name.
    def delete(id)
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
    
    # Convenience method for +upload+, +download+, +delete+. Returns a Tempfile
    # with in the provided type.
    # * file    - The file that will be converted
    # * options - Takes :title and :format. See +upload+ for title, and +download+
    #             for format.
    def convert(file, options = {})
      rid = upload(file, options[:title])
      con = download(rid, options[:format])
      
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
      
      connection = Net::HTTP.new(url.host, url.port)
      connection.use_ssl = (url.scheme == 'https')
      
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
    
    def extract_rid(source) #:nodoc:
      xml = REXML::Document.new(source)
      
      begin
        "#{$1}:#{$2}" if xml.elements['//id'].text =~ /.+(document|spreadsheet|presentation)%3A([0-9a-zA-Z]+)/
      rescue 
        raise DeweyException, "id could not be extracted from: #{body}"
      end
    end
  end
end