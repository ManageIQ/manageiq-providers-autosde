class ManageIQ::Providers::Autosde::Inventory::Persister < ManageIQ::Providers::Inventory::Persister
  require_nested :PhysicalInfraManager

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
