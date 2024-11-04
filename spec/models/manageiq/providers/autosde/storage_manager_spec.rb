describe ManageIQ::Providers::Autosde::StorageManager do

  it 'type is autosde' do
    expect(described_class.ems_type).to(eq('autosde'))
  end

  it "has credentials and hostname" do
    ems = FactoryBot.create(:autosde_storage_manager, :with_authentication, :name => "kaka")
    expect(described_class.all[0].name).to(eq('kaka'))
    expect(ManageIQ::Providers::StorageManager.all[0].authentication_userid).to(eq("testuser"))
  end

  it "has autosde client" do
    FactoryBot.create(:autosde_storage_manager, :with_authentication)
    expect(ManageIQ::Providers::StorageManager.all[0].autosde_client).to(be_instance_of(ManageIQ::Providers::Autosde::StorageManager::AutosdeClient))
  end

  it "can get storage systems -autosde gem v1" do
    # use special trait: with_autosde_credentials, to supply real credentials when first run
    ems = FactoryBot.create(:autosde_storage_manager, :with_autosde_credentials, :hostname => credentials_autosde_host)

    VCR.use_cassette("get_storage_systems_from_storage_manager_v1") do
      systems = ems.autosde_client.StorageSystemApi.storage_systems_get
      expect(systems).to(be_an_instance_of(Array))
      expect(systems.first.management_ip).to(be_truthy)
    end
  end

  it "can get storage systems -autosde gem v2" do
    # use special trait: with_autosde_credentials, to supply real credentials when first run
    ems = FactoryBot.create(:autosde_storage_manager, :with_autosde_credentials, :hostname => credentials_autosde_host)

    VCR.use_cassette("get_storage_systems_from_storage_manager_v2", :record => :once) do
      systems = ems.autosde_client.StorageSystemApi.storage_systems_get
      expect(systems).to(be_an_instance_of(Array))
      expect(systems.first.management_ip).to(be_truthy)
    end
  end


  context "#pause!" do
    let(:zone) { FactoryBot.create(:zone) }
    let(:ems)  { FactoryBot.create(:autosde_storage_manager, :zone => zone) }

    include_examples "ExtManagementSystem#pause!"
  end

  context "#resume!" do
    let(:zone) { FactoryBot.create(:zone) }
    let(:ems)  { FactoryBot.create(:autosde_storage_manager, :zone => zone) }

    include_examples "ExtManagementSystem#resume!"
  end
end
