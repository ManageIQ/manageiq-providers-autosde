
class ManageIQ::Providers::Autosde::StorageManager::CloudVolume < ::CloudVolume


  supports :create
  supports :update do
    unsupported_reason_add(:update, _("the volume is not connected to an active provider")) unless ext_management_system
  end

  # cloud volume delete functionality is not supported for now
  supports_not :delete
  supports_not :safe_delete

  def self.raw_create_volume(ext_management_system, options = {})
    # @type [StorageService]
    vol_to_create = ext_management_system.autosde_client.VolumeCreate(
      :service => ext_management_system.storage_services.find(options["storage_service_id"]).ems_ref,
      :name    => options["name"],
      :size    => options["size"],
      :count   => options["count"]
    )

    new_volume = ext_management_system.autosde_client.VolumeApi.volumes_post(vol_to_create)
    EmsRefresh.queue_refresh(
      InventoryRefresh::Target.new(
        :manager     => ext_management_system,
        :association => :cloud_volumes,
        :manager_ref => {:ems_ref => new_volume.uuid}
      )
    )
  end

  # ================= delete  ================

  def raw_delete_volume
    ems = ext_management_system
    task_id = ems.autosde_client.VolumeApi.volumes_pk_delete(ems_ref)
    status = ManageIQ::Providers::Autosde::StorageManager::AutosdeClient.wait_for_success(ems, task_id.task_id, 100, 5)
    if status == "SUCCESS"
      queue_refresh
    else
      ManageIQ::Providers::Autosde::StorageManager::AutosdeClient.raise_non_success_exception(done_status)
    end
  end

  # ================= edit  ================

  def raw_update_volume(options = {})
    update_details = ext_management_system.autosde_client.VolumeUpdate(
      :name => options[:name],
      :size => options[:size_GB]
    )
    ems = ext_management_system
    task_id = ems.autosde_client.VolumeApi.volumes_pk_put(ems_ref, update_details)
    status = ManageIQ::Providers::Autosde::StorageManager::AutosdeClient.wait_for_success(ems, task_id.task_id, 100, 5)
    if status == "SUCCESS"
      queue_refresh
    else
      ManageIQ::Providers::Autosde::StorageManager::AutosdeClient.raise_non_success_exception(done_status)
    end
  end

  # ================ safe-delete ================
  def raw_safe_delete_volume
    ext_management_system.autosde_client.VolumeApi.volumes_safe_delete(ems_ref)
    queue_refresh
  end

  def params_for_update
    initial_size = (size / 1.0.gigabyte).round
    {
      :fields => [
        {
          :component    => "text-field",
          :name         => "storage_service",
          :id           => "storage_service",
          :label        => _("Storage Pool"),
          :isRequired   => true,
          :validate     => [{:type => "required"}],
          :initialValue => storage_service.name,
          :isDisabled   => true
        },
        {
          :component    => "text-field",
          :id           => "size_GB",
          :name         => "size_GB",
          :label        => _("Size (GiB)"),
          :isRequired   => true,
          :validate     => [{:type => "required"},
                            {:type => "pattern", :pattern => '^[-+]?[0-9]\\d*$', :message => _("Must be an integer")},
                            {:type => "min-number-value", :value => initial_size, :message => _("Must be greater than or equal to %d" % [initial_size])}],
          :initialValue => initial_size,
        }
      ]
    }
  end

  def self.params_for_create(provider)
    services = provider.storage_services.map { |service| {:value => service.id.to_s, :label => service.name} }

    {
      :fields => [
        {
          :component    => "select",
          :name         => "storage_service_id",
          :id           => "storage_service_id",
          :label        => _("Storage Pool"),
          :isRequired   => true,
          :validate     => [{:type => "required"}],
          :options      => services,
          :includeEmpty => true,
          :isDisabled   => false
        },
        {
          :component  => "text-field",
          :id         => "size",
          :name       => "size",
          :label      => _("Size (GiB)"),
          :isRequired => true,
          :validate   => [{:type => "required"},
                          {:type => "pattern", :pattern => '^[-+]?[0-9]\\d*$', :message => _("Must be an integer")},
                          {:type => "min-number-value", :value => 1, :message => _('Must be greater than or equal to 1')}],
        },
        {
          :component    => "text-field",
          :id           => "count",
          :name         => "count",
          :label        => _("How many volumes to create. If greater than one, the volume names will be appended with a running index."),
          :initialValue => _("1"),
          :validate     => [{:type => "required"},
                            {:type => "pattern", :pattern => '^[-+]?[0-9]\\d*$', :message => _("Must be an integer")},
                            {:type => "min-number-value", :value => 1, :message => _('Must be greater than or equal to 1')}],
        }
      ]
    }
  end
end
