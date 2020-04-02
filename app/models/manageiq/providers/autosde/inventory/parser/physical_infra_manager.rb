# This class is supposed to take the parser and the collector, and rebuild the inventory with them.
class ManageIQ::Providers::Autosde::Inventory::Parser::PhysicalInfraManager < ManageIQ::Providers::Inventory::Parser

  # The main function that's supposed to build the inventory_items in the collection.
  # example of how to build:
  # persister.collections[:physical_storages].build(
  #     :ems_ref => "s2", :name => "Storage 3", :ems_id=>persister.manager.id
  # )#
  def parse

  end

end
