# This class is supposed to collect raw output from the managed system
class ManageIQ::Providers::Autosde::Inventory::Collector::StorageManager < ManageIQ::Providers::Inventory::Collector
  # @return [ManageIQ::Providers::Autosde::StorageManager]
  attr_accessor :manager

  def physical_storages
    @physical_storages ||= @manager.autosde_client.StorageSystemApi.storage_systems_get
  end

  def storage_resources
    @storage_resources ||= @manager.autosde_client.StorageResourceApi.storage_resources_get
  end

  def storage_hosts
    @storage_hosts ||= @manager.autosde_client.StorageHostApi.storage_hosts_get
  end

  def host_volume_mappings
    @host_volume_mappings ||= @manager.autosde_client.StorageHostsMappingApi.storage_hosts_mapping_get
  end

  def cluster_volume_mappings
    @cluster_volume_mappings ||= @manager.autosde_client.HostClusterVolumeMappingApi.host_clusters_mapping_get
  end

  def cloud_volumes
    @cloud_volumes ||= @manager.autosde_client.VolumeApi.volumes_get
  end

  def storage_services
    @storage_services ||= @manager.autosde_client.ServiceApi.services_get
  end

  def physical_storage_families
    @physical_storage_families ||= @manager.autosde_client.SystemTypeApi.system_types_get
  end

  def wwpn_candidates
    @wwpn_candidates ||= @manager.autosde_client.StorageHostWWPNCandidatesApi.storage_hosts_wwpn_candidates_get
  end

  def host_initiator_groups
    @host_initiator_groups ||= @manager.autosde_client.HostClusterApi.host_clusters_get
  end

  def storage_capabilities
    @storage_capabilities ||= @manager.autosde_client.AbstractCapabilityApi.abstract_capabilities_get
  end

  def storage_capability_values
    @storage_capability_values ||= @manager.autosde_client.ServiceAbstractCapabilityValueApi.service_abstract_capability_values_get
  end
end
