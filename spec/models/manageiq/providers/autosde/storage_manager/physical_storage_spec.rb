require 'json'

describe ManageIQ::Providers::Autosde::StorageManager::PhysicalStorage do

  let(:ems) do
    FactoryBot.create(:autosde_storage_manager,
                      :with_autosde_credentials,
                      :hostname => Rails.application.secrets.autosde[:appliance_host])
  end

  let(:create_ph_storage_hash) do
    autosde_provider_json_path = File.join(ManageIQ::Providers::Autosde::Engine.root, 'spec', 'fixtures', 'json', 'physical_storage.json')
    autosde_provider_json_file = File.read(autosde_provider_json_path)
    JSON.parse(autosde_provider_json_file)
  end

  it "compare end2end create physical storage hash" do
    ui_classic_json_path = File.join(ManageIQ::UI::Classic::Engine.root, 'spec', 'javascripts', 'fixtures', 'json', 'physical_storage.json')
    ui_classic_json_file = File.read(ui_classic_json_path)
    ui_classic_create_ph_storage_hash = JSON.parse(ui_classic_json_file)

    expect(create_ph_storage_hash).to eq(ui_classic_create_ph_storage_hash)
  end

  it "create physical storage" do
    FactoryBot.create(:PhysicalStorageFamily, :name => "FlashSystems/SVC", :id => 123)

    VCR.use_cassette("create_physical_storage", :record => :once) do
      PhysicalStorage.create_physical_storage(ems.id, create_ph_storage_hash)
    end
  end
end
