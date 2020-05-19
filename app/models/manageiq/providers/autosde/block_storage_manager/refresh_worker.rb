class ManageIQ::Providers::Autosde::BlockStorageManager::RefreshWorker < MiqEmsRefreshWorker
  require_nested :Runner

  def self.ems_class
    parent
  end
end
