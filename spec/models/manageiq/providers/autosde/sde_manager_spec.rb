describe ManageIQ::Providers::Autosde::SdeManager do

  it 'type is autosde' do
    expect(described_class.ems_type).to eq('autosde')
  end

  it "has credentials and hostname" do
    ems = FactoryBot.create(:sde_autosde_manager, :with_authentication, :name => "kaka")
    expect(described_class.all[0].name).to eq 'kaka'
    expect(ManageIQ::Providers::SdeManager.all[0].authentication_userid).to eq "testuser"
  end

  it "has autosde client" do
    FactoryBot.create(:sde_autosde_manager, :with_authentication)
    expect(ManageIQ::Providers::SdeManager.all[0].autosde_client).to be_instance_of ManageIQ::Providers::Autosde::SdeManager::AutosdeClient
  end

  it "can get storage systems " do
    ems = FactoryBot.create(:sde_autosde_manager, :with_authentication)
    ems.default_endpoint.hostname = RSpec.configuration.autosde_appliance_host

    VCR.use_cassette("get_storages_systems_from_sde_manager-1") do
      systems = ems.autosde_client.class::StorageSystemApi.new.storage_systems_get
        # expect(ems.autosde_client.class::StorageSystemApi.new.storage_systems_get[0].to_hash).to eq RSpec.configuration.autosde_test_system
      expect(systems).to be_an_instance_of(Array)
    end
  end
end
