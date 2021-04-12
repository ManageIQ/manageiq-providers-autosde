describe ManageIQ::Providers::Autosde::Inventory::Parser::StorageManager do
  let(:ems) do
    FactoryBot.create(:autosde_storage_manager,
                      :with_autosde_credentials,
                      :hostname => Rails.application.secrets.autosde[:appliance_host_with_auth_token])
  end

  it "gets inventory from the appliance" do
    VCR.use_cassette("ems_refresh") do
      EmsRefresh.refresh(ems)
      ems.reload
    end

    # expected that refresh will bring all components
    expect(ems.physical_storages).to_not be_empty
    expect(ems.physical_storage_families).to_not be_empty
    expect(ems.physical_storages.first.physical_storage_family).to eq(ems.physical_storage_families.find_by(:name=>'svc'))

    expect(ems.storage_resources).to_not be_empty
    expect(ems.storage_resources.first.physical_storage).to eq(ems.physical_storages.first)

    expect(ems.storage_services).to_not be_empty
    expect(ems.cloud_volumes).to_not be_empty

    expect(ems.cloud_volumes.first).to be_instance_of(ManageIQ::Providers::Autosde::StorageManager::CloudVolume)
  end
end
