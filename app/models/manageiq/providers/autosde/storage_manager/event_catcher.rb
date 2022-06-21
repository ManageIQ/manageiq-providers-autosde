class ManageIQ::Providers::Autosde::StorageManager::EventCatcher < ManageIQ::Providers::BaseManager::EventCatcher
  require_nested :Runner
  require_nested :Stream
end
