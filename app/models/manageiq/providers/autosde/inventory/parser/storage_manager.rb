# This class is supposed to take the persister and the collector, and build a snapshot of the inventory.
# The snapshot is then compared against the DB and the DB is adjusted to fit the snapshot.
class ManageIQ::Providers::Autosde::Inventory::Parser::StorageManager < ManageIQ::Providers::Inventory::Parser
  # @return [ManageIQ::Providers::Autosde::Inventory::Collector::StorageManager]
  attr_accessor :collector

  # The main function that's supposed to build the inventory_items in persister.collection based on collector's data
  #
  # example of how to build:
  # persister.physical_storages.build(
  #     :ems_ref => "s2", :name => "Storage 3", :ems_id=>persister.manager.id
  # )#
  def parse
    physical_storage_families
    physical_storages
    storage_resources
    host_initiators
    host_initiator_groups
    san_addresses
    storage_services
    cloud_volumes
    volume_mappings
    wwpn_candidates
    storage_capabilities
    storage_capability_values
  end

  def physical_storage_families
    collector.physical_storage_families.each do |storage_family|
      persister.physical_storage_families.build(
        :name    => storage_family.name,
        :ems_ref => storage_family.uuid,
        :version => storage_family.version
      )
    end
  end

  def physical_storages
    collector.physical_storages.each do |storage|
      persister.physical_storages.build(
        :name                    => storage.name,
        :ems_ref                 => storage.uuid,
        :physical_storage_family => persister.physical_storage_families.lazy_find(storage.system_type.uuid),
        :health_state            => storage.status
      )
    end
  end

  def storage_resources
    collector.storage_resources.each do |resource|
      persister.storage_resources.build(
        :name             => resource.name,
        :ems_ref          => resource.uuid,
        :logical_free     => resource.logical_free,
        :logical_total    => resource.logical_total,
        :physical_storage => persister.physical_storages.lazy_find(resource.storage_system)
      )
    end
  end

  def san_addresses
    port_type = {
      "ISCSI"  => "IscsiAddress",
      "FC"     => "FiberChannelAddress",
      "NVMeFC" => "NvmeAddress"
    }

    collector.storage_hosts.flat_map do |host_initiator|
      host_initiator.addresses.flat_map do |address|
        persister.san_addresses.build(
          :ems_ref     => address.uuid,
          :owner       => persister.host_initiators.lazy_find(host_initiator.uuid),
          :type        => port_type[address.port_type],
          :iqn         => address.iqn,
          :chap_name   => address.chap_name,
          :chap_secret => address.chap_secret,
          :wwpn        => address.wwpn
        )
      end
    end
  end

  def host_initiators
    collector.storage_hosts.each do |host_initiator|
      persister.host_initiators.build(
        :name                 => host_initiator.name,
        :ems_ref              => host_initiator.uuid,
        :physical_storage     => persister.physical_storages.lazy_find(host_initiator.storage_system),
        :status               => host_initiator.status,
        :host_cluster_name    => host_initiator.host_cluster_name,
        :host_initiator_group => persister.host_initiator_groups.lazy_find(host_initiator.host_cluster)
      )
    end
  end

  def volume_mappings
    collector.host_volume_mappings.each do |mapping|
      persister.volume_mappings.build(
        :lun            => mapping.lun,
        :host_initiator => persister.host_initiators.lazy_find(mapping.host),
        :cloud_volume   => persister.cloud_volumes.lazy_find(mapping.volume),
        :ems_ref        => mapping.uuid,
        :type           => "ManageIQ::Providers::Autosde::StorageManager::HostVolumeMapping"
      )
    end
    collector.cluster_volume_mappings.each do |mapping|
      persister.volume_mappings.build(
        :lun                  => mapping.lun,
        :host_initiator_group => persister.host_initiator_groups.lazy_find(mapping.cluster),
        :cloud_volume         => persister.cloud_volumes.lazy_find(mapping.volume),
        :ems_ref              => mapping.uuid,
        :type                 => "ManageIQ::Providers::Autosde::StorageManager::ClusterVolumeMapping"
      )
    end
  end

  def storage_services
    collector.storage_services.each do |service|
      persister.storage_services.build(
        :name        => service.name,
        :description => service.description,
        :version     => service.version,
        :ems_ref     => service.uuid
      )
    end
  end

  def cloud_volumes
    collector.cloud_volumes.each do |volume|
      persister.cloud_volumes.build(
        :name             => volume.name,
        :size             => volume.size * 1024 * 1024 * 1024,
        :ems_ref          => volume.uuid,
        :volume_type      => "ISCSI/FC",
        :bootable         => false,
        :storage_resource => persister.storage_resources.lazy_find(volume.storage_resource),
        :storage_service  => persister.storage_services.lazy_find(volume.service),
        :status           => volume.component_state,
        :health_state     => volume.status
      )
    end
  end

  def wwpn_candidates
    collector.wwpn_candidates.each do |candidate|
      persister.wwpn_candidates.build(
        :candidate        => candidate.wwpn,
        :ems_ref          => candidate.wwpn,
        :physical_storage => persister.physical_storages.lazy_find(candidate.system_uuid)
      )
    end
  end

  def host_initiator_groups
    collector.host_initiator_groups.each do |group|
      persister.host_initiator_groups.build(
        :name             => group.name,
        :ems_ref          => group.uuid,
        :physical_storage => persister.physical_storages.lazy_find(group.storage_system)
      )
    end
  end

  def storage_capabilities
    collector.storage_capabilities.each do |capability|
      persister.storage_capabilities.build(
        :name    => capability.name,
        :ems_ref => capability.uuid
      )
    end
  end

  def storage_capability_values
    collector.storage_capability_values.each do |capability_value|
      persister.storage_capability_values.build(
        :value              => capability_value.value,
        :ems_ref            => capability_value.uuid,
        :storage_capability => persister.storage_capabilities.lazy_find(capability_value.abstract_capability)
      )
    end
  end
end
