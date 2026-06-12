FactoryBot.define do
  factory :autosde_storage_service,
          :parent => :storage_service,
          :class  => "ManageIQ::Providers::Autosde::StorageManager::StorageService"
end
