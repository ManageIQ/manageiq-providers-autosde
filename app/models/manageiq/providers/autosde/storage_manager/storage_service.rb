class ManageIQ::Providers::Autosde::StorageManager::StorageService < ::StorageService
  supports :create
  supports :delete do
    unsupported_reason_add(:delete, _("Cannot delete a Storage Service which has volumes")) if cloud_volumes.present?
  end

  def self.raw_create_storage_service(ext_management_system, options = {})
    creation_hash = {
      :name                  => options['name'],
      :description           => options['description'].nil? ? "none" : options['description'],
      :capability_value_list => options['required_capabilities'].map { |capability| capability["value"] },
      # currently only one default optional value is added in the backend for each of these,
      # but in the future we might add them as miq models with more optional values:
      :project               => "",
      :profile               => "",
      :provisioning_strategy => ""
    }
    service_to_create = ext_management_system.autosde_client.ServiceCreate(creation_hash)

    task_id = ext_management_system.autosde_client.ServiceApi.services_post(service_to_create).task_id
    options = {
      :target_class   => :storage_services,
      :target_id      => nil,
      :ems_id         => ext_management_system.id,
      :native_task_id => task_id,
      :interval       => 10.seconds,
      :target_option  => "new"
    }
    ext_management_system.class::EmsRefreshWorkflow.create_job(options).tap(&:signal_start)
  end

  def raw_delete_storage_service
    raise "Deleting Storage Service #{name} failed because it has volumes" if cloud_volumes.present?

    task_id = ext_management_system.autosde_client.ServiceApi.services_pk_delete(ems_ref).task_id
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

  def self.params_for_create(provider)
    capabilities = provider.capabilities.map do |capability|
      {:label => "#{capability['abstract_capability']}: #{capability['value']}", :value => capability['uuid']}
    end

    {
      :fields => [
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
