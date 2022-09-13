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
    task_id = ext_management_system.autosde_client.StorageHostApi.storage_hosts_post(host_initiator_to_create).task_id

    options = {
      :target_class   => nil,
      :target_id      => nil,
      :ems_id         => ext_management_system.id,
      :native_task_id => task_id,
      :interval       => 10.seconds,
      :target_option  => "ems"
    }
    ext_management_system.class::EmsRefreshWorkflow.create_job(options).tap { |job| job.signal(:start) }
  end

  def raw_delete_host_initiator
    task_id = ext_management_system.autosde_client.StorageHostApi.storage_hosts_pk_delete(ems_ref).task_id
    options = {
      :target_class   => nil,
      :target_id      => nil,
      :ems_id         => ext_management_system.id,
      :native_task_id => task_id,
      :interval       => 1.minute,
      :target_option  => "ems"
    }
    ext_management_system.class::EmsRefreshWorkflow.create_job(options).tap { |job| job.signal(:start) }
  end
end
