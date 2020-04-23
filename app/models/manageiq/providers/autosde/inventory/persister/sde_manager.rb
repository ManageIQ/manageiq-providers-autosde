# This clas builds the collections. The parser then adds actual inventory items to the collections.
# Generally, one collection per application-record class.
class ManageIQ::Providers::Autosde::Inventory::Persister::SdeManager < ManageIQ::Providers::Inventory::Persister

  # @return [Hash{Symbol => InventoryRefresh::InventoryCollection}] collections
  attr_reader  :collections

  def initialize_inventory_collections
    %i[
      physical_storages
      physical_storage_details
      physical_chassis
    ].each do |name|
      add_collection(physical_infra, name)
    end

    add_collection(physical_infra, :computer_systems) do |builder|
      builder.add_properties(
          :manager_ref => %i[managed_entity],
          :parent_inventory_collections => [:physical_chassis]
      )
    end


    add_collection(physical_infra, :hardwares) do |builder|
      builder.add_properties(
          :manager_ref => %i[computer_system],
          :parent_inventory_collections => [:computer_systems]
      )
    end

    add_collection(physical_infra, :volumes) do |builder|
      builder.add_properties(
          :manager_ref => %i[hardware],
          :parent_inventory_collections => [:hardwares]
      )
    end

  end

  def strategy
    nil
  end

  def parent
    manager.presence
  end

  def shared_options
    {
        :strategy => strategy,
        :targeted => targeted?,
        :parent => parent
    }
  end
end
