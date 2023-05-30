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


  def cloud_volumes
    return [] if references(:cloud_volumes).blank?

    @cloud_volumes ||= @manager.autosde_client.VolumeApi.volumes_get.select { |s| references(:cloud_volumes).include?(s.uuid) }
  end

  def cloud_volume_snapshots
    return [] if references(:cloud_volume_snapshots).blank?

    @cloud_volume_snapshots ||= @manager.autosde_client.SnapshotApi.snapshots_get.select { |s| references(:cloud_volume_snapshots).include?(s.uuid) }
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

  def host_initiators
    return [] if references(:host_initiators).blank?

    @host_initiators ||= @manager.autosde_client.StorageHostApi.storage_hosts_get.select { |s| references(:host_initiators).include?(s.uuid) }
  end

  def host_initiator_groups
    return [] if references(:host_initiator_groups).blank?

    @host_initiator_groups ||= @manager.autosde_client.HostClusterApi.host_clusters_get.select { |s| references(:host_initiator_groups).include?(s.uuid) }
  end

  def host_volume_mappings
    return [] if references(:host_volume_mappings).blank?

    @host_volume_mappings ||= @manager.autosde_client.StorageHostsMappingApi.storage_hosts_mapping_get.select { |s| references(:host_volume_mappings).include?(s.uuid) }
  end

  def cluster_volume_mappings
    return [] if references(:cluster_volume_mappings).blank?

    @cluster_volume_mappings ||= @manager.autosde_client.HostClusterVolumeMappingApi.host_clusters_mapping_get.select { |s| references(:cluster_volume_mappings).include?(s.uuid) }
  end

  def capability_values
    @manager.capabilities || []
  end

  def storage_service_resource_attachments
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
      when StorageService
        add_target!(:storage_services, target.ems_ref)
      when CloudVolumeSnapshot
        add_target!(:cloud_volume_snapshots, target.ems_ref)
      when HostInitiator
        add_target!(:host_initiators, target.ems_ref)
      when HostInitiatorGroup
        add_target!(:host_initiator_groups, target.ems_ref)
      when VolumeMapping
        model = target.type.include?("HostVolumeMapping") ? :host_volume_mappings : :cluster_volume_mappings
        add_target!(model, target.ems_ref)
      end
    end
  end
end
