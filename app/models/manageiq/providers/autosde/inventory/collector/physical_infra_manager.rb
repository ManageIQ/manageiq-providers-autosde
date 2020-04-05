# This class is supposed to collect raw output from the managed system
class ManageIQ::Providers::Autosde::Inventory::Collector::PhysicalInfraManager < ManageIQ::Providers::Inventory::Collector
  attr_reader :inventory

  def collect
    inventory = {}

    inventory[:physical_storages] = []

    @manager.autosde_client.get_storage_systems.each do |autosde_system_dict|
      inventory[:physical_storages] << {
          :name => autosde_system_dict["name"],
          :uid_ems => autosde_system_dict["uuid"],
          :ems_ref => autosde_system_dict["uuid"],
      }
    end

    @inventory = inventory
  end
end
