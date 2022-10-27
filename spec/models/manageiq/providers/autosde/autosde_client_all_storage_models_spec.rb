describe ManageIQ::Providers::Autosde::StorageManager::AutosdeClient do
  # assumption to the test
  # -system exists
  # -resource(pool) exists
  # service exists
  #
  # When creating object, how to know which attributes to set in initializer?
  # Autocomplete does not help
  # Example: create Volume
  # Using client.VolumeCreat(service: service, name: vol_name, size: 10)
  # In order to know attributes, click on VolumeCreate, and see all its attributes accessors.
  # This will give all anticipated attributes
  # module AutosdeOpenapiClient
  # class VolumeCreate
  #     # compliant
  #     attr_accessor :compliant
  #
  #     # name
  #     attr_accessor :name
  #
  #     attr_accessor :service
  #
  #     # size
  #     attr_accessor :size
  #
  #     # uuid
  #     attr_accessor :uuid
  #
  #
  #  Problem with autosde REST objects
  #  see https://jira.xiv.ibm.com/browse/SDE-1203
  #  Autosde server and Autosde client both are generated from oas configuration file
  #  In all places , where client anticipates object, the uuid is used instead.
  #  So, such parameter should be replaced by uuid in all places.
  #  See example of using below
  #
  #
  #
  let!(:client) do
    ManageIQ::Providers::Autosde::StorageManager::AutosdeClient.new(
      :host     => Rails.application.secrets.autosde[:appliance_host],
      :username => 'autosde',
      :password => 'change_me',
      :scheme   => 'https'
    )
  end

  it "creates volume on storage system -autosde gem v1" do
    # retrieve storage system
    storage_systems = nil
    #  @type [Array<AutosdeOpenapiClient::StorageSystem>]
    VCR.use_cassette("get_storage_system_v1") do
      storage_systems = client.StorageSystemApi.storage_systems_get
      expect(storage_systems).to be_an_instance_of(Array)
    end

    # retrieve storage resource (pools)
    #  @type [Array<AutosdeOpenapiClient::StorageResource>]
    VCR.use_cassette("get_storage_resources_v1") do
      storage_resources = client.StorageResourceApi.storage_resources_get
      expect(storage_resources).to be_an_instance_of(Array)
    end

    services = nil
    # retrieve service
    VCR.use_cassette("get_services_v1") do
      # @type [Array<AutosdeOpenapiClient::Service>]
      services = client.ServiceApi.services_get
      expect(services).to be_an_instance_of(Array)
    end

    service = services.first

    volumes = nil
    # get existing volumes
    # @type [Array<AutosdeOpenapiClient::Volume>]
    VCR.use_cassette("get_volumes_v1") do
      volumes = client.VolumeApi.volumes_get
    end
    volumes_count = volumes.count

    # @type AutosdeOpenapiClient::VolumeResponse
    any_volume = volumes.first
    expect(any_volume).to be_an_instance_of(AutosdeOpenapiClient::VolumeResponse)
    expect(any_volume.service).to be_a(String)

    # create new volume
    vol_name = 'vol_test_bk_' + Time.zone.now.strftime('%Y-%m-%d %H_%M_%S')
    vol_to_create = client.VolumeCreate(:service => service.uuid, :name => vol_name, :size => 10)
    expect(vol_to_create).to be_an_instance_of(AutosdeOpenapiClient::VolumeCreate)
    expect(vol_to_create.service).to be_a(String)

    # replace by uuid, see explanation at top
    # vol_to_create.service = service.uuid
    VCR.use_cassette("create_new_volume") do
      client.VolumeApi.volumes_post(vol_to_create)
    end
    # sleep 10
    # after create volume: again get all volumes
    VCR.use_cassette("get_volumes_after_creation_v1") do
      volumes = client.VolumeApi.volumes_get
      expect(volumes.count).to eq(volumes_count + 1)
    end
  end

  it "check component state exists" do
    VCR.use_cassette("check_state_exists_v1") do
      volumes = client.VolumeApi.volumes_get
      volume = volumes.first
      expect(volume).to have_attributes(:component_state => a_string_starting_with("CREATED"))
    end
    end

  it "creates volume on storage system -autosde gem v2" do
    # retrieve storage system
    storage_systems = nil
    #  @type [Array<AutosdeOpenapiClient::StorageSystem>]
    VCR.use_cassette("get_storage_system_v2") do
      storage_systems = client.StorageSystemApi.storage_systems_get
      expect(storage_systems).to be_an_instance_of(Array)
    end

    # retrieve storage resource (pools)
    #  @type [Array<AutosdeOpenapiClient::StorageResource>]
    VCR.use_cassette("get_storage_resources_v2") do
      storage_resources = client.StorageResourceApi.storage_resources_get
      expect(storage_resources).to be_an_instance_of(Array)
    end

    services = nil
    # retrieve service
    VCR.use_cassette("get_services_v2") do
      # @type [Array<AutosdeOpenapiClient::Service>]
      services = client.ServiceApi.services_get
      expect(services).to be_an_instance_of(Array)
    end

    service = services.first

    volumes = nil
    # get existing volumes
    # @type [Array<AutosdeOpenapiClient::Volume>]
    VCR.use_cassette("get_volumes_v2") do
      volumes = client.VolumeApi.volumes_get
    end
    volumes_count = volumes.count

    # @type AutosdeOpenapiClient::VolumeResponse
    any_volume = volumes.first
    expect(any_volume).to be_an_instance_of(AutosdeOpenapiClient::VolumeResponse)
    expect(any_volume.service).to be_a(String)

    # create new volume
    vol_name = 'vol_test_bk_' + Time.zone.now.strftime('%Y-%m-%d %H_%M_%S')
    vol_to_create = client.VolumeCreate(:service => service.uuid, :name => vol_name, :size => 10)
    expect(vol_to_create).to be_an_instance_of(AutosdeOpenapiClient::VolumeCreate)
    expect(vol_to_create.service).to be_a(String)

    # replace by uuid, see explanation at top
    # vol_to_create.service = service.uuid
    VCR.use_cassette("create_new_volume") do
      client.VolumeApi.volumes_post(vol_to_create)
    end
    # sleep 10
    # after create volume: again get all volumes
    VCR.use_cassette("get_volumes_after_creation_v2") do
      volumes = client.VolumeApi.volumes_get
      expect(volumes.count).to eq(volumes_count + 1)
    end
  end

  it "check component state exists" do
    VCR.use_cassette("check_state_exists_v2") do
      volumes = client.VolumeApi.volumes_get
      volume = volumes.first
      expect(volume).to have_attributes(:component_state => a_string_starting_with("CREATED"))
    end
  end
end
