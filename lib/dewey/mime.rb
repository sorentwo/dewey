module Dewey

  DOCUMENT_MIMETYPES = {
    :doc  => ['application/msword', 'application/vnd.ms-office'],
    :docx => ['application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/x-docx', 'application/zip'],
    :htm  => 'text/html',
    :html => 'text/html',
    :odt  => 'application/vnd.oasis.opendocument.text',
    :pdf  => 'application/pdf',
    :rtf  => 'application/rtf',
    :sxw  => 'application/vnd.sun.xml.writer',
    :txt  => 'text/plain'
  }

  DRAWING_MIMETYPES = {
    :jpeg => 'image/jpeg',
    :png  => 'image/png',
    :svg  => 'image/svg+xml'
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
    # Determine file extension by parsing the filename. When the filename has no extension,
    # then instead examine the file's mime type and intuit the extension.
    def self.extension(file)
      extension = File.extname(file.path).sub('.', '')
      if extension.nil? || extension == ''
        mime_type = (`file --mime-type #{file.path}`).split(':').last.strip
        extension = mime_type_to_extension_mapping[mime_type]
      end
      extension.to_s.downcase
    end

    # Attempts to provide a mime_type that Google Docs finds acceptable. Certain
    # types, when gathered from +file+ require extra coercion and will be handled
    # automatically.
    def self.mime_type(file)
      type = case extension(file)
      when /csv/  then SPREADSHEET_MIMETYPES[:csv]
      when /doc$/ then DOCUMENT_MIMETYPES[:doc]
      when /docx/ then DOCUMENT_MIMETYPES[:docx]
      when /jpeg/ then DRAWING_MIMETYPES[:jpeg]
      when /htm/  then DOCUMENT_MIMETYPES[:html]
      when /ods/  then SPREADSHEET_MIMETYPES[:ods]
      when /odt/  then DOCUMENT_MIMETYPES[:odt]
      when /pdf/  then DOCUMENT_MIMETYPES[:pdf]
      when /png/  then DRAWING_MIMETYPES[:png]
      when /pps/  then PRESENTATION_MIMETYPES[:pps]
      when /ppt/  then PRESENTATION_MIMETYPES[:ppt]
      when /rtf/  then DOCUMENT_MIMETYPES[:rtf]
      when /svg/  then DRAWING_MIMETYPES[:svg]
      when /sxw/  then DOCUMENT_MIMETYPES[:sxw]
      when /tab/  then SPREADSHEET_MIMETYPES[:tab]
      when /tsv/  then SPREADSHEET_MIMETYPES[:tsv]
      when /txt/  then DOCUMENT_MIMETYPES[:txt]
      when /xls$/ then SPREADSHEET_MIMETYPES[:xls]
      when /xlsx/ then SPREADSHEET_MIMETYPES[:xlsx]
      end
      type.is_a?(Array) ? type.first : type
    end
    
    # Merges then inverts all the mime type constants to make a new hash with mime types as keys
    # and the corresponding file extensions as values. For example this:
    # 
    #   :doc  => ['application/msword', 'application/vnd.ms-office'],
    #   
    # Becomes:
    # 
    #   'application/msword' => :doc, 
    #   'application/vnd.ms-office' => :doc
    # 
    # This is useful for intuiting file extensions based on mime types, which is handy when the
    # filename doesn't have an extension (e.g. when doing post-processing with paperclip).
    # 
    def self.mime_type_to_extension_mapping
      doc_types = [DOCUMENT_MIMETYPES, DRAWING_MIMETYPES, PRESENTATION_MIMETYPES, SPREADSHEET_MIMETYPES]
      extensions = {}
      mime_types = {}
      doc_types.each { |doc_type| extensions.merge!(doc_type) }

      extensions.each do |extension, mime|
        if mime.is_a?(Array)
          mime.each { |m| mime_types[m] = extension }
        else
          mime_types[mime] = extension
        end
      end
      mime_types
    end

    def self.guess_service(mime_type)
      services = { :document     => DOCUMENT_MIMETYPES,
                   :drawing      => DRAWING_MIMETYPES,
                   :presentation => PRESENTATION_MIMETYPES,
                   :spreadsheet  => SPREADSHEET_MIMETYPES }

      services.each_key do |service|
        return service if services[service].values.flatten.include?(mime_type)
      end

      nil
    end
  end
end
