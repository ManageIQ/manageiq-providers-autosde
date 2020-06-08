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

    collected_data[:storage_systems].each do |storage_system_hash|
      storage_system = persister.collections[:storage_systems].build(**storage_system_hash, )
      collected_data[:storage_resources].select  {|h| h[:storage_system_uuid] == storage_system_hash[:uuid]}.each do |storage_resource_hash|
        storage_resource_hash.except!(:storage_system_uuid)
        storage_resource = persister.collections[:storage_resources].build(**storage_resource_hash, storage_system: storage_system)

        collected_data[:cloud_volumes].select {|h| h[:storage_resource_uuid] == storage_resource_hash[:uuid]}.each do |cloud_volume_hash|
          cloud_volume_hash.except!(:storage_resource_uuid)
          persister.collections[:cloud_volumes].build(**cloud_volume_hash, storage_resource: storage_resource)
        end
      end
    end

    collected_data[:storage_services].each do |storage_service_hash|
      persister.collections[:storage_services].build(**storage_service_hash)
    end

  end
end
