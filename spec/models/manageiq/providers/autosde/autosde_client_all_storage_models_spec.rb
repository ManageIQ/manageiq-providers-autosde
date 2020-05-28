require 'spec_helper'

describe ManageIQ::Providers::Autosde::BlockStorageManager::AutosdeClient do

  AUTOSDE_APPLIANCE_HOST_WITH_AUTH_TOKEN =   RSpec.configuration.autosde_appliance_host_with_auth_token
      # '9.151.190.208'

  it "creates volume on storage system" do

    client = ManageIQ::Providers::Autosde::BlockStorageManager::AutosdeClient.new(
        :host => AUTOSDE_APPLIANCE_HOST_WITH_AUTH_TOKEN)

    resources = nil

    # retrieve storage system
    storage_systems = nil
    #  @type [Array<OpenapiClient::StorageSystem>]
    VCR.use_cassette("get_storage_systeme") do
      storage_systems = client.class::StorageSystemApi.new.storage_systems_get
      expect(storage_systems).to be_an_instance_of(Array)
    end

    # get first system
    storage_system = storage_systems.first

    storage_resources = nil

    # retrieve storage resource (pools)
    #  @type [Array<OpenapiClient::StorageResource>]
    VCR.use_cassette("get_storage_resources") do
      storage_resources = client.class::StorageResourceApi.new.storage_resources_get
      expect(storage_resources).to be_an_instance_of(Array)
    end

    # get first resource
    storage_resource = storage_resources.first
    services = nil
    # retrieve service
    VCR.use_cassette("get_services") do
      # @type [Array<OpenapiClient::Service>]
      services = client.class::ServiceApi.new.services_get
      expect(services).to be_an_instance_of(Array)
    end

    service = services.first
    service_id = service.uuid
    puts "service: #{service}"

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
      service_resource_map = client.class::ServiceResourceAttachmentApi.new.service_resource_attchment_get
      expect(service_resource_map).to be_an_instance_of(Array)
    end

    volumes = nil
    # get existing volumes
    # @type [Array<OpenapiClient::Volume>]
    VCR.use_cassette("get_volumes") do
      volumes = client.class::VolumeApi.new.volumes_get
    end

    puts "volumes: #{volumes}"
    volumes_count = volumes.count

    # create new volume
    vol_name = 'vol_test_' + Time.now.getutc.to_s
    puts "GGGGGGGGGG_" + vol_name

    vol_to_create = client.class::VolumeCreate.build_from_hash(service: service, name: vol_name, size: 10)
    vol_to_create.service= service.uuid
    puts "vol to create: #{vol_to_create}"
    VCR.use_cassette("create_new_volume") do
      client.class::VolumeApi.new.volumes_post(vol_to_create)
    end

    # after: again get all volumes

    VCR.use_cassette("get_volumes_after_creation") do
      volumes = client.class::VolumeApi.new.volumes_get
      puts "volumes: #{volumes.count}"
      expect(volumes.count).to  eq(volumes_count +1)
    end

  end

end

