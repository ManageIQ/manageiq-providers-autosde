class ManageIQ::Providers::Autosde::BlockStorageManager::MetricsCollectorWorker < ManageIQ::Providers::BaseManager::MetricsCollectorWorker
  require_nested :Runner

  self.default_queue_name = "autosde"

  def friendly_name
    @friendly_name ||= "C&U Metrics Collector for ManageIQ::Providers::Autosde"
  end
end
