class ManageIQ::Providers::Autosde::StorageManager::HostInitiator < ::HostInitiator
  supports :create

  def self.raw_create_host_initiator(_ext_management_system, _options = {})
    host_initiator_to_create = _ext_management_system.autosde_client.StorageHostCreate(
      :name           => _options['name'],
      :port_type      => _options['port_type'],
      :storage_system => PhysicalStorage.find(_options['physical_storage_id']).ems_ref,
      :iqn            => _options['iqn'] || "",
      :wwpn           => _options['wwpn'] || "",
      :chap_name      => _options['chap_name'] || "",
      :chap_secret    => _options['chap_secret'] || ""
    )

    begin
      _ext_management_system.autosde_client.StorageHostApi.storage_hosts_post(host_initiator_to_create)
    ensure
      EmsRefresh.queue_refresh(_ext_management_system)
    end
  end
end
