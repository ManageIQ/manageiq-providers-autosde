class ManageIQ::Providers::Autosde::StorageManager::HostInitiator < ::HostInitiator
  supports :create
  supports :delete

  def self.raw_create_host_initiator(ext_management_system, options = {})
    # WWPN/IQN values sent to autosde should be format as colon separated string (e.g. WWPN1:WWPN2:WWPN3)
    wwpns = Array(options['custom_wwpn'])
    wwpns += Array(options['wwpn']).map { |item| item["value"] }
    wwpn_values = wwpns.join(":")

    iqns = Array(options['iqn'])
    iqn_values = iqns.join(":")

    host_initiator_to_create = ext_management_system.autosde_client.StorageHostCreate(
      :name           => options['name'],
      :port_type      => options['port_type'],
      :storage_system => PhysicalStorage.find(options['physical_storage_id']).ems_ref,
      :iqn            => iqn_values || "",
      :wwpn           => wwpn_values || "",
      :chap_name      => options['chap_name'] || "",
      :chap_secret    => options['chap_secret'] || ""
    )

    ext_management_system.autosde_client.StorageHostApi.storage_hosts_post(host_initiator_to_create)
    EmsRefresh.queue_refresh(ext_management_system)
  end

  def raw_delete_host_initiator
    ems = ext_management_system
    task_id = ems.autosde_client.StorageHostApi.storage_hosts_pk_delete(ems_ref)
    status = ManageIQ::Providers::Autosde::StorageManager::AutosdeClient.wait_for_success(ems, task_id.task_id, 2, 4)
    if status == "SUCCESS"
      EmsRefresh.queue_refresh(ems)
    else
      ManageIQ::Providers::Autosde::StorageManager::AutosdeClient.raise_non_success_exception(done_status)
    end
  end
end
