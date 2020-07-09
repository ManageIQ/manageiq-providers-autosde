require 'json'
require_relative 'openapi_client/generated/lib/openapi_client'

class ManageIQ::Providers::Autosde::StorageManager::AutosdeClient < OpenapiClient::ApiClient
  include Vmdb::Logging
  include OpenapiClient

  LOGIN_URL = "/site-manager/api/v1/engine/token-auth/"
  AUTH_ERRR_MSG = "Authentication error occured"
  AUTH_TOKEN_INVALID = Rack::Utils.status_code(:unauthorized)

  NoAuthTokenError = Class.new(StandardError)

  attr_accessor :token, :username, :password, :host

  def initialize(username:, password:, host:, port: 443, token: nil, scheme: 'https')
    @scheme = scheme
    @username = username
    @password = password
    @host = host
    @port = port
    @token = token
    super(configure_openapi_client)
  end

  # generates access methods for OpenApiClient , like StorageSystemApi or CreateVolume
  # usage : <this>.StorageSystemApi.storage_systems_get
  OpenapiClient.constants.each do |method|
    clazz = "OpenapiClient::#{method}".constantize
    attr_accessor method
    define_method method do |*args|
      if method.to_s.end_with?('Api')
        clazz.new(self)
      else
        clazz.new(*args)
      end
    end
  end

  # override OpenApiClient::ApiClient method
  def call_api (http_method, path, opts = {})
    puts ">>>>>> in call_api #{opts} #{http_method} #{path}"
    begin
      login unless @token
      set_auth_token
      super
    rescue OpenapiClient::ApiError => e
      case e.code
      when AUTH_TOKEN_INVALID
        begin
          _log.warn("doing re-login: token is #{@token}")
          # bypass private method
          login
          set_auth_token
          super
        rescue StandardError
          # in case re-login did not help, throw error
          _log.error("re-login was unsuccessful: token is #{@token}")
          raise # throw the last error
        end
      else
        # cannot handle
        raise
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
      raise Exception.new AUTH_ERRR_MSG
     end
  end

  private

  def _request(clz, url, payload = nil)
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

  def set_auth_token
    raise NoAuthTokenError, 'No auth token!' unless @token
    config.access_token = @token
  end

  def configure_openapi_client
    Configuration.new.tap do |config|
      config.scheme = @scheme
      config.verify_ssl = false
      config.host = @host
      config.debugging = true
      end
  end
end

