# Class that needs to generate a hash that represents the entire inventory of the EMS
# The hash needs to be in a format that's ready to be deserialized into the DB
# Not in use. inventory/parser is used instead.
class ManageIQ::Providers::Autosde::StorageManager::RefreshParser < EmsRefresh::Parsers::Infra
  def initialize(ems, _options = nil)
    @ems = ems
  end

  # this method adds stuff to collection on top of inventory system.
  # Currently this is not in use because I use inventory/parser
  def self.ems_inv_to_hashes(ems, options = nil)
  end
end
