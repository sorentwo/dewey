module Dewey
  
  DOCUMENT_MIMETYPES = {
    :doc  => 'application/msword',
    :docx => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    :htm  => 'text/html',
    :html => 'text/html',
    :odt  => 'application/vnd.oasis.opendocument.text',
    :pdf  => 'application/pdf',
    :rtf  => 'application/rtf',
    :sxw  => 'application/vnd.sun.xml.writer',
    :txt  => 'text/plain'
  }
  
  PRESENTATION_MIMETYPES = {
    :pps => 'application/vnd.ms-powerpoint',
    :ppt => 'application/vnd.ms-powerpoint'
  }
  
  SPREADSHEET_MIMETYPES = {
    :csv  => 'text/csv',
    :ods  => 'application/x-vnd.oasis.opendocument.spreadsheet',
    :tab  => 'text/tab-separated-values',
    :tsv  => 'text/tab-separated-values',
    :xls  => 'application/vnd.ms-excel',
    :xlsx => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  }
  
  class Mime
    # Attempts to provide a mime_type that Google Docs finds acceptable. Certain
    # types, when gathered from +file+ require extra coercion and will be handled
    # automatically.
    def self.mime_type(file)
      type = (file.path.match(/\.(\w+)/)[1] rescue '').downcase
      case type
      when /csv/  then SPREADSHEET_MIMETYPES[:csv]
      when /doc$/ then DOCUMENT_MIMETYPES[:doc]
      when /docx/ then DOCUMENT_MIMETYPES[:docx]
      when /htm/  then DOCUMENT_MIMETYPES[:html]
      when /ods/  then SPREADSHEET_MIMETYPES[:ods]
      when /odt/  then DOCUMENT_MIMETYPES[:odt]
      when /pdf/  then DOCUMENT_MIMETYPES[:pdf]
      when /pps/  then PRESENTATION_MIMETYPES[:pps]
      when /ppt/  then PRESENTATION_MIMETYPES[:ppt]
      when /rtf/  then DOCUMENT_MIMETYPES[:rtf]
      when /sxw/  then DOCUMENT_MIMETYPES[:sxw]
      when /tab/  then SPREADSHEET_MIMETYPES[:tab]
      when /tsv/  then SPREADSHEET_MIMETYPES[:tsv]
      when /txt/  then DOCUMENT_MIMETYPES[:txt]
      when /xls$/ then SPREADSHEET_MIMETYPES[:xls]
      when /xlsx/ then SPREADSHEET_MIMETYPES[:xlsx]
      else
        Mime.coerce((`file --mime-type #{file.path}`).split(':').last.strip) rescue "application/#{type}"
      end
    end
    
    # Attempt to take mime types that are known to be guessed incorrectly and
    # cast them to one that Google Docs will accept.
    def self.coerce(mime_type)
      case mime_type
      when /vnd.ms-office/       then 'application/msword'
      when /x-docx/              then 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
      else mime_type
      end
    end
    
    def self.guess_service(mime_type)
      services = { :document     => DOCUMENT_MIMETYPES,
                   :presentation => PRESENTATION_MIMETYPES,
                   :spreadsheet  => SPREADSHEET_MIMETYPES }
      
      services.each_key do |service|
        return service if services[service].has_value?(mime_type)
      end
      
      nil
    end
  end
end