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
    creation_hash = {
      :service => "",
      :name    => options["name"],
      :size    => options["size"],
      :count   => options["count"]
    }

    if options['mode'] == 'Basic'
      creation_hash[:service] = ext_management_system.storage_services.find(options["storage_service_id"]).ems_ref
    else
      creation_hash[:service_name] = options["new_service_name"]
      creation_hash[:resources] = ext_management_system.storage_resources.find(options["storage_resource_id"].to_a.pluck("value")).pluck(:ems_ref)
      creation_hash[:service_capabilities] = options['required_capabilities'].map { |capability| capability["value"] }
    end

    vol_to_create = ext_management_system.autosde_client.VolumeCreate(creation_hash)
    task_id = ext_management_system.autosde_client.VolumeApi.volumes_post(vol_to_create).task_id

    options = {
      :target_class   => :cloud_volumes,
      :target_id      => nil,
      :ems_id         => ext_management_system.id,
      :native_task_id => task_id,
      :interval       => 10.seconds,
      :target_option  => "new"
    }
    ext_management_system.class::EmsRefreshWorkflow.create_job(options).tap(&:signal_start)
  end

  # ================= delete  ================

  def raw_delete_volume
    task_id = ext_management_system.autosde_client.VolumeApi.volumes_pk_delete(ems_ref).task_id
    options = {
      :target_class   => self.class.name,
      :target_id      => id,
      :ems_id         => ext_management_system.id,
      :native_task_id => task_id,
      :interval       => 20.seconds,
      :target_option  => "existing"
    }
    ext_management_system.class::EmsRefreshWorkflow.create_job(options).tap(&:signal_start)
  end

  # ================= edit  ================

  def raw_update_volume(options = {})
    update_details = ext_management_system.autosde_client.VolumeUpdate(
      :name => options[:name],
      :size => options[:size_GB]
    )
    task_id = ext_management_system.autosde_client.VolumeApi.volumes_pk_put(ems_ref, update_details).task_id

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
    capabilities = provider.capabilities.flat_map do |name, values|
      values.map do |c|
        {:label => "#{name}: #{c['value']}", :value => c['uuid']}
      end
    end

    {
      :fields => [
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
        },
        {
          :component    => "radio",
          :name         => "mode",
          :id           => "mode",
          :label        => _("Mode"),
          :initialValue => 'Basic',
          :options      => [{:label => 'Basic', :value => 'Basic',}, {:label => 'Advanced', :value => 'Advanced'}],
          :isRequired   => true,
          :validate     => [{:type => "required"}]
        },
        {
          :component  => "select",
          :name       => "required_capabilities",
          :id         => "required_capabilities",
          :label      => _("Required Capabilities (filters by exact match)"),
          :options    => capabilities,
          :isRequired => true,
          :isMulti    => true,
          :validate   => [{:type => "required"}]
        }
      ]
    }
  end
end
