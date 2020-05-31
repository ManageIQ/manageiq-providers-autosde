# Class that needs to generate a hash that represents the entire inventory of the EMS
# The hash needs to be in a format that's ready to be deserialized into the DB
# Not in use. inventory/parser is used instead.
class ManageIQ::Providers::Autosde::StorageManager::RefreshParser < EmsRefresh::Parsers::Infra

  def initialize(ems, _options = nil)
    @ems = ems
  end

  # this method adds stuff to collection on top of inventory system.
  # Currently this is not in use because I use inventory/parser
  def self.ems_inv_to_hashes (ems, options = nil)
    # inventory[:physical_storages] << {
    #     :name => autosde_system_dict["name"],
    #     :uid_ems => autosde_system_dict["uuid"],
    #     :ems_ref => autosde_system_dict["uuid"],
    #     :asset_detail => {
    #         :machine_type => autosde_system_dict["system_type"]["name"],
    #     }
    # }
  end

end