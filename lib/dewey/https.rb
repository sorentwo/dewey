require 'net/http'

# Shortcut method for using +http.use_ssl+.
module Net
  class HTTPS < Net::HTTP
    def initialize(address, port = 443)
      super(address, port)
      self.use_ssl = true
    end
  end
end