describe ManageIQ::Providers::Autosde::StorageManager::StorageService do
  let(:ems) do
    FactoryBot.create(
      :autosde_storage_manager,
      :with_autosde_credentials,
      :hostname     => credentials_autosde_host,
      :capabilities => {
        :cap1 => [{'uuid' => "111", 'value' => "True"}, {'uuid' => "222", 'value' => "False"}],
        :cap2 => [{'uuid' => "333", 'value' => "True"}, {'uuid' => "444", 'value' => "False"}],
      }
    )
  end

  let(:test_resource1) do
    FactoryBot.create(:storage_resource, :ext_management_system => ems, :ems_ref => "555")
  end

  let(:test_resource2) do
    FactoryBot.create(:storage_resource, :ext_management_system => ems, :ems_ref => "666")
  end

  let(:test_resource3) do
    FactoryBot.create(:storage_resource, :ext_management_system => ems, :ems_ref => "777")
  end

  before(:each) do
    @test_service = FactoryBot.create(
      :storage_service,
      :type                  => "ManageIQ::Providers::Autosde::StorageManager::StorageService",
      :ext_management_system => ems,
      :storage_resources     => [test_resource1, test_resource2],
      :capabilities          => {'cap1' => "True", 'cap2' => "False"}
    )
  end

  it "prepares update hash with no change to resources and capabilities" do
    options = {
      'name'                => 'no_change',
      'description'         => 'prepares update hash with no change to resources and capabilities',
      'storage_resource_id' => [{'value' => test_resource1.id}, {'value' => test_resource2.id}],
      'cap2'                => "444",
      'cap1'                => "111"
    }

    update_hash = @test_service.prepare_update_hash(options)
    expected = {
      :resources          => nil,
      :capability_id_list => nil
    }
    expect(update_hash).to include(expected)
  end

  it "prepares update hash with a change to resources and no change to capabilities" do
    options = {
      'name'                => 'no_change',
      'description'         => 'prepares update hash with no change to resources and capabilities',
      'storage_resource_id' => [{'value' => test_resource1.id}],
      'cap2'                => "444",
      'cap1'                => "111"
    }

    update_hash = @test_service.prepare_update_hash(options)
    expected = {
      :resources          => [test_resource1.ems_ref],
      :capability_id_list => nil
    }
    expect(update_hash).to include(expected)
  end

  it "prepares update hash with no change to resources a change to capabilities" do
    options = {
      'name'                => 'no_change',
      'description'         => 'prepares update hash with no change to resources and capabilities',
      'storage_resource_id' => [{'value' => test_resource1.id}, {'value' => test_resource2.id}],
      'cap1'                => "222",
      'cap2'                => "333",
    }

    update_hash = @test_service.prepare_update_hash(options)
    expected = {
      :resources          => nil,
      :capability_id_list => %w[222 333]
    }
    expect(update_hash).to include(expected)
  end

  it "prepares update hash with a change to both resources and capabilities" do
    options = {
      'name'                => 'no_change',
      'description'         => 'prepares update hash with no change to resources and capabilities',
      'storage_resource_id' => [{'value' => test_resource1.id}, {'value' => test_resource3.id}],
      'cap1'                => "111",
      'cap2'                => "333",
    }

    update_hash = @test_service.prepare_update_hash(options)
    expected = {
      :resources          => [test_resource1.ems_ref, test_resource3.ems_ref],
      :capability_id_list => %w[111 333]
    }
    expect(update_hash).to include(expected)
  end
end
