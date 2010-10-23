module Dewey
  class ClientAuth
    attr_reader :authentications

    def initialize(email, password) 
      @email          = email
      @password       = password
      @authentications = {}
    end

    def authenticated?
      @authentications.any? 
    end

    def authenticate!(service = nil)
      service ||= :writely


      params = { 'accountType' => 'HOSTED_OR_GOOGLE',
                 'Email'       => @email,
                 'Passwd'      => @password,
                 'service'     => service.to_s
              }

      url      = URI.parse(Dewey::GOOGLE_LOGIN_URL)
      response = Net::HTTPS.post_form(url, params)

      case response
      when Net::HTTPSuccess
        @authentications[service] = response.body.split('=').last
        true
      when Net::HTTPForbidden
        false
      else
        raise DeweyAuthorizationException, "Unexpected response: #{response}"
      end
    end
  end
end

