class ManageIQ::Providers::Autosde::StorageManager::CloudVolume < ::CloudVolume
  supports :create

  # @param [ExtManagementSystem] _ext_management_system
  def self.raw_create_volume(_ext_management_system, _options = {})
    storage_resource = StorageResource.find(_options[:storage_resource_id])

    puts "--------------------------------------------------------------------------------------"
    puts "------------------------------------------raw_create_volume----------------------------------"
    puts ext_management_system.inspect
    puts storage_resource.inspect
    # todo [per gregoryb]: here we need to send the command to autosde to create the volume

    self.create(
        :ext_management_system => _ext_management_system,
        :storage_resource => storage_resource,
        **options
    )

  end
end