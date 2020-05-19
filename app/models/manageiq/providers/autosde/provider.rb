class ManageIQ::Providers::Autosde::Provider < ::Provider
  has_one :ems_sde_manager,
          :foreign_key => "provider_id",
          :class_name  => "ManageIQ::Providers::Autosde::BlockStorageManager",
          :autosave    => true

  validates :name, :presence => true, :uniqueness => true
end
