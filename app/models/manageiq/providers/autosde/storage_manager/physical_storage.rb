class ManageIQ::Providers::Autosde::StorageManager::PhysicalStorage < ::PhysicalStorage
  supports :create
  supports :update do
    unsupported_reason_add(:update, _("The Physical Storage is not connected to an active Manager")) if ext_management_system.nil?
  end
  supports :delete do
    unsupported_reason_add(:delete, _("The Physical Storage is not connected to an active Manager")) if ext_management_system.nil?
  end

  def raw_delete_physical_storage
    ems = ext_management_system
    ems.autosde_client.StorageSystemApi.storage_systems_pk_delete(ems_ref)
    EmsRefresh.queue_refresh(self)
  end

  def self.raw_validate_physical_storage(ext_management_system, options = {})
    header_params = options[:header_params] || {}
    header_params['Accept'] = ext_management_system.autosde_client.select_header_accept(['*/*'])
    header_params['Content-Type'] = ext_management_system.autosde_client.select_header_content_type(['application/json'])

    request_opts = {
      :header_params => header_params,
      :body => options.merge(
        :system_type => PhysicalStorageFamily.find(options['physical_storage_family_id']).name,
      ),
      :auth_names => ['bearerAuth'],
    }

    data, status_code, headers = ext_management_system.autosde_client.call_api(:POST, 'validate-system', request_opts)
    if ext_management_system.autosde_client.config.debugging
      ext_management_system.autosde_client.config.logger.debug "API called: StorageSystemValidation#storage_systems_post\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
    end
    return data, status_code, headers
  end

  def raw_update_physical_storage(options = {})
    update_details = ext_management_system.autosde_client.StorageSystemUpdate(
      :name          => options['name'],
      :password      => options['password'] || "",
      :user          => options['user'] || "",
      :management_ip => options['management_ip'] || ""
    )
    ext_management_system.autosde_client.StorageSystemApi.storage_systems_pk_put(ems_ref, update_details)
    EmsRefresh.queue_refresh(self)
  end

  def self.raw_create_physical_storage(ext_management_system, options = {})
    sys_to_create = ext_management_system.autosde_client.StorageSystemCreate(
      :password       => options['password'],
      :user           => options['user'],
      :system_type    => PhysicalStorageFamily.find(options['physical_storage_family_id']).name,
      :auto_add_pools => true,
      :auto_setup     => true,
      :management_ip  => options['management_ip'],
      :storage_family => "ontap_7mode"
    )

    begin
      new_storage = ext_management_system.autosde_client.StorageSystemApi.storage_systems_post(sys_to_create)
    ensure
      EmsRefresh.queue_refresh(
        InventoryRefresh::Target.new(
          :manager     => ext_management_system,
          :association => :physical_storages,
          :manager_ref => {:ems_ref => new_storage.uuid}
        )
      )
    end
  end
end
