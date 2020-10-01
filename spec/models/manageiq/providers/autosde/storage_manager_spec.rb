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
    # use special trait: with_autosde_credentials, to supply real credentials when first run
    ems = FactoryBot.create(:autosde_storage_manager, :with_autosde_credentials, :hostname => RSpec.configuration.autosde_appliance_host_with_auth_token)

    VCR.use_cassette("get_storage_systems_from_storage_manager") do
      systems = ems.autosde_client.StorageSystemApi.storage_systems_get
      expect(systems).to be_an_instance_of(Array)
      expect(systems.first.management_ip).to be_truthy
    end
  end
end
