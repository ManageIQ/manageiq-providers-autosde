class ManageIQ::Providers::Autosde::StorageManager::HostInitiatorGroup < ::HostInitiatorGroup
  supports :create

  def self.raw_create_host_initiator_group(ext_management_system, options = {})
    host_initiator_group_to_create = ext_management_system.autosde_client.HostCluster(
      :name           => options['name'],
      :storage_system => PhysicalStorage.find(options['physical_storage_id']).ems_ref
    )
    task_id =
      ext_management_system.autosde_client.HostClusterApi.host_clusters_post(host_initiator_group_to_create).task_id

    options = {
      :target_class   => nil,
      :target_id      => nil,
      :ems_id         => ext_management_system.id,
      :native_task_id => task_id,
      :interval       => 10.seconds,
      :target_option  => "ems"
    }
    ext_management_system.class::EmsRefreshWorkflow.create_job(options).tap(&:signal_start)
  end
end
