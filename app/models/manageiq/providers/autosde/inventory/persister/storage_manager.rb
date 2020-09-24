# This clas builds the collections. The parser then adds actual inventory items to the collections.
# Generally, one collection per application-record class.
class ManageIQ::Providers::Autosde::Inventory::Persister::StorageManager < ManageIQ::Providers::Inventory::Persister
  # @return [Hash{Symbol => InventoryRefresh::InventoryCollection}] collections
  attr_reader  :collections

  def initialize_inventory_collections
    # make sure we have an availability zone
    unless AvailabilityZone.where(:name => "AutoSDE", :ems_id => @manager.id).present?
      AvailabilityZone.create(:name => "AutoSDE", :ems_id => @manager.id)
    end

    @availability_zone = AvailabilityZone.where(:name => "AutoSDE", :ems_id => @manager.id).first

    # storage systems
    add_collection(physical_infra, :physical_storages) do |builder|
      builder.add_default_values(:ems_id => ->(persister) { persister.manager.id })
    end

    # storage resources
    add_collection(physical_infra, :storage_resources) do |builder|
      builder.add_default_values(
        :ems_id => ->(persister) { persister.manager.id }
      )
      builder.add_properties(
        :parent_inventory_collections => [:physical_storages]
      )
    end

    # storage services
    add_collection(physical_infra, :storage_services) do |builder|
      builder.add_default_values(
        :ems_id => ->(persister) { persister.manager.id }
      )
    end

    # cloud volumes
    add_collection(physical_infra, :cloud_volumes) do |builder|
      builder.add_default_values(
        :ems_id               => ->(persister) { persister.manager.id },
        :status               => "Available",
        :volume_type          => "ISCSI/FC",
        :bootable             => "false",
        :availability_zone_id => @availability_zone.id
      )
      builder.add_properties(
        :model_class => ManageIQ::Providers::Autosde::StorageManager::CloudVolume
      )
    end

    # storage system types
    add_collection(physical_infra, :physical_storage_families) do |builder|
      builder.add_default_values(
        :ems_id => ->(persister) { persister.manager.id }
      )
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
