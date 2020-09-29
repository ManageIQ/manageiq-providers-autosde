# This class is supposed to collect raw output from the managed system
class ManageIQ::Providers::Autosde::Inventory::Collector::StorageManager < ManageIQ::Providers::Inventory::Collector
  # @return [ManageIQ::Providers::Autosde::StorageManager]
  attr_accessor :manager

  def collect
    new_inventory = {}

    new_inventory[:physical_storages] = []
    @manager.autosde_client.StorageSystemApi.storage_systems_get.each do |system|
      # @type [ManageIQ::Providers::Autosde::StorageManager::AutosdeClient::StorageSystem]
      system = system
      new_inventory[:physical_storages] << {
        :name             => system.name,
        :ems_ref          => system.uuid,
        :system_type_uuid => system.system_type.uuid,

      }
    end

    new_inventory[:storage_resources] = []
    @manager.autosde_client.StorageResourceApi.storage_resources_get.each do |resource|
      # @type [ManageIQ::Providers::Autosde::StorageManager::AutosdeClient::StorageResourceResponse]
      resource = resource
      new_inventory[:storage_resources] << {
        :name                => resource.name,
        :ems_ref             => resource.uuid,
        :logical_free        => resource.logical_free,
        :logical_total       => resource.logical_total,
        :storage_system_uuid => resource.storage_system
      }
    end

    new_inventory[:cloud_volumes] = []
    @manager.autosde_client.VolumeApi.volumes_get.each do |volume|
      # @type [ManageIQ::Providers::Autosde::StorageManager::AutosdeClient::VolumeResponse]
      volume = volume
      new_inventory[:cloud_volumes] << {
        :name                  => volume.name,
        :size                  => volume.size * 1024 * 1024 * 1024,
        :ems_ref               => volume.uuid,
        :storage_resource_uuid => volume.storage_resource,
        :storage_service_uuid  => volume.service,
        :status                => volume.component_state
      }
    end

    new_inventory[:storage_services] = []
    @manager.autosde_client.ServiceApi.services_get.each do |service|
      # @type [ManageIQ::Providers::Autosde::StorageManager::AutosdeClient::Service]
      service = service
      new_inventory[:storage_services] << {
        :name        => service.name,
        :description => service.description,
        :version     => service.version,
        :ems_ref     => service.uuid,
      }
    end

    new_inventory[:physical_storage_families] = []
    @manager.autosde_client.SystemTypeApi.system_types_get.each do |system_type|
      # @type [ManageIQ::Providers::Autosde::StorageManager::AutosdeClient::SystemType]
      system_type = system_type
      new_inventory[:physical_storage_families] << {
        :name    => system_type.name,
        :ems_ref => system_type.uuid,
        :version => system_type.version
      }
    end

    @inventory = new_inventory
  end
end
