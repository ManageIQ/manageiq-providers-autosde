# This class builds the collections. The parser then adds actual inventory items to the collections.
# Generally, one collection per application-record class.
# for more info see: https://www.manageiq.org/docs/guides/providers/persister/inventory_collections
class ManageIQ::Providers::Autosde::Inventory::Persister::StorageManager < ManageIQ::Providers::Inventory::Persister
  # @return [Hash{Symbol => InventoryRefresh::InventoryCollection}] collections
  attr_reader  :collections

  def initialize_inventory_collections
    collect_san_addresses
    collect_host_initiators
    collect_volume_mappings
    collect_wwpn_candidates
    collect_host_initiator_groups
    collect_physical_storages
    collect_physical_storage_families
    collect_storage_resources
    collect_storage_services
    collect_cloud_volumes
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

  protected

  # san addresses
  def collect_san_addresses
    add_collection(storage, :san_addresses) do |builder|
      builder.add_default_values(
        :ems_id => ->(persister) { persister.manager.id }
      )
      builder.add_properties(
        :parent_inventory_collections => [:host_initiators]
      )
    end
  end

  # host initiators
  def collect_host_initiators
    add_collection(storage, :host_initiators)
  end

  # volume mappings
  def collect_volume_mappings
    add_collection(storage, :volume_mappings)
  end

  # wwpn candidates
  def collect_wwpn_candidates
    add_collection(storage, :wwpn_candidates) do |builder|
      builder.add_default_values(
        :ems_id => ->(persister) { persister.manager.id }
      )
    end
  end

  # host-initiator-groups (cluster)
  def collect_host_initiator_groups
    add_collection(storage, :host_initiator_groups) do |builder|
      builder.add_default_values(
        :ems_id => ->(persister) { persister.manager.id }
      )
    end
  end

  # physical storages
  def collect_physical_storages
    add_collection(storage, :physical_storages) do |builder|
      builder.add_default_values(:ems_id => ->(persister) { persister.manager.id })
      builder.add_properties(
        :model_class => ManageIQ::Providers::Autosde::StorageManager::PhysicalStorage
      )
    end
  end

  # physical storage families
  def collect_physical_storage_families
    add_collection(storage, :physical_storage_families) do |builder|
      builder.add_default_values(
        :ems_id => ->(persister) { persister.manager.id }
      )
    end
  end

  # storage resources
  def collect_storage_resources
    add_collection(storage, :storage_resources) do |builder|
      builder.add_default_values(
        :ems_id => ->(persister) { persister.manager.id }
      )
      builder.add_properties(
        :parent_inventory_collections => [:physical_storages]
      ) unless targeted?
    end
  end

  # storage services
  def collect_storage_services
    add_collection(storage, :storage_services) do |builder|
      builder.add_default_values(
        :ems_id => ->(persister) { persister.manager.id }
      )
    end
  end

  # cloud volumes
  def collect_cloud_volumes
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
  end
end
