class ManageIQ::Providers::Autosde::StorageManager::CloudVolumeSnapshot < ::CloudVolumeSnapshot
  supports :create
  supports :delete

  def self.raw_create_snapshot(cloud_volume, options = {})
    ext_management_system = cloud_volume.ext_management_system
    creation_hash = {
      :name        => options[:name],
      :description => options[:description],
      :volume      => cloud_volume.ems_ref
    }
    snapshot_object = ext_management_system.autosde_client.SnapshotCreate(creation_hash)

    task_id = ext_management_system.autosde_client.SnapshotApi.snapshots_post(snapshot_object).task_id
    options = {
      :target_class   => :cloud_volume_snapshots,
      :target_id      => nil,
      :ems_id         => ext_management_system.id,
      :native_task_id => task_id,
      :interval       => 10.seconds,
      :target_option  => "new"
    }
    ext_management_system.class::EmsRefreshWorkflow.create_job(options).tap(&:signal_start)
  end

  def raw_delete_snapshot
    task_id = ext_management_system.autosde_client.SnapshotApi.snapshots_pk_delete(ems_ref).task_id
    options = {
      :target_id      => id,
      :target_class   => self.class.name,
      :ems_id         => ext_management_system.id,
      :native_task_id => task_id,
      :interval       => 20.seconds,
      :target_option  => "existing"
    }
    ext_management_system.class::EmsRefreshWorkflow.create_job(options).tap(&:signal_start)
  end
end
