require 'json'

class ManageIQ::Providers::Autosde::PhysicalInfraManager::AutosdeClient
    require_relative 'openapi_client/generated/lib/openapi_client'
    include OpenapiClient

    LOGIN_URL = "/site-manager/api/v1/engine/oidc-auth/"
    AUTH_ERRR_MSG = "Authentication error occured"


    # todo (per gregoryb): remove IBM keys from the code (maybe to artifactory)
    def initialize(username="udyum@mailnesia.com", password="abCd_1234",  client_id= "NDBhNDk5MzAtZGZjMi00", secret_id= "NTNkMDdkNmMtNjFkYi00", host: "9.151.190.137")
        @username=username
        @password=password
        @host=host
        @client_id = client_id
        @secret_id = secret_id
        @port=443
        @token=nil
        @logedin = false
        OpenapiClient.configure do |config|
            config.scheme = 'https'
            config.verify_ssl = false
            config.host = @host
            config.debugging = true
        end
        Typhoeus.before do |request|
            login unless @token
            auth_header = build_auth_header
            request.options[:headers].merge!(auth_header)
        end
    end

    private

    def build_auth_header
        OpenapiClient.configure.access_token = @token
        auth_settings = OpenapiClient.configure.auth_settings
        auth_name = auth_settings.keys.first
        key = auth_settings[auth_name][:key]
        value =  auth_settings[auth_name][:value]
        { key => value}
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

    def _request(clz, url, payload = nil)
        uri = URI("https://%s:%s" % [@host, @port])
        uri.path  = url
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

