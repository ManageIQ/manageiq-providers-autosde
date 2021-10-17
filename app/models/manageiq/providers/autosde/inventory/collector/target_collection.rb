class ManageIQ::Providers::Autosde::Inventory::Collector::TargetCollection < ManageIQ::Providers::Autosde::Inventory::Collector::StorageManager
  def initialize(_manager, _target)
    super

    parse_targets!
  end

  def physical_storages
    return [] if references(:physical_storages).blank?

    super
  end

  def storage_resources
    return [] if references(:storage_resources).blank?

    super
  end

  def storage_hosts
    return [] if references(:storage_hosts).blank?

    super
  end

  def volume_mappings
    return [] if references(:volume_mappings).blank?

    super
  end

  def cloud_volumes
    return [] if references(:cloud_volumes).blank?

    super
  end

  def storage_services
    return [] if references(:storage_services).blank?

    super
  end

  def physical_storage_families
    return [] if references(:physical_storage_families).blank?

    super
  end

  def wwpn_candidates
    return [] if references(:wwpn_candidates).blank?

    super
  end

  private

  def parse_targets!
    # `target` here is an `InventoryRefresh::TargetCollection`.  This contains two types of targets,
    # `InventoryRefresh::Target` which is essentialy an association/manager_ref pair, or an ActiveRecord::Base
    # type object like a Vm.
    #
    # This gives us some flexibility in how we request a resource be refreshed.
    target.targets.each do |target|
      case target
      when PhysicalStorageFamily
        add_target(:physical_storage_families, target.ems_ref)
      when PhysicalStorage
        add_target(:physical_storages, target.ems_ref)
      when StorageResource
        add_target(:storage_resources, target.ems_ref)
      when HostInitiator
        add_target(:storage_hosts, target.ems_ref) # TODO [liran] - storage_hosts need to be renamed to host_initiators
      when StorageService
        add_target(:storage_services, target.ems_ref)
      when CloudVolume
        add_target(:cloud_volumes, target.ems_ref)
      when VolumeMapping
        add_target(:volume_mappings, target.ems_ref)
      when WwpnCandidate
        add_target(:wwpn_candidates, target.ems_ref)
      end
    end
  end

  def add_target(association, ems_ref)
    return if ems_ref.blank?

    target.add_target(:association => association, :manager_ref => {:ems_ref => ems_ref})
  end

  # This helps us reference all unique references by collection e.g. all VM targets
  def references(collection)
    target.manager_refs_by_association&.dig(collection, :ems_ref)&.to_a&.compact || []
  end
end
