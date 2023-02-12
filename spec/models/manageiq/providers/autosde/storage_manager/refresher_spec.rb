describe ManageIQ::Providers::Autosde::StorageManager::Refresher do
  include Spec::Support::EmsRefreshHelper

  let(:ems) do
    FactoryBot.create(:autosde_storage_manager,
                      :with_autosde_credentials,
                      :hostname => Rails.application.secrets.autosde[:appliance_host])
  end

  describe "#refresh" do
    context "full refresh" do
      it "Performs a full refresh" do
        2.times do
          VCR.use_cassette("ems_refresh_v1") { described_class.refresh([ems]) }

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
          assert_specific_storage_service_resource_attachment
        end
      end
    end

    context "targeted refresh" do
      before { VCR.use_cassette("ems_refresh_v1") { described_class.refresh([ems]) } }

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
                :management_ip   => "9.151.159.178",
                :name            => "9.151.159.178",
                :status          => "ONLINE",
                :storage_family  => "ontap_7mode",
                :system_type     => AutosdeOpenapiClient::SystemType.new(
                  :component_state => "PENDING_CREATION",
                  :name            => "IBM_FlashSystems",
                  :short_version   => "11",
                  :uuid            => "053446df-ed2b-4822-b9c5-386e85198519",
                  :version         => "1.2"
                ),
                :uuid            => "980f3ceb-c599-49c4-9db3-fdc793cb8666"
              )
            ]
          ))

        assert_inventory_not_changed { run_targeted_refresh(ems.physical_storages.find_by(:ems_ref => "980f3ceb-c599-49c4-9db3-fdc793cb8666")) }
      end

      it "with a new physical storage" do
        expect(storage_system_api)
          .to(receive(:storage_systems_get)
          .and_return(
            [
              AutosdeOpenapiClient::StorageSystem.new(
                :component_state => "PENDING_CREATION",
                :management_ip   => "1.2.3.4",
                :name            => "1.2.3.4",
                :status          => "ONLINE",
                :storage_family  => "ontap_7mode",
                :system_type     => AutosdeOpenapiClient::SystemType.new(
                  :component_state => "PENDING_CREATION",
                  :name            => "IBM_FlashSystems",
                  :short_version   => "11",
                  :uuid            => "053446df-ed2b-4822-b9c5-386e85198519",
                  :version         => "1.2"
                ),
                :uuid            => "3923aeca-0b22-4f5b-a15f-9c844bc9abcb"
              )
            ]
          ))

        run_targeted_refresh(InventoryRefresh::Target.new(:manager => ems, :association => :physical_storages, :manager_ref => {:ems_ref => "3923aeca-0b22-4f5b-a15f-9c844bc9abcb"}))

        ems.reload

        expect(ems.physical_storages.count).to(eq(2))
        expect(ems.physical_storages.find_by(:ems_ref => "3923aeca-0b22-4f5b-a15f-9c844bc9abcb")).to(have_attributes(
                                                                                                       :ems_ref                 => "3923aeca-0b22-4f5b-a15f-9c844bc9abcb",
                                                                                                       :uid_ems                 => nil,
                                                                                                       :name                    => "1.2.3.4",
                                                                                                       :type                    => "ManageIQ::Providers::Autosde::StorageManager::PhysicalStorage",
                                                                                                       :health_state            => "ONLINE",
                                                                                                       :physical_storage_family => ems.physical_storage_families.find_by(:name => "IBM_FlashSystems")
                                                                                                     ))
      end

      it "deleting a physical storage" do
        expect(storage_system_api).to(receive(:storage_systems_get).and_return([]))

        run_targeted_refresh(InventoryRefresh::Target.new(:manager => ems, :association => :physical_storages, :manager_ref => {:ems_ref => "980f3ceb-c599-49c4-9db3-fdc793cb8666"}))

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
                :component_state    => "PENDING_DELETION",
                :historical_service => nil,
                :volume_name        => "bk-vol0-edit",
                :service            => "774c1fd8-43e6-4bb2-8466-d5d1c1d992d6",
                :size               => 10,
                :status             => "online",
                :storage_resource   => "0a10636f-c204-4ae1-a370-f0ee850b80af",
                :uuid               => "ac287c2d-1776-48a3-a5c9-06327f4a57c4"
              )
            ]
          ))

        assert_inventory_not_changed { run_targeted_refresh(ems.cloud_volumes.find_by(:ems_ref => "ac287c2d-1776-48a3-a5c9-06327f4a57c4")) }
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
                :volume_name        => "new-volume",
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

        expect(ems.cloud_volumes.count).to(eq(14))
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

        cloud_volume = ems.cloud_volumes.find_by(:ems_ref => "ac287c2d-1776-48a3-a5c9-06327f4a57c4")
        run_targeted_refresh(InventoryRefresh::Target.new(:manager => ems, :association => :cloud_volumes, :manager_ref => {:ems_ref => cloud_volume.ems_ref}))

        ems.reload

        expect(ems.cloud_volumes.count).to(eq(12))
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
      expect(ems.physical_storage_families.count).to(eq(2))
      expect(ems.storage_resources.count).to(eq(9))
      expect(ems.storage_services.count).to(eq(7))
      expect(ems.cloud_volumes.count).to(eq(13))
      expect(ems.wwpn_candidates.count).to(eq(2))
      expect(ems.host_initiators.count).to(eq(12))
      expect(ems.host_initiator_groups.count).to(eq(5))
      expect(ems.volume_mappings.count).to(eq(8))
      expect(ems.cluster_volume_mappings.count).to(eq(1))
      expect(ems.host_volume_mappings.count).to(eq(7))
      expect(ems.storage_service_resource_attachments.count).to(eq(9))
    end

    def assert_specific_physical_storage
      physical_storage = ems.physical_storages.find_by(:ems_ref => "980f3ceb-c599-49c4-9db3-fdc793cb8666")
      expect(physical_storage).to(have_attributes(
                                    :ems_ref                 => "980f3ceb-c599-49c4-9db3-fdc793cb8666",
                                    :name                    => "9.151.159.178",
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
      expect(flash_systems).to(have_attributes(
                                 :name         => "IBM_FlashSystems",
                                 :version      => "1.2",
                                 :ems_ref      => "053446df-ed2b-4822-b9c5-386e85198519",
                                 :capabilities => {"compression"=>["True", "False"], "thin_provision"=>["True", "False"]}
                               ))
    end

    def assert_specific_storage_resource
      storage_resource = ems.storage_resources.find_by(:ems_ref => "41e4e6fb-d670-4db9-8325-464c138dee6f")
      expect(storage_resource).to(have_attributes(
                                    :name             => "test_or_30:test_pool",
                                    :ems_ref          => "41e4e6fb-d670-4db9-8325-464c138dee6f",
                                    :logical_free     => 472_446_402_560,
                                    :logical_total    => 515_396_075_520,
                                    :physical_storage => ems.physical_storages.find_by(:ems_ref => "9b1cedc0-b476-47f1-8f25-7a7da2b7d91c"),
                                    :type             => "ManageIQ::Providers::Autosde::StorageManager::StorageResource",
                                    :capabilities     => {"compression"=>["True"], "thin_provision"=>["True"]}
                                  ))
    end

    def assert_specific_storage_service
      storage_service = ems.storage_services.find_by(:ems_ref => "774c1fd8-43e6-4bb2-8466-d5d1c1d992d6")
      expect(storage_service).to(have_attributes(
                                   :name        => "9.151.159.178:borisko_test_pool",
                                   :description => "auto_created_service",
                                   :ems_ref     => "774c1fd8-43e6-4bb2-8466-d5d1c1d992d6",
                                   :uid_ems     => nil,
                                   :type        => "ManageIQ::Providers::Autosde::StorageManager::StorageService"
                                 ))
    end

    def assert_specific_cloud_volume
      cloud_volume = ems.cloud_volumes.find_by(:ems_ref => "ac287c2d-1776-48a3-a5c9-06327f4a57c4")
      expect(cloud_volume).to(have_attributes(
                                :type             => "ManageIQ::Providers::Autosde::StorageManager::CloudVolume",
                                :ems_ref          => "ac287c2d-1776-48a3-a5c9-06327f4a57c4",
                                :size             => 10.gigabyte,
                                :name             => "bk-vol0-edit",
                                :status           => "PENDING_DELETION",
                                :description      => nil,
                                :volume_type      => "ISCSI/FC",
                                :bootable         => false,
                                :health_state     => "online",
                                :storage_resource => ems.storage_resources.find_by(:ems_ref => "0a10636f-c204-4ae1-a370-f0ee850b80af"),
                                :storage_service  => ems.storage_services.find_by(:ems_ref => "774c1fd8-43e6-4bb2-8466-d5d1c1d992d6")
                              ))
      expect(cloud_volume.host_initiators.count).to(eq(2))
      expect(cloud_volume.host_initiators.pluck(:ems_ref)).to(match_array(%w[f80e97cf-97fc-4a40-9ec8-1f37454654fc 0a460ad9-e6e7-486a-a34e-7a5d946c9d00]))
    end

    def assert_specific_wwpn_candidate
      wwpn_candidate = ems.wwpn_candidates.find_by(:ems_ref => "2100000E1EE89D90")
      expect(wwpn_candidate).to(have_attributes(
                                  :candidate        => "2100000E1EE89D90",
                                  :ems_ref          => "2100000E1EE89D90",
                                  :physical_storage => nil
                                ))
    end

    def assert_specific_host_initiator
      host_initiator = ems.host_initiators.find_by(:ems_ref => "f80e97cf-97fc-4a40-9ec8-1f37454654fc")
      expect(host_initiator).to(have_attributes(
                                  :name                 => "bk-host1-renamed",
                                  :ems_ref              => "f80e97cf-97fc-4a40-9ec8-1f37454654fc",
                                  :uid_ems              => nil,
                                  :physical_storage     => ems.physical_storages.find_by(:ems_ref => "980f3ceb-c599-49c4-9db3-fdc793cb8666"),
                                  :type                 => "ManageIQ::Providers::Autosde::StorageManager::HostInitiator",
                                  :status               => "offline",
                                  :host_cluster_name    => "bk-cluster1",
                                  :host_initiator_group => nil
                                ))
    end

    def assert_specific_host_initiator_group
      host_initiator_group = ems.host_initiator_groups.find_by(:ems_ref => "856146bb-4fe3-4d8f-b442-49a2dd80dd96")
      expect(host_initiator_group).to(have_attributes(
                                        :name             => "bk-cluster1",
                                        :status           => nil,
                                        :ems_ref          => "856146bb-4fe3-4d8f-b442-49a2dd80dd96",
                                        :uid_ems          => nil,
                                        :type             => "ManageIQ::Providers::Autosde::StorageManager::HostInitiatorGroup",
                                        :physical_storage => ems.physical_storages.find_by(:ems_ref => "980f3ceb-c599-49c4-9db3-fdc793cb8666")
                                      ))
    end

    def assert_specific_host_volume_mapping
      host_volume_mapping = ems.host_volume_mappings.find_by(:ems_ref => "4c9dac0d-d972-4020-8f14-40df08c9968c")
      expect(host_volume_mapping).to(have_attributes(
                                       :ems_ref              => "4c9dac0d-d972-4020-8f14-40df08c9968c",
                                       :uid_ems              => nil,
                                       :lun                  => 100,
                                       :type                 => "ManageIQ::Providers::Autosde::StorageManager::HostVolumeMapping",
                                       :cloud_volume         => ems.cloud_volumes.find_by(:ems_ref => "ae332deb-aa1f-48ff-bc43-56c46ad48b46"),
                                       :host_initiator       => ems.host_initiators.find_by(:ems_ref => "10e8d254-05d9-40dd-9da0-80d65cd0c284"),
                                       :host_initiator_group => nil
                                     ))
    end

    def assert_specific_cluster_volume_mapping
      cluster_volume_mapping = ems.cluster_volume_mappings.first
      expect(cluster_volume_mapping).to(have_attributes(
                                          :ems_ref              => "3a0700b4-3f8d-4f29-8330-af16cbc9f34b",
                                          :uid_ems              => nil,
                                          :lun                  => 0,
                                          :type                 => "ManageIQ::Providers::Autosde::StorageManager::ClusterVolumeMapping",
                                          :host_initiator       => nil,
                                          :host_initiator_group => ems.host_initiator_groups.find_by(:ems_ref => "db5b9911-4f03-43ad-9e13-8ab0de09226c")
                                        ))
    end

    def assert_specific_storage_service_resource_attachment
      attachment = ems.storage_service_resource_attachments.find_by(:ems_ref => "f0ecb715-19a1-4e74-b6f5-5c428a9c741d")
      expect(attachment).to(have_attributes(
                              :storage_resource_id => ems.storage_resources.find_by(:ems_ref => "f60e8f31-1d22-48fe-a79c-319b6c3613aa"),
                              :storage_service_id  => ems.storage_services.find_by(:ems_ref => "5189b322-c4ce-47ea-b267-381e8c4baab5"),
                              :ems_ref             => "f0ecb715-19a1-4e74-b6f5-5c428a9c741d"
                            ))
    end
  end
end
