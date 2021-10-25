describe ManageIQ::Providers::Autosde::Inventory::Parser::StorageManager do
  let(:ems) do
    FactoryBot.create(:autosde_storage_manager,
                      :with_autosde_credentials,
                      :hostname => Rails.application.secrets.autosde[:appliance_host])
  end

  let(:first_wwpn) { "2100000E1EE89D90" }
  let(:wwpn_ems_ref) { "a785c49a-2f3c-4e6d-8ace-879dfa1719a2" }

  it "gets inventory from the appliance" do
    VCR.use_cassette("ems_refresh") do
      EmsRefresh.refresh(ems)
      ems.reload
    end

    # expected that refresh will bring all components
    expect(ems.physical_storages).to_not(be_empty)
    expect(ems.physical_storage_families).to_not(be_empty)
    expect(ems.physical_storages.first.physical_storage_family).to(eq(ems.physical_storage_families.find_by(:name=>'FlashSystems/SVC')))

    expect(ems.storage_resources).to_not(be_empty)
    expect(ems.storage_resources.first.physical_storage).to(eq(ems.physical_storages.first))

    expect(ems.storage_services).to_not(be_empty)
    expect(ems.cloud_volumes).to_not(be_empty)

    expect(ems.cloud_volumes.first).to(be_instance_of(ManageIQ::Providers::Autosde::StorageManager::CloudVolume))

    # wwpn candidates
    expect(ems.wwpn_candidates.count).to(eq(2))
    first_candidate = ems.wwpn_candidates.find_by(:ems_ref => first_wwpn)
    expect(first_candidate).to(have_attributes(
                                 :candidate        => first_wwpn,
                                 :physical_storage => ems.physical_storages.find_by(:ems_ref => wwpn_ems_ref)
                               ))

    # mapping for host_initiator_group / cluster
    expect(ems.host_initiator_groups.count).to(eq(5))
    cluster_mapping = ems.volume_mappings.where.not(:host_initiator_group => nil).first
    host_initiator_group_ref = cluster_mapping.host_initiator_group.ems_ref
    host_initiator_group = ems.host_initiator_groups.find_by(:ems_ref => host_initiator_group_ref)
    expect(cluster_mapping.host_initiator_group).to have_attributes(
      :name => host_initiator_group.name
    )
    # mappings for host_initiator
    host_mapping = ems.volume_mappings.where.not(:host_initiator => nil).first
    host_mapping_ref = host_mapping.host_initiator.ems_ref
    host_initiator = ems.host_initiators.find_by(:ems_ref => host_mapping_ref)
    expect(host_mapping.host_initiator).to have_attributes(:name => host_initiator.name)
  end
end
