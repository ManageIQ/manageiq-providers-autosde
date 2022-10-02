class ManageIQ::Providers::Autosde::StorageManager < ManageIQ::Providers::StorageManager
  require_nested :AutosdeClient
  require_nested :CloudVolume
  require_nested :ClusterVolumeMapping
  require_nested :HostInitiatorGroup
  require_nested :HostInitiator
  require_nested :HostVolumeMapping
  require_nested :PhysicalStorage
  require_nested :Refresher
  require_nested :RefreshWorker
  require_nested :StorageResource
  require_nested :StorageService
  require_nested :VolumeMapping
  require_nested :EventCatcher

  supports :authentication_status
  supports :create
  supports :storage_services
  supports :update
  supports :volume_resizing
  supports :cloud_volume_create
  supports :cloud_volume
  supports :catalog

  supports :add_storage
  supports :add_host_initiator
  supports :add_volume_mapping
  supports :storage_capabilities
  supports :storage_capability_values

  include ManageIQ::Providers::StorageManager::BlockMixin

  # Asset details
  has_many :physical_server_details,  :through => :physical_servers,  :source => :asset_detail
  has_many :physical_storage_details, :through => :physical_storages, :source => :asset_detail
  # TODO: (erezt):
  # has_many :services_details, :through => :services, :source => :asset_detail
  # has_many :resources_details, :through => :resources, :source => :asset_detail

  # Computer systems
  has_many :physical_server_computer_systems,  :through => :physical_servers,  :source => :computer_system
  has_many :physical_storage_computer_systems, :through => :physical_storages, :source => :canister_computer_systems

  # Network
  has_many :physical_server_networks,  :through => :physical_server_management_devices,  :source => :network
  has_many :physical_storage_networks, :through => :physical_storage_management_devices, :source => :network

  # Physical network ports
  has_many :physical_server_network_ports,  :through => :physical_server_network_devices,     :source => :physical_network_ports
  has_many :physical_storage_network_ports, :through => :physical_storage_management_devices, :source => :physical_network_ports

  # Physical disks
  has_many :physical_disks, :through => :physical_storages

  has_many :host_volume_mappings, :foreign_key => :ems_id, :inverse_of => :ext_management_system,
           :class_name => "ManageIQ::Providers::Autosde::StorageManager::HostVolumeMapping"
  has_many :cluster_volume_mappings, :foreign_key => :ems_id, :inverse_of => :ext_management_system,
           :class_name => "ManageIQ::Providers::Autosde::StorageManager::ClusterVolumeMapping"

  virtual_total :total_physical_servers,  :physical_servers
  virtual_total :total_physical_storages, :physical_storages

  virtual_column :total_hosts, :type => :integer
  virtual_column :total_vms,   :type => :integer

  virtual_column :total_valid, :type => :integer
  virtual_column :total_warning, :type => :integer
  virtual_column :total_critical, :type => :integer
  virtual_column :health_state_info, :type => :json

  virtual_column :total_resources, :type => :integer
  virtual_column :resources_info, :type => :json

  class << model_name
    define_method(:route_key) { "ems_block_storages" }
    define_method(:singular_route_key) { "ems_block_storage" }
  end

  def queue_name_for_ems_refresh
    queue_name
  end

  def self.ems_type
    @ems_type ||= "storage_manager".freeze
  end

  def self.description
    @description ||= "StorageManager".freeze
  end

  def count_health_state(state)
    count = 0
    count += physical_servers.where(:health_state => state).count
    count += physical_storages.where(:health_state => state).count
  end

  def assign_health_states
    {
      :total_valid    => count_health_state("Valid"),
      :total_warning  => count_health_state("Warning"),
      :total_critical => count_health_state("Critical"),
    }
  end

  alias health_state_info assign_health_states

  def count_resources(component = nil)
    count = 0

    if component
      count = component.count
    else
      count += physical_servers.count
      count += physical_storages.count
    end
  end

  def assign_resources_info
    {
      :total_resources => count_resources,
    }
  end

  alias resources_info assign_resources_info

  def count_physical_servers_with_host
    physical_servers.inject(0) { |t, physical_server| physical_server.host.nil? ? t : t + 1 }
  end

  alias total_hosts count_physical_servers_with_host

  def count_vms
    physical_servers.inject(0) { |t, physical_server| physical_server.host.nil? ? t : t + physical_server.host.vms.size }
  end

  alias total_vms count_vms

  def self.display_name(number = 1)
    n_('Storage Manager', 'Storage Managers', number)
  end

  def textual_group_list
    [
      %i[properties status],
      %i[storage_relationships topology]
    ]
  end

  def autosde_client
    if @autosde_client.nil?
      @autosde_client = self.class.raw_connect(authentication_userid,
                                               authentication_password,
                                               address,
                                               port)
    end
    @autosde_client
  end

  def self.verify_credentials(options = {})
    raw_connect(options["authentications"]["default"]["userid"],
                ManageIQ::Password.try_decrypt(options["authentications"]["default"]["password"]),
                options["endpoints"]["default"]["hostname"],
                options["endpoints"]["default"]["port"]).login
  end

  # is this just for verifying credentials for when you create a new instance?
  # todo (per gregoryb): need to enable users to provide client_id and secret_id
  def verify_credentials(_auth_type = nil, _options = {})
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
    username   = options[:user] || authentication_userid(options[:auth_type])
    password   = options[:pass] || authentication_password(options[:auth_type])
    host       = options[:host] || address
    port       = options[:port] || self.port
    self.class.raw_connect(username, password, host, port).login
  end

  def self.validate_authentication_args(params)
    # return args to be used in raw_connect
    [params[:default_userid], ManageIQ::Password.encrypt(params[:default_password])]
  end

  # is this just for verifying credentials for when you create a new instance?
  # @return AutosdeClient
  def self.raw_connect(username, password, host, port)
    ManageIQ::Providers::Autosde::StorageManager::AutosdeClient.new(:username => username, :password => password, :host => host, :port => port)
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

  def self.params_for_create
    {
      :fields => [
        {
          :component => 'sub-form',
          :id        => 'endpoints-subform',
          :name      => 'endpoints-subform',
          :title     => _('Endpoints'),
          :fields    => [
            {
              :component              => 'validate-provider-credentials',
              :id                     => 'authentications.default.valid',
              :name                   => 'authentications.default.valid',
              :skipSubmit             => true,
              :validationDependencies => %w[type endpoints.default.hostname authentications.default.userid authentications.default.password],
              :fields                 => [
                {
                  :component  => "select",
                  :id         => "endpoints.default.security_protocol",
                  :name       => "endpoints.default.security_protocol",
                  :label      => _("Security Protocol"),
                  :isRequired => true,
                  :validate   => [{:type => "required"}],
                  :includeEmpty => true,
                  :options    => [
                    {
                      :label => _("SSL without validation"),
                      :value => "ssl-no-validation"
                    }
                    # todo[per gregoryb]: need to provide ssl and non-ssl
                    # {
                    #     :label => _("SSL"),
                    #     :value => "ssl-with-validation"
                    # },
                    # {
                    #     :label => _("Non-SSL"),
                    #     :value => "non-ssl"
                    # }
                  ]
                },
                {
                  :component  => "text-field",
                  :id         => "endpoints.default.hostname",
                  :name       => "endpoints.default.hostname",
                  :label      => _("Hostname (or IPv4 or IPv6 address)"),
                  :isRequired => true,
                  :validate   => [{:type => "required"}],
                },
                {
                  :component    => "text-field",
                  :id           => "endpoints.default.port",
                  :name         => "endpoints.default.port",
                  :label        => _("API Port"),
                  :type         => "number",
                  :initialValue => 443,
                  :isRequired   => true,
                  :validate     => [{:type => "required"}],
                },
                {
                  :component  => "text-field",
                  :id         => "authentications.default.userid",
                  :name       => "authentications.default.userid",
                  :label      => _("Username"),
                  :isRequired => true,
                  :validate   => [{:type => "required"}],
                },
                {
                  :component  => "password-field",
                  :id         => "authentications.default.password",
                  :name       => "authentications.default.password",
                  :label      => _("Password"),
                  :type       => "password",
                  :isRequired => true,
                  :validate   => [{:type => "required"}],
                },
              ]
            }
          ],
        },
      ]
    }
  end

  def self.catalog_types
    {"autosde" => N_("Autosde")}
  end
end
