class ManageIQ::Providers::Autosde::StorageManager::Refresher < ManageIQ::Providers::BaseManager::Refresher
  def post_process_refresh_classes
    [ManageIQ::Providers::Autosde::StorageManager]
  end
end
