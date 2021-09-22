class ManageIQ::Providers::Autosde::StorageManager::VolumeMapping < ::VolumeMapping
  supports :create

  supports :delete do
    unsupported_reason_add(:delete, _("The Volume mapping is not connected to an active Manager")) if ext_management_system.nil?
  end

  def raw_delete_volume_mapping
    ext_management_system.autosde_client.StorageHostVolumeMappingApi.storage_hosts_mapping_pk_delete(ems_ref)
    EmsRefresh.queue_refresh(ext_management_system)
  end

  def self.raw_create_volume_mapping(ext_management_system, options = {})

    volume_mapping_to_create = ext_management_system.autosde_client.StorageHostVolumeMappingCreate(
      :host => HostInitiator.find(options['host_initiator_id']).ems_ref,
      :volume => CloudVolume.find(options['cloud_volume_id']).ems_ref
    )

    ext_management_system.autosde_client.StorageHostVolumeMappingApi.storage_hosts_mapping_post(volume_mapping_to_create)
    EmsRefresh.queue_refresh(ext_management_system)
  end
end
