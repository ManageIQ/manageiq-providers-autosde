describe ManageIQ::Providers::Autosde::PhysicalInfraManager::AutosdeClient do
  it "logs in with right credentials " do
    client = ManageIQ::Providers::Autosde::PhysicalInfraManager::AutosdeClient.new(
        :host => RSpec.configuration.autosde_appliance_host)
    VCR.use_cassette("correct_login_spec") do
      expect(client.login).to be_truthy
    end
  end

  it "raises on login with wrong credentials" do
    client = ManageIQ::Providers::Autosde::PhysicalInfraManager::AutosdeClient.new(
        'asfd', :host => RSpec.configuration.autosde_appliance_host)
    VCR.use_cassette("incorrect_login_spec") do
      expect { client.login }.to raise_error(
                                     Exception,
                                     ManageIQ::Providers::Autosde::PhysicalInfraManager::AutosdeClient::AUTH_ERRR_MSG)
    end
  end

  it "gets a list of storage systems" do
    client = ManageIQ::Providers::Autosde::PhysicalInfraManager::AutosdeClient.new(
        :host => RSpec.configuration.autosde_appliance_host)
    temp = {}

    VCR.use_cassette("get_storage_systems") do
      temp[:systems] = client.storage_system_api.storage_systems_get
    end

    systems = temp[:systems]
    expect(systems.first.to_hash).to eq RSpec.configuration.autosde_test_system

  end

end
