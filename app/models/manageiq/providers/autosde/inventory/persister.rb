# Dummy class to allow require_newsted of ManageIQ::Providers::Autosde::Inventory::Persister::PhysicalInfraManager
# ManageIQ::Providers::Autosde::Inventory::Persister::PhysicalInfraManager must be located as it is
class ManageIQ::Providers::Autosde::Inventory::Persister
  require_nested :PhysicalInfraManager
end