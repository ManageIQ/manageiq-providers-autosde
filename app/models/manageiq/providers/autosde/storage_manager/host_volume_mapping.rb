class ManageIQ::Providers::Autosde::StorageManager::HostVolumeMapping <
  ManageIQ::Providers::Autosde::StorageManager::VolumeMapping
  def mapped_to
    host_initiator
  end
end
