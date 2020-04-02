class ManageIQ::Providers::Autosde::Inventory::Persister < ManageIQ::Providers::Inventory::Persister
  require_nested :PhysicalInfraManager

  def initialize_inventory_collections
    %i[
      physical_storages
      physical_storage_details
    ].each do |name|
      add_collection(physical_infra, name)
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
