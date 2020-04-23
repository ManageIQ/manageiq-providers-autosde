describe ManageIQ::Providers::Autosde::PhysicalInfraManager do
  it 'type is autosde' do
    expect(described_class.ems_type).to eq('autosde')

  end

  it "has credentials and hostname" do
    ems = FactoryBot.create(:autosde_manager, :with_authentication, :name => "kaka")
    expect(ManageIQ::Providers::Autosde::PhysicalInfraManager.all[0].name).to eq 'kaka'
    expect(ManageIQ::Providers::PhysicalInfraManager.all[0].authentication_userid).to eq "testuser"
  end

  it "has autosde client" do
    ems = FactoryBot.create(:autosde_manager, :with_authentication)
    expect(ManageIQ::Providers::PhysicalInfraManager.all[0].autosde_client).to be_instance_of ManageIQ::Providers::Autosde::PhysicalInfraManager::AutosdeClient
  end

end
