# This class is supposed to collect raw output from the managed system
class ManageIQ::Providers::Autosde::Inventory::Collector::StorageManager < ManageIQ::Providers::Inventory::Collector
  # @return [ManageIQ::Providers::Autosde::StorageManager]
  attr_accessor :manager

  def physical_storages
    @physical_storages ||= @manager.autosde_client.StorageSystemApi.storage_systems_get.map do |system|
      {
        :name             => system.name,
        :ems_ref          => system.uuid,
        :system_type_uuid => system.system_type.uuid,
      }
    end
  end

  def storage_resources
    @storage_resources ||= @manager.autosde_client.StorageResourceApi.storage_resources_get.map do |resource|
      {
        :name                => resource.name,
        :ems_ref             => resource.uuid,
        :logical_free        => resource.logical_free,
        :logical_total       => resource.logical_total,
        :storage_system_uuid => resource.storage_system
      }
    end
  end

  def addresses
    @addresses ||= @manager.autosde_client.StorageHostApi.storage_hosts_get.map do |address|
      {
        :ems_ref                => address.addresses[0].uuid,
        :iqn                    => address.addresses[0].iqn,
        :wwpn                   => address.addresses[0].wwpn,
        :physical_storage_consumers_uuid => address.uuid,
        :storage_system_uuid    => address.storage_system
      }
    end
  end

  def physical_storage_consumers
    @physical_storage_consumers ||= @manager.autosde_client.StorageHostApi.storage_hosts_get.map do |consumer|
      {
        :name                => consumer.name,
        :ems_ref             => consumer.uuid,
        :storage_system_uuid => consumer.storage_system
      }
    end
  end

  def cloud_volumes
    @cloud_volumes ||= @manager.autosde_client.VolumeApi.volumes_get.map do |volume|
      {
        :name                  => volume.name,
        :size                  => volume.size * 1024 * 1024 * 1024,
        :ems_ref               => volume.uuid,
        :storage_resource_uuid => volume.storage_resource,
        :storage_service_uuid  => volume.service,
        :status                => volume.component_state
      }
    end
  end

  def storage_services
    @storage_services ||= @manager.autosde_client.ServiceApi.services_get.map do |service|
      {
        :name        => service.name,
        :description => service.description,
        :version     => service.version,
        :ems_ref     => service.uuid,
      }
    end
  end

  def physical_storage_families
    @physical_storage_families ||= @manager.autosde_client.SystemTypeApi.system_types_get.map do |system_type|
      {
        :name    => system_type.name,
        :ems_ref => system_type.uuid,
        :version => system_type.version
      }
    end
  end
end
