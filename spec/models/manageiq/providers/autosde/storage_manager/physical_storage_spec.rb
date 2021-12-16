require 'json'

describe ManageIQ::Providers::Autosde::StorageManager::PhysicalStorage do

  let(:ems) do
    FactoryBot.create(:autosde_storage_manager,
                      :with_autosde_credentials,
                      :hostname => Rails.application.secrets.autosde[:appliance_host])
  end

  let(:create_ph_storage_hash) do
    {
      "name"                       => "svc-178",
      "password"                   => "<password>",
      "user"                       => "<user>",
      # "physical_storage_family_id" => PhysicalStorageFamily.first.id,
      "physical_storage_family_id" => 123,
      "management_ip"              => "9.151.159.178",
    }
  end

  it "compare end2end create physical storage hash" do
    end2end_json_path = Rails.root.join("spec", "fixtures", "end2end", "physical_storage.json").to_s
    end2end_json_file = File.read(end2end_json_path)
    end2end_create_ph_storage_hash = JSON.parse(end2end_json_file)

    expect(end2end_create_ph_storage_hash).to eq(create_ph_storage_hash)
  end

  it "create physical storage" do
    FactoryBot.create(:PhysicalStorageFamily, :name => "FlashSystems/SVC", :id => 123)

    VCR.use_cassette("create_physical_storage", :record => :once) do
      PhysicalStorage.create_physical_storage(ems.id, create_ph_storage_hash)
    end
  end
end
