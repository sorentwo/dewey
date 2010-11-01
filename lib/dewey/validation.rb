module Dewey
  
  DOCUMENT_EXPORT_FORMATS     = [:txt, :odt, :pdf, :html, :rtf, :doc, :png, :zip]
  DRAWING_EXPORT_FORMATS      = [:jpeg, :pdf, :png, :svg]
  PRESENTATION_EXPORT_FORMATS = [:swf, :pdf, :png, :ppt]
  SPREADSHEET_EXPORT_FORMATS  = [:xls, :csv, :pdf, :ods, :tsv, :html]
  
  # Utility methods to check that a format is accepted for a particular service
  #
  class Validation
    
    class << self
      # Determine wether or not a format is available for download.
      #
      # @param [Symbol] format  The file format to check, i.e. `:txt`, `:doc`, `:pdf`
      # @param [Symbol] service The service that would be used. Must be
      #   `:document`, `:presentation`, or `:spreadsheet`.
      #
      # @return [Boolean] `true` if the format is supported, `false` otherwise
      #
      # @raise [DeweyException] Raised when an unknown service is given
      def valid_upload_format?(format, service = nil)
        format  = format.to_sym
        service = default_service(service)

        case service
        when :document     then Dewey::DOCUMENT_MIMETYPES.has_key?(format)
        when :drawing      then Dewey::DRAWING_MIMETYPES.has_key?(format)
        when :presentation then Dewey::PRESENTATION_MIMETYPES.has_key?(format)
        when :spreadsheet  then Dewey::SPREADSHEET_MIMETYPES.has_key?(format)
        else
          raise DeweyException, "Unknown service: #{service}"
        end
      end

      # Determine whether or not a format is available for export.
      #
      # @param [Symbol] format  The file format to check, i.e. `:txt`, `:doc`, `:pdf`
      # @param [Symbol] service The service that would be used. Must be
      #   `:document`, `:presentation`, or `:spreadsheet`.
      #
      # @return [Boolean] `true` if the format is supported, `false` otherwise
      #
      # @raise [DeweyException] Raised when an unknown service is given
      def valid_export_format?(format, service = nil)
        format  = format.to_sym
        service = default_service(service) 

        case service
        when :document     then Dewey::DOCUMENT_EXPORT_FORMATS.include?(format)
        when :drawing      then Dewey::DRAWING_EXPORT_FORMATS.include?(format)
        when :presentation then Dewey::PRESENTATION_EXPORT_FORMATS.include?(format)
        when :spreadsheet  then Dewey::SPREADSHEET_EXPORT_FORMATS.include?(format)
        else
          raise DeweyException, "Unknown service: #{service}"
        end
      end

      protected

      def default_service(service)
        service.nil? ? :document : service.to_sym
      end
    end
  end
end
