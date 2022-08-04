class ManageIQ::Providers::Autosde::StorageManager::VolumeMapping < ::VolumeMapping
  HOST_MAPPING_OBJECT = 'host'.freeze
  HOST_GROUP_MAPPING_OBJECT = 'host_group'.freeze

  supports :create

  supports :delete do
    unsupported_reason_add(:delete, _("The Volume mapping is not connected to an active Manager")) if ext_management_system.nil?
  end

  def raw_delete_volume_mapping
    ems = ext_management_system
    task_id = ems.autosde_client.StorageHostsMappingApi.storage_hosts_mapping_pk_delete(ems_ref)
    status = ManageIQ::Providers::Autosde::StorageManager::AutosdeClient.wait_for_success(ems, task_id.task_id, 2, 4)
    if status == "SUCCESS"
      EmsRefresh.queue_refresh(ext_management_system)
    else
      ManageIQ::Providers::Autosde::StorageManager::AutosdeClient.raise_non_success_exception(done_status)
    end
  end

  def self.raw_create_volume_mapping(ext_management_system, options = {})
    # this method has 2 flow:
    # 1 - for host_initiator
    # 2 - for host_initiator_group
    # The options dict contains a field named mapping_object. The supported values for this field are 'host' and cluster'

    volume_ref = CloudVolume.find(options['cloud_volume_id']).ems_ref
    case options['mapping_object']
    when HOST_MAPPING_OBJECT
      host_volume_mapping_to_create = ext_management_system.autosde_client.StorageHostsMappingCreate(
        :host   => HostInitiator.find(options['host_initiator_id']).ems_ref,
        :volume => volume_ref
      )
      ext_management_system.autosde_client.StorageHostsMappingApi.storage_hosts_mapping_post(host_volume_mapping_to_create)
    when HOST_GROUP_MAPPING_OBJECT
      cluster_volume_mapping_to_create = ext_management_system.autosde_client.HostClusterVolumeMappingCreate(
        :cluster => HostInitiatorGroup.find(options['host_initiator_group_id']).ems_ref,
        :volume  => volume_ref
      )
      ext_management_system.autosde_client.HostClusterVolumeMappingApi.host_clusters_mapping_post(cluster_volume_mapping_to_create)
    end
    EmsRefresh.queue_refresh(ext_management_system)
  end
end
