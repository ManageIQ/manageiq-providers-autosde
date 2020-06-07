class ManageIQ::Providers::Autosde::StorageManager::StorageVolume < ::StorageVolume
  supports :create

  # @param [StorageResource] storage_resource
  # @param [ExtManagementSystem] ext_management_system
  def self.raw_create_volume(ext_management_system, storage_resource, size, name, options = {})

    puts "--------------------------------------------------------------------------------------"
    puts "------------------------------------------raw_create_volume----------------------------------"
    puts ext_management_system.inspect
    puts storage_resource.inspect
    puts size
    puts name
    # todo [per gregoryb]: here we need to send the command to autosde to create the volume

    self.create(
        :ext_management_system => ext_management_system,
        :storage_resource => storage_resource,
        :size => size,
        :name => name,
        **options
    )

  end
end