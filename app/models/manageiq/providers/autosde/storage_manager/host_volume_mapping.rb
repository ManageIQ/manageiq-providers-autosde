class ManageIQ::Providers::Autosde::StorageManager::HostVolumeMapping < ManageIQ::Providers::Autosde::StorageManager::VolumeMapping
  def name
    _("Volume <%{cloud_volume_name}> is mapped to Host Initiator <%{host_initiator_name}>") % {:cloud_volume_name => cloud_volume.name, :host_initiator_name => host_initiator.name}
  end
end
