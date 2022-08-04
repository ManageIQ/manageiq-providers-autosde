class ManageIQ::Providers::Autosde::StorageManager::PhysicalStorage < ::PhysicalStorage
  supports :create
  supports :update do
    unsupported_reason_add(:update, _("The Physical Storage is not connected to an active Manager")) if ext_management_system.nil?
  end
  supports :delete do
    unsupported_reason_add(:delete, _("The Physical Storage is not connected to an active Manager")) if ext_management_system.nil?
  end
  supports :validate

  def raw_delete_physical_storage
    ems = ext_management_system
    task_id = ems.autosde_client.StorageSystemApi.storage_systems_pk_delete(ems_ref)
    status = ManageIQ::Providers::Autosde::StorageManager::AutosdeClient.wait_for_success(ems, task_id.task_id, 2, 4)
    if status == "SUCCESS"
      EmsRefresh.queue_refresh(self)
    else
      ManageIQ::Providers::Autosde::StorageManager::AutosdeClient.raise_non_success_exception(done_status)
    end
  end

  def self.raw_validate_physical_storage(ext_management_system, options = {})
    validation_object = ext_management_system.autosde_client.StorageSystemCreate(
      :management_ip => options['management_ip'],
      :user          => options['user'],
      :password      => options['password'],
      :system_type   => PhysicalStorageFamily.find(options['physical_storage_family_id']).name
    )
    ext_management_system.autosde_client.ValidateSystemApi.validate_system_post(validation_object)
  end

  def raw_update_physical_storage(options = {})
    update_details = ext_management_system.autosde_client.StorageSystemUpdate(
      :name          => options['name'],
      :password      => options['password'] || "",
      :user          => options['user'] || "",
      :management_ip => options['management_ip'] || ""
    )
    ems = ext_management_system
    task_id = ems.autosde_client.StorageSystemApi.storage_systems_pk_put(ems_ref, update_details)
    status = ManageIQ::Providers::Autosde::StorageManager::AutosdeClient.wait_for_success(ems, task_id.task_id, 100, 5)
    if status == "SUCCESS"
      EmsRefresh.queue_refresh(self)
    else
      ManageIQ::Providers::Autosde::StorageManager::AutosdeClient.raise_non_success_exception(done_status)
    end
  end

  def self.raw_create_physical_storage(ext_management_system, options = {})
    sys_to_create = ext_management_system.autosde_client.StorageSystemCreate(
      :password       => options['password'],
      :user           => options['user'],
      :system_type    => PhysicalStorageFamily.find(options['physical_storage_family_id']).name,
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
