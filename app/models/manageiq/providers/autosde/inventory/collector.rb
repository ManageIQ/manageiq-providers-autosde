# Dummy class to allow require_newsted of ManageIQ::Providers::Autosde::Inventory::Collector::PhysicalInfraManager
# ManageIQ::Providers::Autosde::Inventory::Collector::PhysicalInfraManager must be located as it is
class ManageIQ::Providers::Autosde::Inventory::Collector
  require_nested :PhysicalInfraManager
end