# This class builds the collections. The parser then adds actual inventory items to the collections.
# Generally, one collection per application-record class.
class ManageIQ::Providers::Autosde::Inventory::Persister::StorageManager < ManageIQ::Providers::Inventory::Persister
  # @return [Hash{Symbol => InventoryRefresh::InventoryCollection}] collections
  attr_reader  :collections

  def initialize_inventory_collections
    # physical storages
    add_collection(storage, :physical_storages) do |builder|
      builder.add_default_values(:ems_id => ->(persister) { persister.manager.id })
      builder.add_properties(
        :model_class => ManageIQ::Providers::Autosde::StorageManager::PhysicalStorage
      )
    end

    # storage resources
    add_collection(storage, :storage_resources) do |builder|
      builder.add_default_values(
        :ems_id => ->(persister) { persister.manager.id }
      )
      builder.add_properties(
        :parent_inventory_collections => [:physical_storages]
      )
    end

    # san addresses
    add_collection(storage, :san_addresses) do |builder|
      builder.add_default_values(
        :ems_id => ->(persister) { persister.manager.id }
      )
      builder.add_properties(
        :parent_inventory_collections => [:host_initiators]
      )
    end

    # host initiators
    add_collection(storage, :host_initiators)

    # storage services
    add_collection(storage, :storage_services) do |builder|
      builder.add_default_values(
        :ems_id => ->(persister) { persister.manager.id }
      )
    end

    # cloud volumes
    add_collection(storage, :cloud_volumes) do |builder|
      builder.add_default_values(
        :ems_id      => ->(persister) { persister.manager.id },
        :status      => "Available",
        :volume_type => "ISCSI/FC",
        :bootable    => "false"
      )
      builder.add_properties(
        :model_class => ManageIQ::Providers::Autosde::StorageManager::CloudVolume
      )
    end

    # physical storage families
    add_collection(storage, :physical_storage_families) do |builder|
      builder.add_default_values(
        :ems_id => ->(persister) { persister.manager.id }
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
      :parent   => parent
    }
  end
end
