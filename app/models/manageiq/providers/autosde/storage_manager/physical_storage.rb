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

  # @param [ManageIQ::Providers::Autosde] _ext_management_system
  def self.raw_create_physical_storage(_ext_management_system, _options = {})
    sys_to_create = _ext_management_system.autosde_client.StorageSystemCreate(
      :password       => _options['password'],
      :user           => _options['user'],
      :system_type    => PhysicalStorageFamily.find(_options['physical_storage_family_id']).name,
      :auto_add_pools => true,
      :auto_setup     => true,
      :management_ip  => _options['management_ip'],
      :storage_family => "ontap_7mode"
    )

    begin
      new_storage = _ext_management_system.autosde_client.StorageSystemApi.storage_systems_post(sys_to_create)
    ensure
      EmsRefresh.queue_refresh(
        InventoryRefresh::Target.new(
          :manager     => _ext_management_system,
          :association => :physical_storages,
          :manager_ref => {:ems_ref => new_storage.uuid}
        )
      )
    end
  end
end
