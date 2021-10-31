class ManageIQ::Providers::Autosde::Inventory::Collector::TargetCollection < ManageIQ::Providers::Autosde::Inventory::Collector::StorageManager
  def initialize(_manager, _target)
    super

    parse_targets!
  end

  def physical_storages
    return [] if references(:physical_storages).blank?

    @physical_storages ||= begin
      references(:physical_storages).map do |ems_ref|
        @manager.autosde_client.StorageSystemApi.storage_systems_get.map{|s| s if s.uuid==ems_ref}.compact.first
      end
    end

    super
  end

  def storage_resources
    return [] if references(:storage_resources).blank?

    @storage_resources ||= begin
      references(:storage_resources).map do |ems_ref|
        @manager.autosde_client.StorageResourceApi.storage_resources_get.map{|s| s if s.uuid==ems_ref}.compact.first
      end
    end

    super
  end

  def storage_hosts
    return [] if references(:storage_hosts).blank?

    super
  end

  def host_volume_mappings
    return [] if references(:volume_mappings).blank?

    super
  end

  def cluster_volume_mappings
    return [] if references(:volume_mappings).blank?

    super
  end

  def cloud_volumes
    return [] if references(:cloud_volumes).blank?

    # Retrieve only the targeted volumes
    @cloud_volumes ||= begin
      references(:cloud_volumes).map do |ems_ref|
        @manager.autosde_client.VolumeApi.volumes_get.map{|v| v if v.uuid==ems_ref}.compact.first
      end
    end

    super
  end

  def storage_services
    return [] if references(:storage_services).blank?

    @storage_services ||= begin
      references(:storage_services).map do |ems_ref|
        @manager.autosde_client.ServiceApi.services_get.map{|s| s if s.uuid==ems_ref}.compact.first
      end
    end

    super
  end

  def physical_storage_families
    return [] if references(:physical_storage_families).blank?

    @physical_storage_families ||= begin
      references(:physical_storage_families).map do |ems_ref|
        @manager.autosde_client.SystemTypeApi.system_types_get.map{|s| s if s.uuid==ems_ref}.compact.first
      end
    end

    super
  end

  def wwpn_candidates
    return [] if references(:wwpn_candidates).blank?

    super
  end

  def host_initiator_groups
    return [] if references(:host_initiator_groups).blank?

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
      when PhysicalStorage
        add_target(:physical_storages, target.ems_ref)
        add_target(:physical_storage_families, PhysicalStorageFamily.find(id=target.physical_storage_family_id).ems_ref)
      when CloudVolume
        storage_resource = StorageResource.find(id=target.storage_resource_id)
        storage_service = StorageService.find(id=target.storage_service_id)
        physical_storage = PhysicalStorage.find(id=storage_resource.physical_storage_id)
        physical_storage_family = PhysicalStorageFamily.find(id=physical_storage.physical_storage_family_id)
        add_target(:cloud_volumes, target.ems_ref)
        add_target(:storage_resources, storage_resource.ems_ref)
        add_target(:storage_services, storage_service.ems_ref)
        add_target(:physical_storages, physical_storage.ems_ref)
        add_target(:physical_storage_families, physical_storage_family.ems_ref)
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
