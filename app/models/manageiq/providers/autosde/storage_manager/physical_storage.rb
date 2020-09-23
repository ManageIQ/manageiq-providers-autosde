class ManageIQ::Providers::Autosde::StorageManager::PhyscialStorage < ::PhysicalStorage
  supports :create

  # @param [ManageIQ::Providers::Autosde] _ext_management_system
  def self.raw_create_physical_storage(_ext_management_system, _options = {})
    sys_to_create = _ext_management_system.autosde_client.StorageSystemCreate(
      :name           => _options[:name],
      :password       => _options[:password],
      :user           => _options[:user],
      :system_type    => _options[:system_type],
      :auto_add_pools => true,
      :auto_setup     => true,
      :management_ip  => _options[:management_ip],
      :storage_family => "ontap_7mode"
    )

    begin
      _ext_management_system.autosde_client.StorageSystemApi.storage_systems_post(sys_to_create)
    ensure
      EmsRefresh.queue_refresh(_ext_management_system)
    end
  end
end
