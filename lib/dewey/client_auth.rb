module Dewey
  class ClientAuth
    attr_reader :authorizations

    def initialize(email, password) 
      @email          = email
      @password       = password
      @authorizations = {}
    end

    def authorized?
      @authorizations.any? 
    end

    def authorize!(service = nil)
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
        @authorizations[service] = response.body.split('=').last
        true
      when Net::HTTPForbidden
        false
      else
        raise DeweyAuthorizationException, "Unexpected response: #{response}"
      end
    end
  end
end

