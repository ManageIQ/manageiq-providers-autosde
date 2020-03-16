module ManageIQ::Providers::Autosde::Inventory::Persister::Definitions::PhysicalInfraCollections
  extend ActiveSupport::Concern

  def initialize_physical_infra_inventory_collections
    %i(vms).each do |name|
      add_collection(physical_infra, name)
    end
  end
end
