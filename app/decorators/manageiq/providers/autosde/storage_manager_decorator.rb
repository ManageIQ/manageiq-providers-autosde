module ManageIQ::Providers
  class Autosde::StorageManagerDecorator < MiqDecorator
    def self.fonticon
      'pficon pficon-server'
    end

    def fileicon
      "svg/vendor-#{image_name}.svg"
    end

    def quadicon
      icon = {
        :top_left     => {
          :text    => t = cloud_volumes.size,
          :tooltip => n_("%{number} Cloud Volume", "%{number} Cloud Volumes", t) % {:number => t}
        },
        :top_right    => {
          :text    => t = storage_resources.size,
          :tooltip => n_("%{number} Storage Pool", "%{number} Storage Pools", t) % {:number => t}
        },
        :bottom_left  => {
          :fileicon => fileicon,
          :tooltip  => ui_lookup(:model => type)
        },
        :bottom_right => QuadiconHelper.provider_status(authentication_status, enabled?)
      }

      icon[:middle] = QuadiconHelper::POLICY_SHIELD if get_policies.present?
      icon
    end
  end
end
