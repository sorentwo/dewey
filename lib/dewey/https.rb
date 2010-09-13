require 'net/http'

module Net # :nodoc:
  # Shortcut method for using +http.use_ssl+.
  class HTTPS < Net::HTTP
    def initialize(address, port = 443)
      super(address, port)
      self.use_ssl = true
    end
  end
end