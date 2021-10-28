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

  def self.parser_class_for(_ems, _target = nil, _manager_name = nil)
    ManageIQ::Providers::Autosde::Inventory::Parser::StorageManager
  end
end
