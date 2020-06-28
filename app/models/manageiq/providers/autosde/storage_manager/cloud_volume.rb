class ManageIQ::Providers::Autosde::StorageManager::CloudVolume < ::CloudVolume
  supports :create

  # Has to be override the base method.. It's supposed to implement creating the volume on the EMS.
  # But I only create it in MIQ DB for now.
  # @param [ManageIQ::Providers::Autosde] _ext_management_system
  def self.raw_create_volume(_ext_management_system, _options = {})
    # @type [StorageService]
    storage_service = _options[:storage_service]

    vol_to_create = _ext_management_system.autosde_client.VolumeCreate(
        service: storage_service.ems_ref,
        name: _options[:name],
        size: _options[:size]
    )
    _ext_management_system.autosde_client.VolumeApi.volumes_post(vol_to_create)
    EmsRefresh.queue_refresh(_ext_management_system)

  end

  # has to be overriden and return a specifically-formatted hash.
  def self.validate_create_volume(ext_management_system)
    # check that the ems isn't nil and return a correctly formatted hash.
    validate_volume(ext_management_system)
  end

  # ================= delete  ================

  def raw_delete_volume
    ems = self.ext_management_system
    ems.autosde_client.VolumeApi.volumes_pk_delete(self.ems_ref)
    EmsRefresh.queue_refresh(ems)
  end

  def validate_delete_volume
    return {:available => true, :message => nil}
  end

  # ================ safe-delete ================

  def validate_safe_delete_volume
    return {:available => true, :message => nil}
  end

  def raw_safe_delete_volume
    self.ext_management_system.autosde_client.VolumeApi.volumes_safe_delete(self.ems_ref)
    EmsRefresh.queue_refresh(self.ext_management_system)
  end

end