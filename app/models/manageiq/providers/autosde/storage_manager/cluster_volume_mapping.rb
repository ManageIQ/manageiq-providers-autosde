class ManageIQ::Providers::Autosde::StorageManager::ClusterVolumeMapping <
  ManageIQ::Providers::Autosde::StorageManager::VolumeMapping
  def mapped_to
    host_initiator_group
  end
end
