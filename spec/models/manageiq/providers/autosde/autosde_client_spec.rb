describe ManageIQ::Providers::Autosde::StorageManager::AutosdeClient do
  AUTOSDE_APPLIANCE_HOST_WITH_AUTH_TOKEN = RSpec.configuration.autosde_appliance_host_with_auth_token
  AUTOSDE_SITE_MANAGER_USER = RSpec.configuration.autosde_site_manager_user
  AUTOSDE_SITE_MANAGER_PASSWORD = RSpec.configuration.autosde_site_manager_password

  it "logs in with right credentials" do
    client = ManageIQ::Providers::Autosde::StorageManager::AutosdeClient.new(
      :host     => AUTOSDE_APPLIANCE_HOST_WITH_AUTH_TOKEN,
      #:scheme => 'http',
      :username => AUTOSDE_SITE_MANAGER_USER,
      :password => AUTOSDE_SITE_MANAGER_PASSWORD
    )

    VCR.use_cassette("correct_login_spec") do
      client.login
      expect(client.token.size).to be > 10
    end
  end

  it "raises on login with wrong credentials" do
    client = ManageIQ::Providers::Autosde::StorageManager::AutosdeClient.new(
      :host     => AUTOSDE_APPLIANCE_HOST_WITH_AUTH_TOKEN,
      #:scheme => 'http',
      :username => 'wrong_user',
      :password => AUTOSDE_SITE_MANAGER_PASSWORD
    )

    VCR.use_cassette("incorrect_login_spec") do
      expect { client.login }.to raise_error(RuntimeError, /Authentication error/)
    end
  end

  it "gets a list of storage systems" do
    client = ManageIQ::Providers::Autosde::StorageManager::AutosdeClient.new(
      :host     => AUTOSDE_APPLIANCE_HOST_WITH_AUTH_TOKEN,
      # :scheme => 'http',
      :username => AUTOSDE_SITE_MANAGER_USER,
      :password => AUTOSDE_SITE_MANAGER_PASSWORD
    )

    temp = {}

    VCR.use_cassette('get_storage_systems_autosde_client') do
      temp[:systems] = client.StorageSystemApi.storage_systems_get
    end

    systems = temp[:systems]
    expect(systems).to be_an_instance_of(Array)
  end

  it "does not fail when token is bad (ie expired) and re-login" do
    client = ManageIQ::Providers::Autosde::StorageManager::AutosdeClient.new(
      :host     => AUTOSDE_APPLIANCE_HOST_WITH_AUTH_TOKEN,
      #:scheme => 'http',
      :username => AUTOSDE_SITE_MANAGER_USER,
      :password => AUTOSDE_SITE_MANAGER_PASSWORD
    )

    temp = {}

    VCR.use_cassette("bad_token_get_storage_systems_with_relogin_not_fails") do
      # set bad token
      client.token = "__bad-token__"
      temp[:systems] = client.StorageSystemApi.storage_systems_get
    end

    systems = temp[:systems]
    expect(systems).to be_an_instance_of(Array)
  end

  it "proves clients stuffs  are different" do
    client1 = ManageIQ::Providers::Autosde::StorageManager::AutosdeClient.new(
      :host     => AUTOSDE_APPLIANCE_HOST_WITH_AUTH_TOKEN,
      :username => AUTOSDE_SITE_MANAGER_USER,
      :password => AUTOSDE_SITE_MANAGER_PASSWORD
    )

    client2 = ManageIQ::Providers::Autosde::StorageManager::AutosdeClient.new(
      :host     => AUTOSDE_APPLIANCE_HOST_WITH_AUTH_TOKEN,
      :username => AUTOSDE_SITE_MANAGER_USER,
      :password => AUTOSDE_SITE_MANAGER_PASSWORD
    )

    expect(client1.object_id).not_to eq(client2.object_id)
    expect(client1.StorageSystemApi.object_id).not_to eq(client2.StorageSystemApi.object_id)
    expect(client1.config.object_id).not_to eq(client2.config.object_id)
  end
  it "works with object with arguments" do
    client = ManageIQ::Providers::Autosde::StorageManager::AutosdeClient.new(
      :host     => AUTOSDE_APPLIANCE_HOST_WITH_AUTH_TOKEN,
      :username => AUTOSDE_SITE_MANAGER_USER,
      :password => AUTOSDE_SITE_MANAGER_PASSWORD
    )

    vol_to_create = client.VolumeCreate(:service => 's1', :name => 'vol_name', :size => 10)
    expect(vol_to_create).to be_instance_of(OpenapiClient::VolumeCreate)
  end
end
