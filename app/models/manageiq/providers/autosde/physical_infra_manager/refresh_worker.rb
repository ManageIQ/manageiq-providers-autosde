class ManageIQ::Providers::Autosde::PhysicalInfraManager::RefreshWorker < MiqEmsRefreshWorker
  require_nested :Runner

  def self.ems_class
    parent
  end
end
