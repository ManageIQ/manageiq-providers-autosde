# This class is supposed to take the persister and the collector, and build a snapshot of the inventory.
# The snapshot is then compared against the DB and the DB is adjusted to fit the snapshot.
class ManageIQ::Providers::Autosde::Inventory::Parser::StorageManager < ManageIQ::Providers::Inventory::Parser
  # @return [ManageIQ::Providers::Autosde::Inventory::Collector::StorageManager]
  attr_accessor :collector

  # The main function that's supposed to build the inventory_items in persister.collection based on collector's data
  #
  # example of how to build:
  # persister.collections[:physical_storages].build(
  #     :ems_ref => "s2", :name => "Storage 3", :ems_id=>persister.manager.id
  # )#
  def parse
    collector.physical_storage_families.each do |physical_storage_family_hash|
      persister.collections[:physical_storage_families].build(**physical_storage_family_hash)
    end

    collector.physical_storages.each do |physical_storage_hash|
      system_type_uuid = physical_storage_hash.delete(:system_type_uuid)
      physical_storage_family = persister.collections[:physical_storage_families].data_storage.data.select { |st| st.ems_ref == system_type_uuid }[0]
      physical_storage = persister.collections[:physical_storages].build(
        :physical_storage_family => physical_storage_family,
      **physical_storage_hash
      )

      collector.storage_resources.select { |h| h[:storage_system_uuid] == physical_storage_hash[:ems_ref] }.each do |storage_resource_hash|
        storage_resource_hash.delete(:storage_system_uuid)
        persister.collections[:storage_resources].build(**storage_resource_hash, :physical_storage => physical_storage)
      end
    end

    collector.storage_services.each do |storage_service_hash|
      storage_service = persister.collections[:storage_services].build(**storage_service_hash)

      collector.cloud_volumes.select { |h| h[:storage_service_uuid] == storage_service_hash[:ems_ref] }.each do |cloud_volume_hash|
        storage_resource_uuid = cloud_volume_hash.delete(:storage_resource_uuid)
        storage_resource = persister.collections[:storage_resources].data_storage.data.find { |sr| sr.ems_ref == storage_resource_uuid }
        cloud_volume_hash.delete(:storage_service_uuid)
        persister.collections[:cloud_volumes].build(
            **cloud_volume_hash, :storage_resource => storage_resource, :storage_service => storage_service)
      end
    end
  end
end
