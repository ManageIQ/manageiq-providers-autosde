describe ManageIQ::Providers::Autosde::StorageManager do

  it 'type is autosde' do
    expect(described_class.ems_type).to eq('autosde')
  end

  it "has credentials and hostname" do
    ems = FactoryBot.create(:autosde_storage_manager, :with_authentication, :name => "kaka")
    expect(described_class.all[0].name).to eq 'kaka'
    expect(ManageIQ::Providers::StorageManager.all[0].authentication_userid).to eq "testuser"
  end

  it "has autosde client" do
    FactoryBot.create(:autosde_storage_manager, :with_authentication)
    expect(ManageIQ::Providers::StorageManager.all[0].autosde_client).to be_instance_of ManageIQ::Providers::Autosde::StorageManager::AutosdeClient
  end

  it "can get storage systems " do
    ems = FactoryBot.create(:autosde_storage_manager, :with_authentication)
    ems.default_endpoint.hostname = RSpec.configuration.autosde_appliance_host

    VCR.use_cassette("get_storages_systems_from_sde_manager") do
      systems = ems.autosde_client.class::StorageSystemApi.new.storage_systems_get
      expect(systems).to be_an_instance_of(Array)
      expect(systems[0].to_hash).to eq RSpec.configuration.autosde_test_system
    end
  end
end
