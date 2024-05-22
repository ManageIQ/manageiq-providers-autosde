class ManageIQ::Providers::Autosde::StorageManager::HostInitiatorGroup < ::HostInitiatorGroup
  supports :create
  supports :update do
    _("the host initiator group is not connected to an active provider") unless ext_management_system
  end
  supports :delete do
    _("the host initiator group is not connected to an active provider") unless ext_management_system
  end

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

  # ================= delete  ================

  def raw_delete_host_initiator_group
    task_id = ext_management_system.autosde_client.HostClusterApi.host_clusters_pk_delete(ems_ref).task_id
    options = {
      :target_class   => self.class.name,
      :target_option  => "existing",
      :target_id      => id,
      :ems_id         => ext_management_system.id,
      :native_task_id => task_id,
      :interval       => 20.seconds
    }
    ext_management_system.class::EmsRefreshWorkflow.create_job(options).tap(&:signal_start)
  end

  # ================= edit  ================

  def raw_update_host_initiator_group(options = {})
    update_details = ext_management_system.autosde_client.HostClusterUpdate(
      :name => options[:name]
    )
    task_id = ext_management_system.autosde_client.HostClusterApi.host_clusters_pk_put(ems_ref, update_details).task_id

    options = {
      :target_class   => self.class.name,
      :target_id      => id,
      :ems_id         => ext_management_system.id,
      :native_task_id => task_id,
      :interval       => 10.seconds,
      :target_option  => "existing"
    }
    ext_management_system.class::EmsRefreshWorkflow.create_job(options).tap(&:signal_start)
  end
end
