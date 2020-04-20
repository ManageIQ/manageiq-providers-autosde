FactoryBot.define do


  factory :autosde_manager,
          :parent  => :ems_physical_infra,
          :class   => "ManageIQ::Providers::Autosde::PhysicalInfraManager" do
  end
end

