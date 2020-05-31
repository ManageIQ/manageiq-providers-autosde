describe ManageIQ::Providers::Autosde::Inventory::Parser::StorageManager do
  it "gets inventroy from the appliance" do
    ems = FactoryBot.create(:autosde_storage_manager, :with_authentication, :name => "kaka")
    ems.default_endpoint.hostname = RSpec.configuration.autosde_appliance_host
    VCR.use_cassette("ems_refresh") do
      EmsRefresh.refresh(ems)
    end

    expected_system_hash = RSpec.configuration.autosde_test_system
    expect(ManageIQ::Providers::Autosde::StorageManager.first.physical_storages.first.name).to eq expected_system_hash[:name]
    expect(ManageIQ::Providers::Autosde::StorageManager.first.physical_storages.first.uid_ems).to eq expected_system_hash[:uuid]
  end
end
