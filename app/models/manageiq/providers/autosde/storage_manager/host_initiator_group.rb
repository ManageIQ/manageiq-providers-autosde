class ManageIQ::Providers::Autosde::StorageManager::HostInitiatorGroup < ::HostInitiatorGroup
  supports :create

  def self.raw_create_host_initiator_group(ext_management_system, options = {})
    host_initiator_group_to_create = ext_management_system.autosde_client.HostCluster(
      :name           => options['name'],
      :storage_system => PhysicalStorage.find(options['physical_storage_id']).ems_ref
    )
    ext_management_system.autosde_client.HostClusterApi.host_clusters_post(host_initiator_group_to_create)
    EmsRefresh.queue_refresh(ext_management_system)
  end
end
