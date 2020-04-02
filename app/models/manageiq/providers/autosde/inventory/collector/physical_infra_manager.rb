# This class is supposed to collect raw output from the managed system, as far as I can tell.
# I think it's only used for the new inventory system. But It's a good place to put our collection logic.
class ManageIQ::Providers::Autosde::Inventory::Collector::PhysicalInfraManager < ManageIQ::Providers::Inventory::Collector
  attr_reader :inventory

  # Collect output of all devices registered in the autosde instance.
  # Output is a hash that's ready to be deserialized to the DB
  # I put this Inventory::Collector instead of refresh_parser because I think this is how it's designed to be.
  # Maybe this will ease transition to new inventory system?
  def collect
    inventory = {}
    inventory[:physical_storages] = []

    @manager.autosde.get_storage_systems.each do |autosde_system_dict|
      inventory[:physical_storages] << {
          :name => autosde_system_dict["name"],
          :uid_ems => autosde_system_dict["uuid"],
          :ems_ref => autosde_system_dict["uuid"],
          :asset_detail => {
              :machine_type => autosde_system_dict["system_type"]["name"],
          }
      }
    end

    @inventory = inventory
  end
end
