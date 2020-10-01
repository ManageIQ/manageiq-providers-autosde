class ManageIQ::Providers::Autosde::StorageManager::RefreshWorker < MiqEmsRefreshWorker
  require_nested :Runner

  def self.ems_class
    parent
  end
end
