class ManageIQ::Providers::Autosde::Inventory < ManageIQ::Providers::Inventory
  require_nested :Collector
  require_nested :Parser
  require_nested :Persister

  # Default manager for building collector/parser/persister classes
  # when failed to get class name from refresh target automatically
  # todo: ask Adam if we can remove this
  def self.default_manager_name
    "PhysicalInfraManager"
  end

  def self.parser_classes_for(ems, target)
    case target
    when InventoryRefresh::TargetCollection
      [ManageIQ::Providers::Autosde::Inventory::Parser::StorageManager]
    else
      super
    end
  end
end
