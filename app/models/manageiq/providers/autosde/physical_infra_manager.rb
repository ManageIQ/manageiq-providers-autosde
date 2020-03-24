
# I add the require_relative here as a convenience so you don't have to remember the path to autosde_client.
# Just evaluate the manager class, like so:
#   irb :001 > ManageIQ::Providers::Autosde::PhysicalInfraManager
# and then you can use the client
#   irb :002 > ManageIQ::Providers::Autosde::AutoSDEClient
# I don't know why native MIQ stuff can be included right away, but things I add need to be required. Probably there's
# a list of files that MIQ requires on startup.
require_relative 'physical_infra_manager/autosde_client.rb'

class ManageIQ::Providers::Autosde::PhysicalInfraManager < ManageIQ::Providers::PhysicalInfraManager
  require_nested :MetricsCapture
  require_nested :MetricsCollectorWorker
  require_nested :Refresher
  require_nested :RefreshWorker

  # is this just for verifying credentials for when you create a new instance?
  # todo (per gregoryb): need to enable users to provide client_id and secret_id
  def verify_credentials(auth_type = nil, options = {})
    begin
      connect
    rescue => err
      raise MiqException::MiqInvalidCredentialsError, err.message
    end

    true
  end

  # is this just for verifying credentials for when you create a new instance?
  def connect(options = {})
    raise MiqException::MiqHostError, "No credentials defined" if missing_credentials?(options[:auth_type])

    auth_token = authentication_token(options[:auth_type])
    host       = options[:host] || address
    self.class.raw_connect host
    # self.class.raw_connect(project, auth_token, options, options[:proxy_uri] || http_proxy_uri)
  end

  def self.validate_authentication_args(params)
    # return args to be used in raw_connect
    return [params[:default_userid], ManageIQ::Password.encrypt(params[:default_password])]
  end

  # is this just for verifying credentials for when you create a new instance?
  def self.raw_connect(host)
    ManageIQ::Providers::Autosde::AutoSDEClient.new(host: host).login
  end

  def self.hostname_required?
    # TODO: ExtManagementSystem is validating this
    false
  end

  def self.ems_type
    @ems_type ||= "autosde".freeze
  end

  def self.description
    @description ||= "Autosde".freeze
  end
end
