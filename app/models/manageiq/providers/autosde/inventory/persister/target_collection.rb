class ManageIQ::Providers::Autosde::Inventory::Persister::TargetCollection < ManageIQ::Providers::Autosde::Inventory::Persister::StorageManager
  def targeted?
    true
  end

  # Overwrite the base initialize_inventory_collections function, and add to collections only the targeted objects.
  def initialize_inventory_collections
    target.manager_refs_by_association.each_key do |target|
      send("add_#{target}")
    end
  end
end
