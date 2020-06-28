# This class is supposed to collect raw output from the managed system
class ManageIQ::Providers::Autosde::Inventory::Collector::StorageManager < ManageIQ::Providers::Inventory::Collector

  # @return [ManageIQ::Providers::Autosde::StorageManager]
  attr_accessor :manager

  def collect
    new_inventory = {}

    new_inventory[:storage_systems] = []
    @manager.autosde_client.StorageSystemApi.storage_systems_get.each do |system|
      # @type [ManageIQ::Providers::Autosde::StorageManager::AutosdeClient::StorageSystem]
      system = system
      new_inventory[:storage_systems] << {
          :name => system.name,
          :ems_ref => system.uuid,
          :uuid => system.uuid,
          :system_type_uuid => system.system_type.uuid,
          :storage_family => system.storage_family,
          :management_ip => system.management_ip
      }
    end

    new_inventory[:storage_resources] = []
    @manager.autosde_client.StorageResourceApi.storage_resources_get.each do |resource|
      # @type [ManageIQ::Providers::Autosde::StorageManager::AutosdeClient::StorageResource]
      resource = resource
      new_inventory[:storage_resources] << {
          :name => resource.name,
          :uuid => resource.uuid,
          :ems_ref => resource.uuid,
          :logical_free => resource.logical_free,
          :logical_total => resource.logical_total,
          :pool_name => resource.pool_name,
          :storage_system_uuid => resource.storage_system
      }
    end

    new_inventory[:cloud_volumes] = []
    @manager.autosde_client.VolumeApi.volumes_get.each do |volume|
      # @type [ManageIQ::Providers::Autosde::StorageManager::AutosdeClient::Volume]
      volume = volume
      new_inventory[:cloud_volumes] << {
          :name => volume.name,
          :compliant => volume.compliant,
          :size => volume.size * 1024 * 1024 * 1024,
          :ems_ref => volume.uuid,
          :storage_resource_uuid => volume.storage_resource,
          :storage_service_uuid => volume.service,
          :status => volume.component_state
      }
    end

    new_inventory[:storage_services] = []
    @manager.autosde_client.ServiceApi.services_get.each do |service|
      # @type [ManageIQ::Providers::Autosde::StorageManager::AutosdeClient::Service]
      service = service
      new_inventory[:storage_services] << {
          name: service.name,
          description: service.description,
          uuid: service.uuid,
          version: service.version,
          ems_ref: service.uuid,
      }

    end

    new_inventory[:storage_system_types] = []
    @manager.autosde_client.SystemTypeApi.system_types_get.each do |system_type|
      # @type [ManageIQ::Providers::Autosde::StorageManager::AutosdeClient::SystemType]
      system_type = system_type
      new_inventory[:storage_system_types] << {
          name: system_type.name,
          ems_ref: system_type.uuid,
          version: system_type.version
      }

    end

    @inventory = new_inventory
  end
end
