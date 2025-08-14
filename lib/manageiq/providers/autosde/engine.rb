module ManageIQ
  module Providers
    module Autosde
      class Engine < ::Rails::Engine
        isolate_namespace ManageIQ::Providers::Autosde

        config.autoload_paths << root.join('lib')


        def self.vmdb_plugin?
          true
        end

        def self.plugin_name
          _('Autosde Provider')
        end
      end
    end
  end
end
