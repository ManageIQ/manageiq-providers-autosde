# Dummy class to allow require_newsted of ManageIQ::Providers::Autosde::Inventory::Collector::SdeManager
# ManageIQ::Providers::Autosde::Inventory::Collector::SdeManager must be located as it is
class ManageIQ::Providers::Autosde::Inventory::Collector
  require_nested :SdeManager
end