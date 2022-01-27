class ManageIQ::Providers::Autosde::StorageManager::ClusterVolumeMapping < ManageIQ::Providers::Autosde::StorageManager::VolumeMapping
  def name
    _("Volume <%{cloud_volume_name}> is mapped to Host Initiator Group <%{host_initiator_group_name}>") % {:cloud_volume_name => cloud_volume.name, :host_initiator_group_name => host_initiator_group.name}
  end
end
