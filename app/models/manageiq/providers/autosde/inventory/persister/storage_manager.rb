# This class builds the collections. The parser then adds actual inventory items to the collections.
# Generally, one collection per application-record class.
# for more info see: https://www.manageiq.org/docs/guides/providers/persister/inventory_collections
class ManageIQ::Providers::Autosde::Inventory::Persister::StorageManager < ManageIQ::Providers::Inventory::Persister
  # @return [Hash{Symbol => InventoryRefresh::InventoryCollection}] collections
  attr_reader  :collections

  def initialize_inventory_collections
    add_san_addresses
    add_host_initiators
    add_volume_mappings
    add_wwpn_candidates
    add_host_initiator_groups
    add_physical_storages
    add_physical_storage_families
    add_storage_resources
    add_storage_services
    add_cloud_volumes
  end

  protected

  # san addresses
  def add_san_addresses
    add_collection(storage, :san_addresses)
  end

  # host initiators
  def add_host_initiators
    add_collection(storage, :host_initiators)
  end

  # volume mappings
  def add_volume_mappings
    add_collection(storage, :volume_mappings)
  end

  # wwpn candidates
  def add_wwpn_candidates
    add_collection(storage, :wwpn_candidates)
  end

  # host-initiator-groups (cluster)
  def add_host_initiator_groups
    add_collection(storage, :host_initiator_groups)
  end

  # physical storages
  def add_physical_storages
    add_collection(storage, :physical_storages)
  end

  # physical storage families
  def add_physical_storage_families
    add_collection(storage, :physical_storage_families)
  end

  # storage resources
  def add_storage_resources
    add_collection(storage, :storage_resources)
  end

  # storage services
  def add_storage_services
    add_collection(storage, :storage_services)
  end

  # cloud volumes
  def add_cloud_volumes
    add_collection(storage, :cloud_volumes)
  end
end
