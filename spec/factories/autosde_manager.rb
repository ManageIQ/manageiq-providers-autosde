FactoryBot.define do
  factory :autosde_manager,
          :parent => :ems_physical_infra,
          :class  => "ManageIQ::Providers::Autosde::PhysicalInfraManager" do
  end

  factory :sde_autosde_manager,
          :parent => :ems_physical_infra,
          :class  => "ManageIQ::Providers::Autosde::SdeManager" do
  end

  # naming confention is if we wanna class called Autosde::CamelCase, we name the factory :autosde_camel_case
  # ManageIQ::Providers::Autosde::StorageManager => :autosde_storage_manager
  factory :autosde_storage_manager,
          :parent => :ext_management_system,
          :class  => "ManageIQ::Providers::Autosde::StorageManager" do
    trait :with_autosde_credentials do
      after(:create) do |ems, _|
        ems.authentications << FactoryBot.create(
          :authentication,
          :userid   => VcrSecrets.autosde.site_manager_user,
          :password => VcrSecrets.autosde.site_manager_password
        )
      end
    end
  end
end
