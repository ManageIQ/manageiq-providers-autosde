require 'json'
require_relative 'openapi_client/generated/lib/openapi_client'

class ManageIQ::Providers::Autosde::SdeManager::AutosdeClient
    include Vmdb::Logging
    include OpenapiClient

    LOGIN_URL = "/site-manager/api/v1/engine/oidc-auth/"
    AUTH_ERRR_MSG = "Authentication error occured"

    NoAuthTokenError = Class.new(StandardError)

    # open generated class and add method for setting custom client
    class OpenapiClient::ApiClient
        def self.default=(c)
            @@default = c
        end
    end

    attr_accessor :token, :host

    # todo (per gregoryb): remove IBM keys from the code (maybe to artifactory)
    def initialize(username = "udyum@mailnesia.com", password = "abCd_1234", client_id = "NDBhNDk5MzAtZGZjMi00", secret_id = "NTNkMDdkNmMtNjFkYi00", host: "9.151.190.137")
        @username = username
        @password = password
        @host = host
        @client_id = client_id
        @secret_id = secret_id
        @port = 443
        @token = nil
        @logedin = false
        # make generated code to reference our class
        OpenapiClient::ApiClient.default = ReloginClient.new(self)
    end

    class ReloginClient < OpenapiClient::ApiClient
        # @type ManageIQ::Providers::Autosde::PhysicalInfraManager::AutosdeClient parent
        def initialize(parent = nil)
            @parent = parent
            configure_openapi_client
            super()
        end

        def call_api (http_method, path, opts = {})
            begin
                puts "1>>>>> in overriden parent token is #{@parent.token}"
                @parent.login unless @parent.token
                set_auth_token
                super
            rescue StandardError => e
                puts e.message
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
            :client_id => @client_id,
            :secret_id => @secret_id,
            :username => @username,
            :password => @password,
        }

        @token = nil
        res = _request(Net::HTTP::Post, LOGIN_URL, payload)
        if res.instance_of? Net::HTTPOK
            @token = JSON.parse(res.body)["access_token"]
            @login = true
        else
            @login = false
            raise Exception.new AUTH_ERRR_MSG
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
