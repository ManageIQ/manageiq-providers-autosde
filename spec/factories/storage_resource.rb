FactoryBot.define do
  factory :autosde_storage_resource,
          :parent => :storage_resource,
          :class  => "ManageIQ::Providers::Autosde::StorageManager::StorageResource"
end
