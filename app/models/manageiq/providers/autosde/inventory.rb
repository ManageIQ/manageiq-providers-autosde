class ManageIQ::Providers::Autosde::Inventory < ManageIQ::Providers::Inventory
  # Default manager for building collector/parser/persister classes
  # when failed to get class name from refresh target automatically
  def self.default_manager_name
    "StorageManager"
  end

  def self.parser_class_for(_ems, _target = nil, _manager_name = nil)
    ManageIQ::Providers::Autosde::Inventory::Parser::StorageManager
  end
end
