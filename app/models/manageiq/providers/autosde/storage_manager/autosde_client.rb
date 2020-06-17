require 'json'
require_relative 'openapi_client/generated/lib/openapi_client'

class ManageIQ::Providers::Autosde::StorageManager::AutosdeClient
    include Vmdb::Logging
    include OpenapiClient

    LOGIN_URL = "/site-manager/api/v1/engine/token-auth/"
    # AUTH_ERRR_MSG = "Authentication error occured"
    AUTH_TOKEN_INVALID = Rack::Utils.status_code(:forbidden)

    NoAuthTokenError = Class.new(StandardError)

    # open generated class and add method for setting custom client
    class OpenapiClient::ApiClient
      #noinspection RubyClassVariableUsageInspection
      def self.default=(c)
            @@default = c
        end
    end

    attr_accessor :token, :username, :password, :host

    # todo (per gregoryb): remove IBM keys from the code (maybe to artifactory)
    def initialize(username: "autosde", password: "change_me", host: "9.151.190.137")
        @username = username
        @password = password
        @host = host
        @port = 443
        @token = nil
        @logedin = false
        # make generated code to reference our class
        OpenapiClient::ApiClient.default = ReloginClient.new(self)
    end

    class ReloginClient < OpenapiClient::ApiClient
        def initialize(parent = nil)
            @parent = parent
            configure_openapi_client
            super()
        end

        def call_api (http_method, path, opts = {})
            begin
                @parent.login unless @parent.token
                set_auth_token
                super
            rescue OpenapiClient::ApiError => e
              case e.code
                when AUTH_TOKEN_INVALID
                  begin
                      @parent._log.warn("doing re-login: token is #{@parent.token}")
                      # bypass private method
                      @parent.login
                      set_auth_token
                      super
                  rescue StandardError
                      # in case re-login did not help, throw error
                      @parent._log.error("re-login was unsuccessful: token is #{@parent.token}")
                      raise # throw the last error
                  end
                else
                  # cannot handle
                  raise
               end
            end
        end

        private def set_auth_token
            raise NoAuthTokenError, 'No auth token!' unless @parent.token
            OpenapiClient.configure.access_token = @parent.token
        end

        private def configure_openapi_client
            OpenapiClient.configure do |config|
                config.scheme = 'https'
                config.verify_ssl = false
                config.host = @parent.host
                config.debugging = true
            end
        end
    end

    def login
        payload = {
            :username => @username,
            :password => @password,
        }

        @token = nil
        res = _request(Net::HTTP::Post, LOGIN_URL, payload)
        # if res.code != "200"
        if res.instance_of? Net::HTTPOK
            @token = JSON.parse(res.body)["token"]
            @login = true
        else
            @login = false
            # raise Exception.new AUTH_ERRR_MSG
            raise res.read_body
        end
    end

    private def _request(clz, url, payload = nil)
        uri = URI("https://%s:%s" % [@host, @port])
        uri.path = url
        request = clz.new(uri.path)
        if payload != nil
            request.body = payload.to_json
        end

        # set headers
        request["Content-Type"] = 'application/json'

        # send the request
        Net::HTTP.start(
            uri.host, uri.port,
            :use_ssl => uri.scheme == 'https',
            :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |https|
            https.request(request)
        end
    end
end
