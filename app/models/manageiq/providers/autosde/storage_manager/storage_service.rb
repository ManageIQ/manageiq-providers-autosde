class ManageIQ::Providers::Autosde::StorageManager::StorageService < ::StorageService
  supports :create
  supports :delete

  def self.raw_create_storage_service(ext_management_system, options = {})
    capability_value_list = options.slice(*ext_management_system.capabilities.keys).values
    capability_value_list.delete("-1")

    creation_hash = {
      :name                  => options['name'],
      :description           => options['description'].nil? ? "none" : options['description'],
      :capability_value_list => capability_value_list,
      :resources             => ext_management_system.storage_resources.find(options["storage_resource_id"].to_a.pluck("value")).pluck(:ems_ref),
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
    capabilities = provider.capabilities.reject { |cap| cap == 'data_reduction' }.map do |name, values|
      {
        :component    => "select",
        :id           => name,
        :name         => name,
        :label        => _(name.split("_").join(" ").capitalize),
        :initialValue => "-1",
        :options      => [
          {:label => "N/A", :value => "-1"},
          {:label => values[0]['value'], :value => values[0]['uuid']},
          {:label => values[1]['value'], :value => values[1]['uuid']}
        ]
      }
    end

    {
      :fields => [
        {
          :component => "sub-form",
          :name      => "required_capabilities",
          :id        => "required_capabilities",
          :title     => _("Required Capabilities"),
          :fields    => capabilities
        }
      ]
    }
  end
end
