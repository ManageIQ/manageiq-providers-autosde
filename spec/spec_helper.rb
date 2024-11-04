if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

Dir[Rails.root.join("spec/shared/**/*.rb")].each { |f| require f }
Dir[File.join(__dir__, "support/**/*.rb")].each { |f| require f }

require "manageiq/providers/autosde"

def credentials_autosde_host
  @credentials_autosde_host ||= Rails.application.credentials.appliance_host || "autosde-appliance-host"
end

def credentials_autosde_user
  @credentials_autosde_user ||= Rails.application.credentials.site_manager_user || "autosde"
end

def credentials_autosde_password
  @credentials_autosde_password ||= Rails.application.credentials.site_manager_password || "change_me"
end

VCR.configure do |config|
  config.ignore_hosts 'codeclimate.com' if ENV['CI']
  config.cassette_library_dir = File.join(ManageIQ::Providers::Autosde::Engine.root, 'spec/vcr_cassettes')
  config.default_cassette_options = {:record => :none, :allow_unused_http_interactions => true}
  config.hook_into :webmock

  defaults = {
    "appliance_host"        => credentials_autosde_host,
    "site_manager_user"     => credentials_autosde_user,
    "site_manager_password" => credentials_autosde_password
  }

  # Sanitize the credentials when writing to the cassette to avoid leaking this information.
  defaults.each do |key, value|
    config.define_cassette_placeholder(value) do
      Rails.application.credentials.dig(:autosde, key)
    end
  end
end
