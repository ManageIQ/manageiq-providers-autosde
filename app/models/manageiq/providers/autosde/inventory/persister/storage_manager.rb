# This class builds the collections. The parser then adds actual inventory items to the collections.
# Generally, one collection per application-record class.
# for more info see: https://www.manageiq.org/docs/guides/providers/persister/inventory_collections
class ManageIQ::Providers::Autosde::Inventory::Persister::StorageManager < ManageIQ::Providers::Inventory::Persister
  # @return [Hash{Symbol => InventoryRefresh::InventoryCollection}] collections
  attr_reader  :collections

  def initialize_inventory_collections
    add_collection(storage, :san_addresses)
    add_collection(storage, :host_initiators)
    add_collection(storage, :volume_mappings)
    add_collection(storage, :wwpn_candidates)
    add_collection(storage, :host_initiator_groups)
    add_collection(storage, :physical_storages)
    add_collection(storage, :physical_storage_families)
    add_collection(storage, :storage_resources)
    add_collection(storage, :storage_services)
    add_collection(storage, :cloud_volumes)
    add_collection(storage, :cloud_volume_snapshots)
    add_collection(storage, :ext_management_system)
    add_collection(storage, :storage_service_resource_attachments)
    add_physical_storage_details
  end

  def add_physical_storage_details
    add_collection(storage, :physical_storage_details) do |builder|
      builder.add_properties(
        :model_class                  => ::AssetDetail,
        :manager_ref                  => %i[resource],
        :parent_inventory_collections => %i[physical_storages]
      )
    end
  end
end
