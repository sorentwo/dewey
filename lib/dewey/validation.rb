module Dewey
  
  class Validation
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
  end
end