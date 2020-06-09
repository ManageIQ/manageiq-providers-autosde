class ManageIQ::Providers::Autosde::StorageManager::CloudVolume < ::CloudVolume
  supports :create

  # Has to be override the base method.. It's supposed to implement creating the volume on the EMS.
  # But I only create it in MIQ DB for now.
  # @param [ExtManagementSystem] _ext_management_system
  def self.raw_create_volume(_ext_management_system, _options = {})
    storage_resource = _options[:storage_resource]
    # todo [per gregoryb]: here we need to send the command to autosde to create the volume

    self.create(
        :ext_management_system => _ext_management_system,
        :storage_resource => storage_resource,
        **_options
    )

  end

  # has to be overriden and return a specifically-formatted hash.
  def self.validate_create_volume(ext_management_system)
    # check that the ems isn't nil and return a correctly formatted hash.
    validate_volume(ext_management_system)
  end
end