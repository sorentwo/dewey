require 'net/http'

module Net # :nodoc:
  class HTTPS < Net::HTTP
    def initialize(address, port = 443)
      super(address, port)
      self.use_ssl = true
      @ssl_context = OpenSSL::SSL::SSLContext.new
      @ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
  end
end