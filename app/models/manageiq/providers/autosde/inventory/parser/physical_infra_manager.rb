# This class is supposed to take the parser and the collector, and build a snapshot of the inventory.
# The snapshot is then compared against the DB and the DB is adjusted to fit the snapshot.
class ManageIQ::Providers::Autosde::Inventory::Parser::PhysicalInfraManager < ManageIQ::Providers::Inventory::Parser

  # The main function that's supposed to build the inventory_items in the collection.
  # example of how to build:
  # persister.collections[:physical_storages].build(
  #     :ems_ref => "s2", :name => "Storage 3", :ems_id=>persister.manager.id
  # )#
  def parse
    collected_data = @collector.collect

    collected_data[:physical_storages].each do |storage_hash|
      chassis = persister.collections[:physical_chassis].build(:ems_ref => storage_hash[:ems_ref])
      computer_system = persister.collections[:computer_systems].build(:managed_entity => chassis)
      hardware = persister.collections[:hardwares].build(:computer_system => computer_system)
      persister.collections[:volumes].build(:uid => '34', :hardware => hardware)

      storage = persister.collections[:physical_storages].build(**storage_hash, :physical_chassis => chassis)
      persister.collections[:physical_storage_details].build(:resource => storage, :description => "detail description?")

    end
  end

end

