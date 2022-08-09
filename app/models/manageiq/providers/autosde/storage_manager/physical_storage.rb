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
    ems.autosde_client.StorageSystemApi.storage_systems_pk_delete(ems_ref)
    EmsRefresh.queue_refresh(self)
  end

  def self.raw_validate_physical_storage(ext_management_system, options = {})
    validation_object = ext_management_system.autosde_client.StorageSystemCreate(
      :management_ip => options['management_ip'],
      :user => options['user'],
      :password => options['password'],
      :system_type => PhysicalStorageFamily.find(options['physical_storage_family_id']).name
    )
    ext_management_system.autosde_client.ValidateSystemApi.validate_system_post(validation_object)
  end

  def raw_update_physical_storage(options = {})
    update_details = ext_management_system.autosde_client.StorageSystemUpdate(
      :name => options['name'],
      :password => options['password'] || "",
      :user => options['user'] || "",
      :management_ip => options['management_ip'] || ""
    )
    ext_management_system.autosde_client.StorageSystemApi.storage_systems_pk_put(ems_ref, update_details)
    EmsRefresh.queue_refresh(self)
  end

  def self.raw_create_physical_storage(ext_management_system, options = {})
    sys_to_create = ext_management_system.autosde_client.StorageSystemCreate(
      :password => options['password'],
      :user => options['user'],
      :system_type => PhysicalStorageFamily.find(options['physical_storage_family_id']).name,
      :management_ip => options['management_ip'],
      :storage_family => "ontap_7mode"
    )

    begin
      new_storage = ext_management_system.autosde_client.StorageSystemApi.storage_systems_post(sys_to_create)
      ### SETUP SERVICE CATALOG COMPONENTS ###
      # CATALOG
      catalog_id = ServiceTemplateCatalog.find_or_create_by(:name => "AutoSDE Catalog").id
      # DIALOG
      vol_dialog = YAML.load_file('plugins/manageiq-providers-autosde/service_catalog/volume/dialog.yaml')
      vol_dialog_id = DialogImportService.new.import(vol_dialog).id
      # ITEM
      vol_item_prop = { :name => "Volume", :prov_type => "autosde", :display => "true", :service_template_catalog_id => catalog_id,
                        :config_info => { :provision => { :fqname => "/Storage/AutoSde/Services/ServiceVolumeRequestApproval/Default", :dialog_id => vol_dialog_id } } }
      ServiceTemplate.create_catalog_item(vol_item_prop, nil) unless ServiceTemplate.find_by(:name => vol_item_prop[:name]) != nil
    ensure
      EmsRefresh.queue_refresh(
        InventoryRefresh::Target.new(
          :manager => ext_management_system,
          :association => :physical_storages,
          :manager_ref => { :ems_ref => new_storage.uuid }
        )
      )
    end
  end
end
