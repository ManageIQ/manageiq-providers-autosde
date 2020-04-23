# This class is supposed to collect raw output from the managed system
class ManageIQ::Providers::Autosde::Inventory::Collector::SdeManager < ManageIQ::Providers::Inventory::Collector

  # @return [ManageIQ::Providers::Autosde::SdeManager]
  attr_accessor :manager

  def collect
    new_inventory = {}

    new_inventory[:physical_storages] = []

    @manager.autosde_client.storage_system_api.storage_systems_get.each do |storage|
      #  @type [OpenapiClient::StorageSystem] storage
      new_inventory[:physical_storages] << {
          :name => storage.name,
          :uid_ems => storage.uuid,
          :ems_ref => storage.uuid,
      }
    end
    @inventory = new_inventory
  end
end
