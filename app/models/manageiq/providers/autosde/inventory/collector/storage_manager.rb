# This class is supposed to collect raw output from the managed system
class ManageIQ::Providers::Autosde::Inventory::Collector::StorageManager < ManageIQ::Providers::Inventory::Collector

  # @return [ManageIQ::Providers::Autosde::StorageManager]
  attr_accessor :manager

  def collect
    new_inventory = {}

    new_inventory[:storage_systems] = []
    @manager.autosde_client.class::StorageSystemApi.new.storage_systems_get.each do |system|
      # @type [ManageIQ::Providers::Autosde::StorageManager::AutosdeClient::StorageSystem]
      system = system
      new_inventory[:storage_systems] << {
          :name => system.name,
          :ems_ref => system.uuid,
          :uuid => system.uuid,
          :system_type => system.system_type,
          :storage_family => system.storage_family,
          :management_ip => system.management_ip
      }
    end

    new_inventory[:storage_resources] = []
    @manager.autosde_client.class::StorageResourceApi.new.storage_resources_get.each do |resource|
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

    new_inventory[:storage_volumes] = []
    @manager.autosde_client.class::VolumeApi.new.volumes_get.each do |volume|
      # @type [ManageIQ::Providers::Autosde::StorageManager::AutosdeClient::Volume]
      volume = volume
      new_inventory[:storage_volumes] << {
          :name => volume.name,
          :compliant => volume.compliant,
          :size => volume.size,
          :ems_ref => volume.uuid,
          :uuid => volume.uuid,
          :storage_resource_uuid => volume.storage_resource
      }
    end

    @inventory = new_inventory
  end
end
