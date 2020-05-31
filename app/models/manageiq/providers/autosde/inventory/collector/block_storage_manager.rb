# This class is supposed to collect raw output from the managed system
class ManageIQ::Providers::Autosde::Inventory::Collector::BlockStorageManager < ManageIQ::Providers::Inventory::Collector

  # @return [ManageIQ::Providers::Autosde::BlockStorageManager]
  attr_accessor :manager

  def collect
    new_inventory = {}

    new_inventory[:physical_storages] = []

    @manager.autosde_client.class::StorageSystemApi.new.storage_systems_get.each do |storage|
      #  @type [OpenapiClient::StorageSystem] storage
      new_inventory[:physical_storages] << {
          :name => storage.name,
          :uid_ems => storage.uuid,
          :ems_ref => storage.uuid,
      }
    end

    new_inventory[:storage_resources] = []
    @manager.autosde_client.class::StorageResourceApi.new.storage_resources_get.each do |resource|
      # @type [ManageIQ::Providers::Autosde::BlockStorageManager::AutosdeClient::StorageResource]
      resource = resource
      new_inventory[:storage_resources] << {
          :name => resource.name,
          :uuid => resource.uuid,
          :ems_ref => resource.uuid,
          :logical_free => resource.logical_free,
          :logical_total => resource.logical_total,
          :pool_name => resource.pool_name,
      }
    end

    @inventory = new_inventory
  end
end
