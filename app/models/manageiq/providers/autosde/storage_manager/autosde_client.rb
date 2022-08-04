require 'autosde_openapi_client'

class ManageIQ::Providers::Autosde::StorageManager::AutosdeClient < AutosdeOpenapiClient::ApiClient
  include Vmdb::Logging

  AUTH_ERRR_MSG = "Authentication error occured. ".freeze
  AUTH_TOKEN_INVALID = Rack::Utils.status_code(:unauthorized)

  NoAuthTokenError = Class.new(StandardError)

  attr_accessor :token, :username, :password, :host, :port

  def initialize(username:, password:, host:, port: 443, token: nil, scheme: 'https')
    @scheme = scheme
    @username = username
    @password = password
    @host = host
    @port = port
    @token = token
    @count = 0
    super(configure_openapi_client)
  end

  # generates access methods for AutosdeOpenapiClient , like StorageSystemApi or CreateVolume
  # usage : <this>.StorageSystemApi.storage_systems_get
  AutosdeOpenapiClient.constants.each do |method|
    clazz = "AutosdeOpenapiClient::#{method}".constantize
    attr_accessor method
    define_method method do |*args|
      if method.to_s.end_with?('Api')
        clazz.new(self)
      else
        clazz.new(*args)
      end
    end
  end

  # override AutosdeOpenapiClient::ApiClient method
  def call_api(http_method, path, opts = {})
    if opts[:login]
      super
    else
      login unless @token
      set_auth_token
      super
    end
  rescue AutosdeOpenapiClient::ApiError => e
    case e.code
    when AUTH_TOKEN_INVALID
      begin
        _log.warn("doing re-login: token is #{@token}")
        login
        set_auth_token
        super
      rescue
        # in case re-login did not help, throw error
        _log.error("re-login was unsuccessful: token is #{@token}")
        raise # throw the last error
      end
    else
      # cannot handle
      raise
    end
  end

  def login
    auth_request = Authentication(:username => @username, :password => @password)
    # prevents endless loop
    opts = {:login => true}
    data = self.AuthenticationApi.token_auth_post(auth_request, opts)
    @token = data.token
  rescue AutosdeOpenapiClient::ApiError => e
    error_data = JSON.parse(e.response_body)
    raise AUTH_ERRR_MSG + error_data.dig("detail", "non_field_errors")&.first
  rescue => e
    raise AUTH_ERRR_MSG + e.to_s
  end

  private

  def set_auth_token
    raise NoAuthTokenError, 'No auth token!' unless @token

    config.access_token = @token
  end

  def configure_openapi_client
    AutosdeOpenapiClient::Configuration.new.tap do |config|
      config.scheme = @scheme
      config.verify_ssl = false
      config.host = @host
      config.debugging = false
      config.verify_ssl_host = false
      config.server_index = nil # by default is set to 0; then server url is
      # taken from oas. which is localhost.
      # when set to nil, url refers to config.host, as it should be
    end
  end

  private_class_method def self.wait_for_success(ems, task_id, time_to_sleep = 1, wait_time = 60)
    task_status = nil
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    while task_status != "SUCCESS" and task_status != "FAILURE" and Process.clock_gettime(Process::CLOCK_MONOTONIC) < start_time + wait_time
      sleep(time_to_sleep)
      task_status = ems.autosde_client.JobApi.jobs_pk_get(task_id).status
    end
    task_status
  end

  private_class_method def self.raise_non_success_exception(status)
    if status == "FAILURE"
      raise _("The Job failed")
    elsif status == "PENDING" or status == "STARTED"
      raise _("Timeout")
    else
      raise _("An unknown exception has occurred (Job status: '%{status_name}'") % {:status_name => status}
    end
  end
end
