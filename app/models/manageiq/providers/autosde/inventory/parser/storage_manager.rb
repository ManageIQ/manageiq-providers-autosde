# This class is supposed to take the parser and the collector, and build a snapshot of the inventory.
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
    collected_data = collector.collect

    collected_data[:storage_system_types].each do |storage_system_type_hash|
      persister.collections[:storage_system_types].build(**storage_system_type_hash)
    end

    collected_data[:storage_systems].each do |storage_system_hash|
      system_type_uuid = storage_system_hash.delete(:system_type_uuid)
      storage_system_type = persister.collections[:storage_system_types].data_storage.data.select {|st| st.ems_ref == system_type_uuid}[0]
      storage_system = persister.collections[:storage_systems].build(
          storage_system_type: storage_system_type,
        **storage_system_hash )

      collected_data[:storage_resources].select  {|h| h[:storage_system_uuid] == storage_system_hash[:uuid]}.each do |storage_resource_hash|
        storage_resource_hash.delete(:storage_system_uuid)
        persister.collections[:storage_resources].build(**storage_resource_hash, storage_system: storage_system)
      end
    end

    collected_data[:storage_services].each do |storage_service_hash|
      storage_service = persister.collections[:storage_services].build(**storage_service_hash)

      collected_data[:cloud_volumes].select {|h| h[:storage_service_uuid] == storage_service_hash[:uuid]}.each do |cloud_volume_hash|
        storage_resource_uuid = cloud_volume_hash.delete(:storage_resource_uuid)
        storage_resource = persister.collections[:storage_resources].data_storage.data.select {|sr| sr.ems_ref == storage_resource_uuid} .first
        cloud_volume_hash.delete(:storage_service_uuid)
        persister.collections[:cloud_volumes].build(**cloud_volume_hash, storage_resource: storage_resource, storage_service: storage_service)
      end
    end

  end

end