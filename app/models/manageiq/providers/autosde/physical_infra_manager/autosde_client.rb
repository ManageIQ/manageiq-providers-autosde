require 'json'

class ManageIQ::Providers::Autosde::PhysicalInfraManager::AutosdeClient
    LOGIN_URL = "/site-manager/api/v1/engine/oidc-auth/"
    STORAGE_SYSTEMS_URL = "/site-manager/api/v1/engine/storage-systems/"
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
    end

    # todo [per gregoryb]: This is just a placeholder. We want to generate a ruby client based on our swagger api.
    def get_storage_systems
        get(STORAGE_SYSTEMS_URL)
    end

    # @param [String] url
    def get(url)
        _request_with_login(Net::HTTP::Get, url, nil)
    end

    def post(url, payload)
        _request_with_login(Net::HTTP::Post, url, payload)
    end

    def put(url, payload)
        _request_with_login(Net::HTTP::Put, url, payload)
    end

    def patch(url, payload)
        _request_with_login(Net::HTTP::Patch, url, payload)
    end

    def delete(url)
        _request_with_login(Net::HTTP::Delete, url, nil)
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

    private

    # @param [Object] clz
    # @param [String] url
    def _request_with_login(clz, url, payload=nil)
        login if @token.nil?

        resp = _request(clz, url, payload)
        if resp.instance_of? Net::HTTPForbidden
            login
            resp = _request(clz, url, payload)
        end
        JSON.parse(resp.body)
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
        if @token != nil
            request['Authorization'] = 'Bearer %s' % [@token]
        end

        # send the request
        Net::HTTP.start(
            uri.host, uri.port,
            :use_ssl => uri.scheme == 'https',
            :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |https|
            https.request(request)
        end

    end

end

