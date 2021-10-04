class ManageIQ::Providers::Autosde::StorageManager::HostInitiator < ::HostInitiator
  supports :create

  def self.raw_create_host_initiator(ext_management_system, options = {})
    # wwpn values send to autosde should be format as colon separated string (e.g. WWPN1:WWPN2:WWPN3)
    wwpn_values = options['wwpn'].join(":") if options['wwpn']

    host_initiator_to_create = ext_management_system.autosde_client.StorageHostCreate(
      :name           => options['name'],
      :port_type      => options['port_type'],
      :storage_system => PhysicalStorage.find(options['physical_storage_id']).ems_ref,
      :iqn            => options['iqn'] || "",
      :wwpn           => wwpn_values || "",
      :chap_name      => options['chap_name'] || "",
      :chap_secret    => options['chap_secret'] || ""
    )

    ext_management_system.autosde_client.StorageHostApi.storage_hosts_post(host_initiator_to_create)
    EmsRefresh.queue_refresh(ext_management_system)
  end
end
