class ManageIQ::Providers::Autosde::StorageManager::HostInitiator < ::HostInitiator
  supports :create

  def self.raw_create_host_initiator(ext_management_system, options = {})
    host_initiator_to_create = ext_management_system.autosde_client.StorageHostCreate(
      :name           => options['name'],
      :port_type      => options['port_type'],
      :storage_system => PhysicalStorage.find(options['physical_storage_id']).ems_ref,
      :iqn            => options['iqn'] || "",
      :wwpn           => options['wwpn'] || "",
      :chap_name      => options['chap_name'] || "",
      :chap_secret    => options['chap_secret'] || ""
    )

    begin
      ext_management_system.autosde_client.StorageHostApi.storage_hosts_post(host_initiator_to_create)
    ensure
      EmsRefresh.queue_refresh(ext_management_system)
    end
  end
end
