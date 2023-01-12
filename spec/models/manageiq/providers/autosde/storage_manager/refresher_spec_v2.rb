describe ManageIQ::Providers::Autosde::StorageManager::Refresher do
  include Spec::Support::EmsRefreshHelper

  let(:ems) do
    FactoryBot.create(:autosde_storage_manager,
                      :with_autosde_credentials,
                      :hostname => Rails.application.secrets.autosde[:appliance_host])
  end

  describe "#refresh - autosde gem v2" do
    context "full refresh" do
      it "Performs a full refresh" do
        2.times do
          VCR.use_cassette("ems_refresh_v2", :record => :once) { described_class.refresh([ems]) }

          ems.reload

          assert_ems
          assert_specific_physical_storage
          assert_specific_physical_storage_family
          assert_specific_storage_resource
          assert_specific_storage_service
          assert_specific_cloud_volume
          assert_specific_wwpn_candidate
          assert_specific_host_initiator
          assert_specific_host_initiator_group
          assert_specific_host_volume_mapping
          assert_specific_cluster_volume_mapping
        end
      end
    end

    context "targeted refresh" do
      before { VCR.use_cassette("ems_refresh_v2") { described_class.refresh([ems]) } }

      let(:system_type_api)    { double("SystemTypeApi") }
      let(:storage_system_api) { double("StorageSystemApi") }
      let(:volume_api)         { double("VolumeApi") }

      it "with no targets" do
        assert_inventory_not_changed { run_targeted_refresh }
      end

      it "with a PhysicalStorage object target" do
        expect(storage_system_api)
          .to(receive(:storage_systems_get)
          .and_return(
            [
              AutosdeOpenapiClient::StorageSystem.new(
                :component_state => "PENDING_CREATION",
                :management_ip   => "129.39.244.30",
                :name            => "Barmetall9_SVC",
                :status          => "ONLINE",
                :storage_family  => "ontap_7mode",
                :system_type     => AutosdeOpenapiClient::SystemType.new(
                  :component_state => "PENDING_CREATION",
                  :name            => "IBM_FlashSystems",
                  :short_version   => "11",
                  :uuid            => "397352fb-f6a0-4a5d-90f8-6addf4c81076",
                  :version         => "1.1"
                ),
                :uuid            => "78ef7ca4-2ce9-4983-aa49-76dbeedcbedf"
              )
            ]
          ))
        assert_inventory_not_changed { run_targeted_refresh(ems.physical_storages.find_by(:ems_ref => "78ef7ca4-2ce9-4983-aa49-76dbeedcbedf")) }
      end

      it "with a new physical storage" do
        expect(storage_system_api)
          .to(receive(:storage_systems_get)
          .and_return(
            [
              AutosdeOpenapiClient::StorageSystem.new(
                :component_state => "PENDING_CREATION",
                :management_ip   => "129.39.244.30",
                :name            => "129.39.244.30",
                :status          => "ONLINE",
                :storage_family  => "ontap_7mode",
                :system_type     => AutosdeOpenapiClient::SystemType.new(
                  :component_state => "PENDING_CREATION",
                  :name            => "IBM_FlashSystems",
                  :short_version   => "11",
                  :uuid            => "053446df-ed2b-4822-b9c5-386e85198519",
                  :version         => "1.1"
                ),
                :uuid            => "3923aeca-0b22-4f5b-a15f-9c844bc9abcb"
              )
            ]
          ))

        run_targeted_refresh(InventoryRefresh::Target.new(:manager => ems, :association => :physical_storages, :manager_ref => {:ems_ref => "3923aeca-0b22-4f5b-a15f-9c844bc9abcb"}))

        ems.reload

        expect(ems.physical_storages.count).to(eq(2))
        expect(ems.physical_storages.find_by(:ems_ref => "78ef7ca4-2ce9-4983-aa49-76dbeedcbedf")).to(have_attributes(
                                                                                                       :ems_ref                 => "78ef7ca4-2ce9-4983-aa49-76dbeedcbedf",
                                                                                                       :uid_ems                 => nil,
                                                                                                       :name                    => "Barmetall9_SVC",
                                                                                                       :type                    => "ManageIQ::Providers::Autosde::StorageManager::PhysicalStorage",
                                                                                                       :health_state            => "ONLINE",
                                                                                                       :physical_storage_family => ems.physical_storage_families.find_by(:name => "IBM_FlashSystems")
                                                                                                     ))
      end

      it "deleting a physical storage" do
        expect(storage_system_api).to(receive(:storage_systems_get).and_return([]))

        run_targeted_refresh(InventoryRefresh::Target.new(:manager => ems, :association => :physical_storages, :manager_ref => {:ems_ref => "78ef7ca4-2ce9-4983-aa49-76dbeedcbedf"}))

        ems.reload

        expect(ems.physical_storages.count).to(eq(0))
      end

      it "with a CloudVolume object target" do
        expect(volume_api)
          .to(receive(:volumes_get)
          .and_return(
            [
              AutosdeOpenapiClient::VolumeResponse.new(
                :compliant          => true,
                :component_state    => "CREATED",
                :historical_service => nil,
                :name               => "dup_volume_10",
                :service            => "d7cd0d98-1467-4384-a24d-c0d003ea1701",
                :size               => 1,
                :status             => "online",
                :storage_resource   => "0be07c17-9775-422a-a03c-8fa158c5f297",
                :uuid               => "77b2dcdf-5d74-4094-8b61-624701740562"
              )
            ]
          ))
        assert_inventory_not_changed { run_targeted_refresh(ems.cloud_volumes.find_by(:ems_ref => "77b2dcdf-5d74-4094-8b61-624701740562")) }
      end

      it "with a new cloud volume" do
        expect(volume_api)
          .to(receive(:volumes_get)
          .and_return(
            [
              AutosdeOpenapiClient::VolumeResponse.new(
                :compliant          => true,
                :component_state    => "PENDING_CREATION",
                :historical_service => nil,
                :name               => "new-volume",
                :service            => "774c1fd8-43e6-4bb2-8466-d5d1c1d992d6",
                :size               => 10,
                :status             => "online",
                :storage_resource   => "0a10636f-c204-4ae1-a370-f0ee850b80af",
                :uuid               => "6a02fc1f-04f4-476d-a5ac-6bcf042809e8"
              )
            ]
          ))

        run_targeted_refresh(InventoryRefresh::Target.new(:manager => ems, :association => :cloud_volumes, :manager_ref => {:ems_ref => "6a02fc1f-04f4-476d-a5ac-6bcf042809e8"}))

        ems.reload

        expect(ems.cloud_volumes.count).to(eq(29))
        expect(ems.cloud_volumes.find_by(:ems_ref => "6a02fc1f-04f4-476d-a5ac-6bcf042809e8")).to(have_attributes(
                                                                                                   :type             => "ManageIQ::Providers::Autosde::StorageManager::CloudVolume",
                                                                                                   :ems_ref          => "6a02fc1f-04f4-476d-a5ac-6bcf042809e8",
                                                                                                   :size             => 10.gigabyte,
                                                                                                   :name             => "new-volume",
                                                                                                   :status           => "PENDING_CREATION",
                                                                                                   :description      => nil,
                                                                                                   :volume_type      => "ISCSI/FC",
                                                                                                   :bootable         => false,
                                                                                                   :health_state     => "online",
                                                                                                   :storage_resource => ems.storage_resources.find_by(:ems_ref => "0a10636f-c204-4ae1-a370-f0ee850b80af"),
                                                                                                   :storage_service  => ems.storage_services.find_by(:ems_ref => "774c1fd8-43e6-4bb2-8466-d5d1c1d992d6")
                                                                                                 ))
      end

      it "deleting a cloud volume" do
        expect(volume_api).to(receive(:volumes_get).and_return([]))

        cloud_volume = ems.cloud_volumes.find_by(:ems_ref => "c82a379e-6697-461b-b605-340d2c3075ed")
        run_targeted_refresh(InventoryRefresh::Target.new(:manager => ems, :association => :cloud_volumes, :manager_ref => {:ems_ref => cloud_volume.ems_ref}))

        ems.reload

        expect(ems.cloud_volumes.count).to(eq(27))
      end

      def run_targeted_refresh(targets = [])
        target = InventoryRefresh::TargetCollection.new(:manager => ems, :targets => Array(targets))

        persister = ManageIQ::Providers::Autosde::Inventory::Persister::TargetCollection.new(ems, target)
        collector = ManageIQ::Providers::Autosde::Inventory::Collector::TargetCollection.new(ems, target)
        parser    = ManageIQ::Providers::Autosde::Inventory::Parser::StorageManager.new

        # Allow for tests to mock API calls
        autosde_client_stub = double("AutosdeClient")
        allow(autosde_client_stub).to(receive(:SystemTypeApi).and_return(system_type_api))
        allow(autosde_client_stub).to(receive(:StorageSystemApi).and_return(storage_system_api))
        allow(autosde_client_stub).to(receive(:VolumeApi).and_return(volume_api))

        allow(ems).to(receive(:autosde_client).and_return(autosde_client_stub))

        parser.collector = collector
        parser.persister = persister
        parser.parse

        InventoryRefresh::SaveInventory.save_inventory(ems, persister.inventory_collections)
      end
    end

    def assert_ems
      expect(ems.physical_storages.count).to(eq(1))
      expect(ems.physical_storage_families.count).to(eq(1))
      expect(ems.storage_resources.count).to(eq(8))
      expect(ems.storage_services.count).to(eq(9))
      expect(ems.cloud_volumes.count).to(eq(28))
      expect(ems.wwpn_candidates.count).to(eq(1))
      expect(ems.host_initiators.count).to(eq(7))
      expect(ems.host_initiator_groups.count).to(eq(2))
      expect(ems.volume_mappings.count).to(eq(3))
      expect(ems.cluster_volume_mappings.count).to(eq(1))
      expect(ems.host_volume_mappings.count).to(eq(2))
    end

    def assert_specific_physical_storage
      physical_storage = ems.physical_storages.find_by(:ems_ref => "78ef7ca4-2ce9-4983-aa49-76dbeedcbedf")
      expect(physical_storage).to(have_attributes(
                                    :ems_ref                 => "78ef7ca4-2ce9-4983-aa49-76dbeedcbedf",
                                    :name                    => "Barmetall9_SVC",
                                    :type                    => "ManageIQ::Providers::Autosde::StorageManager::PhysicalStorage",
                                    :access_state            => nil,
                                    :health_state            => "ONLINE",
                                    :overall_health_state    => nil,
                                    :drive_bays              => nil,
                                    :enclosures              => nil,
                                    :canister_slots          => nil,
                                    :physical_chassis_id     => nil,
                                    :total_space             => nil,
                                    :physical_storage_family => ems.physical_storage_families.find_by(:name => "IBM_FlashSystems")
                                  ))
    end

    def assert_specific_physical_storage_family
      flash_systems = ems.physical_storage_families.find_by(:name => "IBM_FlashSystems")
      require 'byebug'
      byebug
      expect(flash_systems).to(have_attributes(
                                 :name    => "IBM_FlashSystems",
                                 :version => "1.1",
                                 :ems_ref => "397352fb-f6a0-4a5d-90f8-6addf4c81076",
                                 :capabilities => "[{\"abstract_capability__name\": \"compression\", \"uuid\": \"65bf355d-3931-40b2-b67a-d4291fc5860b\", \"value\": \"True\"}, {\"abstract_capability__name\": \"compression\", \"uuid\": \"84d102cc-c98f-4bc0-9348-430ba04e90e4\", \"value\": \"False\"}, {\"abstract_capability__name\": \"thin_provision\", \"uuid\": \"92865732-1175-47ef-8b41-b77356784b63\", \"value\": \"True\"}, {\"abstract_capability__name\": \"thin_provision\", \"uuid\": \"a8a2bd22-bda9-4ad7-ba6f-11c8b4ee739c\", \"value\": \"False\"}]"
                               ))
    end

    def assert_specific_storage_resource
      storage_resource = ems.storage_resources.find_by(:ems_ref => "2423882a-c95b-4416-ac45-d379802eb451")
      expect(storage_resource).to(have_attributes(
                                    :name             => "Barmetall9_SVC:Pool3",
                                    :ems_ref          => "2423882a-c95b-4416-ac45-d379802eb451",
                                    :logical_free     => 515_396_075_520,
                                    :logical_total    => 515_396_075_520,
                                    :physical_storage => ems.physical_storages.find_by(:ems_ref => "78ef7ca4-2ce9-4983-aa49-76dbeedcbedf"),
                                    :type             => "ManageIQ::Providers::Autosde::StorageManager::StorageResource"
                                  ))
    end

    def assert_specific_storage_service
      storage_service = ems.storage_services.find_by(:ems_ref => "2d6f8233-b7ff-4c8c-aa43-ea9c9e2f7142")
      expect(storage_service).to(have_attributes(
                                   :name        => "TEST_SERVICE-129.39.244.172-1120",
                                   :description => "test service",
                                   :ems_ref     => "2d6f8233-b7ff-4c8c-aa43-ea9c9e2f7142",
                                   :uid_ems     => nil,
                                   :type        => "ManageIQ::Providers::Autosde::StorageManager::StorageService"
                                 ))
    end

    def assert_specific_cloud_volume
      cloud_volume = ems.cloud_volumes.find_by(:ems_ref => "c82a379e-6697-461b-b605-340d2c3075ed")
      expect(cloud_volume).to(have_attributes(
                                :type             => "ManageIQ::Providers::Autosde::StorageManager::CloudVolume",
                                :ems_ref          => "c82a379e-6697-461b-b605-340d2c3075ed",
                                :size             => 1_073_741_824,
                                :name             => "tony_test_4",
                                :status           => "CREATED",
                                :description      => nil,
                                :volume_type      => "ISCSI/FC",
                                :bootable         => false,
                                :health_state     => "online",
                                :storage_resource => ems.storage_resources.find_by(:ems_ref => "0be07c17-9775-422a-a03c-8fa158c5f297"),
                                :storage_service  => ems.storage_services.find_by(:ems_ref => "d7cd0d98-1467-4384-a24d-c0d003ea1701")
                              ))
      expect(cloud_volume.host_initiators.count).to(eq(0))
      expect(cloud_volume.host_initiators.pluck(:ems_ref)).to(match_array(%w[]))
    end

    def assert_specific_wwpn_candidate
      wwpn_candidate = ems.wwpn_candidates.find_by(:ems_ref => "5001738063CC0193")
      expect(wwpn_candidate).to(have_attributes(
                                  :candidate        => "5001738063CC0193",
                                  :ems_ref          => "5001738063CC0193",
                                  :physical_storage => ems.physical_storages.find_by(:ems_ref => "78ef7ca4-2ce9-4983-aa49-76dbeedcbedf")
                                ))
    end

    def assert_specific_host_initiator
      host_initiator = ems.host_initiators.find_by(:ems_ref => "b7f4b12e-17b7-41bf-b7d0-2c7444599b15")
      expect(host_initiator).to(have_attributes(
                                  :name                 => "TEST_HOST-172.29.0.5-2856",
                                  :ems_ref              => "b7f4b12e-17b7-41bf-b7d0-2c7444599b15",
                                  :uid_ems              => nil,
                                  :physical_storage     => ems.physical_storages.find_by(:ems_ref => "78ef7ca4-2ce9-4983-aa49-76dbeedcbedf"),
                                  :type                 => "ManageIQ::Providers::Autosde::StorageManager::HostInitiator",
                                  :status               => "offline",
                                  :host_cluster_name    => "",
                                  :host_initiator_group => nil
                                ))
    end

    def assert_specific_host_initiator_group
      host_initiator_group = ems.host_initiator_groups.find_by(:ems_ref => "0ef132ee-ae4c-4c2b-ae07-f52e1b99f7cc")
      expect(host_initiator_group).to(have_attributes(
                                        :name             => "test_host",
                                        :status           => nil,
                                        :ems_ref          => "0ef132ee-ae4c-4c2b-ae07-f52e1b99f7cc",
                                        :uid_ems          => nil,
                                        :type             => "ManageIQ::Providers::Autosde::StorageManager::HostInitiatorGroup",
                                        :physical_storage => ems.physical_storages.find_by(:ems_ref => "78ef7ca4-2ce9-4983-aa49-76dbeedcbedf")
                                      ))
    end

    def assert_specific_host_volume_mapping
      host_volume_mapping = ems.host_volume_mappings.find_by(:ems_ref => "bff501aa-1eb5-49a4-ba8c-6d1a4b570d14")
      expect(host_volume_mapping).to(have_attributes(
                                       :ems_ref              => "bff501aa-1eb5-49a4-ba8c-6d1a4b570d14",
                                       :uid_ems              => nil,
                                       :lun                  => 0,
                                       :type                 => "ManageIQ::Providers::Autosde::StorageManager::HostVolumeMapping",
                                       :cloud_volume         => ems.cloud_volumes.find_by(:ems_ref => "b419d4d3-d1b2-44c7-b6af-a39642fa4039"),
                                       :host_initiator       => ems.host_initiators.find_by(:ems_ref => "d253ffd7-b6ae-4a0e-9f18-8df1707bee83"),
                                       :host_initiator_group => nil
                                     ))
    end

    def assert_specific_cluster_volume_mapping
      cluster_volume_mapping = ems.cluster_volume_mappings.first
      expect(cluster_volume_mapping).to(have_attributes(
                                          :ems_ref              => "b25fd48e-bbc6-4b0b-b48c-75a915356bf3",
                                          :uid_ems              => nil,
                                          :lun                  => 1,
                                          :type                 => "ManageIQ::Providers::Autosde::StorageManager::ClusterVolumeMapping",
                                          :host_initiator       => nil,
                                          :host_initiator_group => ems.host_initiator_groups.find_by(:ems_ref => "0ef132ee-ae4c-4c2b-ae07-f52e1b99f7cc")
                                        ))
    end
  end
end
