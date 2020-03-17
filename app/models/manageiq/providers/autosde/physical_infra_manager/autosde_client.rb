require 'json'

class AutoSDEClient

    FORBIDEN = "403"
    OK = "200"
    LOGIN_URL = "/site-manager/api/v1/engine/oidc-auth/"
    AUTH_ERRR_MSG = "Authentication error occured"

    def initialize(username="udyum@mailnesia.com", password="abCd_1234", host="9.151.190.137", client_id="NDBhNDk5MzAtZGZjMi00", secret_id="NTNkMDdkNmMtNjFkYi00")
        @username=username
        @password=password
        @host=host
        @client_id = client_id
        @secret_id = secret_id
        @port=443
        @token=nil
        @logedin = false
    end

    def get(url)
        _make_request_with_login( method(:_make_get_request), url)
    end

    def post(url, payload)
        _make_request_with_login(method(:_make_post_request), url, payload)
    end

    def put(url, payload)
        _make_request_with_login(method(:_make_put_request), url, payload)
    end

    def patch(url, payload)
        _make_request_with_login(method(:_make_patch_request), url, payload)
    end

    def delete(url)
        _login_if_no_token
        resp = _make_delete_request(url)
        if resp.code == FORBIDEN
            login
            resp = _make_delete_request(url)
        end
        resp
    end

    def login
        payload = {
            "client_id": @client_id,
            "secret_id": @secret_id,
            "username": @username,
            "password": @password
        }

        @token = nil
        res = _make_post_request(LOGIN_URL, payload)

        if res.code == OK
            @token = JSON.parse(res.body)["access_token"]
            @login = true
        else
            @login = false
            raise Exception.new AUTH_ERRR_MSG
        end
    end

    private

    def _make_request_with_login(callback, url, payload=nil)
        _login_if_no_token
        resp = callback.call(url, payload)
        if resp.code == FORBIDEN
            login
            resp = callback.call(url, payload)
        end
        resp
    end

    def _login_if_no_token
        if @token == nil
            login
        end
    end

    def _make_delete_request(url)
        _make_request(Net::HTTP::Delete, url)
    end

    def _make_get_request(url, payload_not_used=nil)
        _make_request(Net::HTTP::Get, url)
    end

    def _make_post_request(url, payload)
        _make_request(Net::HTTP::Post, url, payload)
    end

    def _make_put_request(url, payload)
        _make_request(Net::HTTP::Put, url, payload)
    end

    def _make_patch_request(url, payload)
        _make_request(Net::HTTP::Patch, url, payload)
    end

    def _make_request(clz, url, payload = nil)
        uri = URI("https://%s:%s" % [@host, @port])
        uri.path  = url
        request = clz.new(uri.path)
        if payload != nil
            request.body = payload.to_json
        end
        set_headers(request)
        res = _exec_request(request, uri)
        res    
    end

    def set_headers(request)
        request["Content-Type"] = 'application/json'
        if @token != nil
            request['Authorization'] = 'Bearer %s' % [@token]
        end
    end

    def _exec_request(request, uri)
        res = Net::HTTP.start(
        uri.host, uri.port,
        :use_ssl => uri.scheme == 'https',
        :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |https|
            https.request(request)
        end
        res
    end
end
