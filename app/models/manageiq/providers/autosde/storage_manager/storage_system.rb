class ManageIQ::Providers::Autosde::StorageManager::StorageSystem < ::StorageSystem
  supports :create

  # @param [ManageIQ::Providers::Autosde] _ext_management_system
  def self.raw_create_storage_system(_ext_management_system, _options = {})

    sys_to_create = _ext_management_system.autosde_client.class::StorageSystemCreate.new(
        name: _options[:name],
        password: _options[:password],
        user: _options[:user],
        system_type: _options[:system_type],
        auto_add_pools: true,
        auto_setup: true,
        management_ip: _options[:management_ip],
        storage_family: "ontap_7mode"
    )
    _ext_management_system.autosde_client.class::StorageSystemApi.new.storage_systems_post(sys_to_create)

    EmsRefresh.queue_refresh(ext_management_system)

  end

end