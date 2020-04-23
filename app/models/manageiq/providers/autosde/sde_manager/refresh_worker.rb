class ManageIQ::Providers::Autosde::SdeManager::RefreshWorker < MiqEmsRefreshWorker
  require_nested :Runner

  def self.ems_class
    parent
  end
end
