FactoryBot.define do


  factory :autosde_manager,
          :parent => :ems_physical_infra,
          :class => "ManageIQ::Providers::Autosde::PhysicalInfraManager" do
  end


  factory :sde_autosde_manager,
          :parent => :ems_physical_infra,
          :class => "ManageIQ::Providers::Autosde::SdeManager" do
  end

  # naming confention is if we wanna class called Autosde::CamelCase, we name the factory :autosde_camel_case
  # ManageIQ::Providers::Autosde::BlockStorageManager => :autosde_block_storage_manager
  factory :autosde_block_storage_manager,
          :parent => :ext_management_system,
          :class => "ManageIQ::Providers::Autosde::BlockStorageManager" do
  end

end

