# Dummy class to allow require_nested of ManageIQ::Providers::Autosde::Inventory::Persister::StorageManager
# ManageIQ::Providers::Autosde::Inventory::Persister::StorageManager must be located as it is
class ManageIQ::Providers::Autosde::Inventory::Persister
  require_nested :StorageManager
end
