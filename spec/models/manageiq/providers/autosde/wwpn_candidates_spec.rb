describe ManageIQ::Providers::Autosde::StorageManager do
  it "can get storage fc wwpn candidates -autosde gem v1" do
    VCR.use_cassette("get_storage_systems_wwpn_candidates_v1", :record => :once) do
      client = ManageIQ::Providers::Autosde::StorageManager::AutosdeClient.new(
        :host     => Rails.application.secrets.autosde[:appliance_host],
        :username => Rails.application.secrets.autosde[:site_manager_user],
        :password => Rails.application.secrets.autosde[:site_manager_password]
      )
      result = client.StorageHostWWPNCandidatesApi.storage_hosts_wwpn_candidates_get
      expect(result).to be_an_instance_of(Array)
      expect(result).not_to be_empty
      first_candidate = result.first
      expect(first_candidate).to be_respond_to(:wwpn)
      expect(first_candidate.wwpn.length).to be(16)
      expect(first_candidate).to be_respond_to(:system_uuid)
      expect(first_candidate.system_uuid).not_to be_empty
    end
    end

  it "can get storage fc wwpn candidates -autosde gem v2" do
    VCR.use_cassette("get_storage_systems_wwpn_candidates_v2", :record => :once) do
      client = ManageIQ::Providers::Autosde::StorageManager::AutosdeClient.new(
        :host     => Rails.application.secrets.autosde[:appliance_host],
        :username => Rails.application.secrets.autosde[:site_manager_user],
        :password => Rails.application.secrets.autosde[:site_manager_password]
      )
      result = client.StorageHostWWPNCandidatesApi.storage_hosts_wwpn_candidates_get
      expect(result).to be_an_instance_of(Array)
      expect(result).not_to be_empty
      first_candidate = result.first
      expect(first_candidate).to be_respond_to(:wwpn)
      expect(first_candidate.wwpn.length).to be(16)
      expect(first_candidate).to be_respond_to(:system_uuid)
      expect(first_candidate.system_uuid).not_to be_empty
    end
  end
end
