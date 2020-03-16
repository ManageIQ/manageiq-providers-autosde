class ManageIQ::Providers::Autosde::Inventory::Persister::PhysicalInfraManager < ManageIQ::Providers::Autosde::Inventory::Persister
  include ManageIQ::Providers::Autosde::Inventory::Persister::Definitions::PhysicalInfraCollections

  def initialize_inventory_collections
    initialize_physical_infra_inventory_collections
  end
end
