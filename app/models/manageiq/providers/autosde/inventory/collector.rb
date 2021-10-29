class ManageIQ::Providers::Autosde::Inventory::Collector < ManageIQ::Providers::Inventory::Collector
  require_nested :StorageManager
  require_nested :TargetCollection
end
