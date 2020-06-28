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
# module OpenapiClient
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

  AUTOSDE_APPLIANCE_HOST_WITH_AUTH_TOKEN = RSpec.configuration.autosde_appliance_host_with_auth_token

  it "creates volume on storage system" do

    client = ManageIQ::Providers::Autosde::StorageManager::AutosdeClient.new(
        :host => AUTOSDE_APPLIANCE_HOST_WITH_AUTH_TOKEN,
        :username => 'autosde',
        :password => 'change_me'
    )

    # retrieve storage system
    storage_systems = nil
    #  @type [Array<OpenapiClient::StorageSystem>]
    VCR.use_cassette("get_storage_system") do
      storage_systems = client.StorageSystemApi.storage_systems_get
      expect(storage_systems).to be_an_instance_of(Array)
    end

    # retrieve storage resource (pools)
    #  @type [Array<OpenapiClient::StorageResource>]
    VCR.use_cassette("get_storage_resources") do
      storage_resources = client.StorageResourceApi.storage_resources_get
      expect(storage_resources).to be_an_instance_of(Array)
    end

    services = nil
    # retrieve service
    VCR.use_cassette("get_services") do
      # @type [Array<OpenapiClient::Service>]
      services = client.ServiceApi.services_get
      expect(services).to be_an_instance_of(Array)
    end

    service = services.first

    # retrieve attachment
    # @type [Array<OpenapiClient::ServiceResourceAttachment>]
    # override to get uuid, not object
    class OpenapiClient::ServiceResourceAttachment
      def self.openapi_types
        {
            :'compliant' => :'Boolean',
            :'service' => :'String',
            :'storage_resource' => :'String',
            :'uuid' => :'String'
        }
      end
    end
    VCR.use_cassette("get_service_resource_attachment") do
      service_resource_map = client.ServiceResourceAttachmentApi.service_resource_attchment_get
      expect(service_resource_map).to be_an_instance_of(Array)
    end
    volumes = nil
    # get existing volumes
    # @type [Array<OpenapiClient::Volume>]
    VCR.use_cassette("get_volumes") do
      volumes = client.VolumeApi.volumes_get
    end
    volumes_count = volumes.count
    # create new volume
    vol_name = 'vol_test_bk_'  +  Time.now.strftime('%Y-%m-%d %H_%M_%S')
    vol_to_create = client.VolumeCreate(service: service, name: vol_name, size: 10)
    # replace by uuid, see explanation at top
    vol_to_create.service = service.uuid
    VCR.use_cassette("create_new_volume") do
      client.VolumeApi.volumes_post(vol_to_create)
    end
    sleep 10
    # after create volume: again get all volumes
    VCR.use_cassette("get_volumes_after_creation") do
      volumes = client.VolumeApi.volumes_get
      expect(volumes.count).to eq(volumes_count + 1)
    end
  end
end

