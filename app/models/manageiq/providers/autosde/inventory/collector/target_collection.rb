class ManageIQ::Providers::Autosde::Inventory::Collector::TargetCollection < ManageIQ::Providers::Autosde::Inventory::Collector::StorageManager
  def initialize(_manager, target)
    super

    parse_targets!
    target.manager_refs_by_association_reset
  end

  def physical_storages
    return [] if references(:physical_storages).blank?

    @physical_storages ||= @manager.autosde_client.StorageSystemApi.storage_systems_get.select { |s| references(:physical_storages).include?(s.uuid) }
  end

  def storage_resources
    return [] if references(:storage_resources).blank?

    @storage_resources ||= @manager.autosde_client.StorageResourceApi.storage_resources_get.select { |s| references(:storage_resources).include?(s.uuid) }
  end

  def storage_hosts
    []
  end

  def host_volume_mappings
    []
  end

  def cluster_volume_mappings
    []
  end

  def cloud_volumes
    return [] if references(:cloud_volumes).blank?

    @cloud_volumes ||= @manager.autosde_client.VolumeApi.volumes_get.select { |s| references(:cloud_volumes).include?(s.uuid) }
  end

  def storage_services
    return [] if references(:storage_services).blank?

    @storage_services ||= @manager.autosde_client.ServiceApi.services_get.select { |s| references(:storage_services).include?(s.uuid) }
  end

  def physical_storage_families
    return [] if references(:physical_storage_families).blank?

    @physical_storage_families ||= @manager.autosde_client.SystemTypeApi.system_types_get.select { |s| references(:physical_storage_families).include?(s.uuid) }
  end

  def wwpn_candidates
    []
  end

  def host_initiator_groups
    []
  end

  def capability_values
    []
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
        add_target!(:physical_storages, target.ems_ref)
      when CloudVolume
        add_target!(:cloud_volumes, target.ems_ref)
      end
    end
  end
end
