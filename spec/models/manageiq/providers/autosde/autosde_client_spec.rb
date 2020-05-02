describe ManageIQ::Providers::Autosde::SdeManager::AutosdeClient do

  it "logs in with right credentials-1" do
    client = ManageIQ::Providers::Autosde::SdeManager::AutosdeClient.new(
        :host => RSpec.configuration.autosde_appliance_host)
    VCR.use_cassette("correct_login_spec") do
      expect(client.login).to be_truthy
    end
  end

  it "raises on login with wrong credentials" do
    client = ManageIQ::Providers::Autosde::SdeManager::AutosdeClient.new(
        'asfd', :host => RSpec.configuration.autosde_appliance_host)

    VCR.use_cassette("incorrect_login_spec") do
      expect { client.login }.to raise_error(
                                     Exception,
                                     ManageIQ::Providers::Autosde::PhysicalInfraManager::AutosdeClient::AUTH_ERRR_MSG)
    end
  end

  it "gets a list of storage systems" do

    client = ManageIQ::Providers::Autosde::SdeManager::AutosdeClient.new(
        :host => RSpec.configuration.autosde_appliance_host)

    temp = {}

    VCR.use_cassette('get_storage_systems_autosde_client_sde_manager') do
      temp[:systems] = client.class::StorageSystemApi.new.storage_systems_get
    end

    systems = temp[:systems]
    #expect(systems.first.to_hash).to eq RSpec.configuration.autosde_test_system
    expect(systems).to be_an_instance_of(Array)

  end

  it "does not fail when token is bad (ie expired) and re-login" do


    client = ManageIQ::Providers::Autosde::SdeManager::AutosdeClient.new(
        :host => RSpec.configuration.autosde_appliance_host)

    class << client
      attr_accessor :token
    end

    # set bad token
    client.token = "__bad-token__"

    temp = {}

    VCR.use_cassette("bad_token_get_storage_systems_with_relogin_not_fails") do
      temp[:systems] = client.class::StorageSystemApi.new.storage_systems_get
    end

    systems = temp[:systems]
    #expect(systems.first.to_hash).to eq RSpec.configuration.autosde_test_system
    expect(systems).to be_an_instance_of(Array)

  end
end
