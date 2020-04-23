# Dummy class to allow require_nested of ManageIQ::Providers::Autosde::Inventory::Persister::SdeManager
# ManageIQ::Providers::Autosde::Inventory::Persister::SdeManager must be located as it is
class ManageIQ::Providers::Autosde::Inventory::Persister
  require_nested :SdeManager
end
