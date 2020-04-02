# Class that needs to generate a hash that represents the entire inventory of the EMS
# The hash needs to be in a format that's ready to be deserialized into the DB
class ManageIQ::Providers::Autosde::PhysicalInfraManager::RefreshParser < EmsRefresh::Parsers::Infra

  def initialize(ems, _options = nil)
    @ems = ems
  end

  def self.ems_inv_to_hashes (ems, options = nil)
    ManageIQ::Providers::Autosde::Inventory::Collector::PhysicalInfraManager.new(ems, nil).collect
  end

end