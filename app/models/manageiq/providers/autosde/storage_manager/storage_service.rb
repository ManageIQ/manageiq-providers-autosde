class ManageIQ::Providers::Autosde::StorageManager::StorageService < ::StorageService
  supports :create
  supports :delete
  supports :update
  supports :check_compliant_resources

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

  def prepare_update_hash(options = {})
    # send resources only if edited
    current_resources = storage_resources.ids
    selected_resources = options["storage_resource_id"].to_a.pluck("value").map(&:to_i)
    resources = if current_resources.sort != selected_resources.sort
                  ext_management_system.storage_resources.find(options["storage_resource_id"].to_a.pluck("value")).pluck(:ems_ref)
                end
    # send capability_value_list only if edited
    selected_capabilities_refs = options.slice(*ext_management_system.capabilities.keys).values
    selected_capabilities_refs.delete("-1")  # get rid of the N/A option
    current_capabilities = ext_management_system.capabilities.slice(*capabilities.keys)
    current_capabilities_refs = []
    capabilities.each do |key, value|
      current_capabilities[key].each do |cap|
        current_capabilities_refs.push(cap["uuid"]) if cap["value"] == value
      end
    end
    capability_value_list = if current_capabilities_refs.sort != selected_capabilities_refs.sort
                              selected_capabilities_refs
                            end

    {
      :name               => options['name'],
      :description        => options['description'],
      :resources          => resources,
      :capability_id_list => capability_value_list
    }
  end

  def raw_update_storage_service(options = {})
    update_hash = prepare_update_hash(options)
    update_details = ext_management_system.autosde_client.ServiceUpdate(update_hash)
    task_id = ext_management_system.autosde_client.ServiceApi.services_pk_put(ems_ref, update_details).task_id

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

  def self.raw_check_compliant_resources(ext_management_system, options = {})
    capability_value_list = options.slice(*ext_management_system.capabilities.keys).values
    capability_value_list.delete("-1")

    compliance_object = ext_management_system.autosde_client.ServiceResourcesCompliance(
      :service           => ext_management_system.storage_services.find(options["_id"]).ems_ref,
      :capability_values => capability_value_list
    )
    ext_management_system.autosde_client.ServiceResourcesComplianceApi.service_resources_compliance_post(compliance_object)
  end

  def params_for_update
    {
      :fields => [
        {
          :component => "sub-form",
          :name      => "required_capabilities",
          :id        => "required_capabilities",
          :title     => _("Required Capabilities"),
          :fields    => self.class.provider_capabilities(ext_management_system, capabilities)
        }
      ]
    }
  end

  def self.params_for_create(provider)
    {
      :fields => [
        {
          :component => "sub-form",
          :name      => "required_capabilities",
          :id        => "required_capabilities",
          :title     => _("Required Capabilities"),
          :fields    => provider_capabilities(provider)
        }
      ]
    }
  end

  def self.provider_capabilities(provider, existing_caps = nil)
    provider.capabilities.reject { |cap| cap == 'data_reduction' }.map do |name, values|
      if existing_caps && existing_caps[name]
        cap = values.find { |value| value["value"] == existing_caps[name] }
        default_value = cap["uuid"]
      else
        default_value = "-1"
      end

      {
        :component    => "select",
        :id           => name,
        :name         => name,
        :label        => _(name.split("_").join(" ").capitalize),
        :initialValue => default_value,
        :options      => [
          {:label => "N/A", :value => "-1"},
          {:label => values[0]['value'], :value => values[0]['uuid']},
          {:label => values[1]['value'], :value => values[1]['uuid']}
        ]
      }
    end
  end
end
