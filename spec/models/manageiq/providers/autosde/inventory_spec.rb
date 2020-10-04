describe ManageIQ::Providers::Autosde::Inventory::Parser::StorageManager do
  it "gets inventory from the appliance" do
    ems = FactoryBot.create(:autosde_storage_manager, :with_autosde_credentials,
                            :hostname => RSpec.configuration.autosde_appliance_host_with_auth_token)

    VCR.use_cassette("ems_refresh") do
      EmsRefresh.refresh(ems)
    end

    # expected that refresh will bring all components
    # @type manager [ManageIQ::Providers::Autosde::StorageManager]
    manager = ManageIQ::Providers::Autosde::StorageManager.first
    expect(manager.physical_storages).to_not be_empty
    expect(manager.storage_resources).to_not be_empty
    expect(manager.storage_services).to_not be_empty
    expect(manager.physical_storage_families).to_not be_empty
    expect(manager.cloud_volumes).to_not be_empty
    expect(manager.cloud_volumes.first).to be_instance_of(ManageIQ::Providers::Autosde::StorageManager::CloudVolume)
  end
end
