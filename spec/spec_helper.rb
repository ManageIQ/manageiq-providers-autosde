if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

Dir[Rails.root.join("spec/shared/**/*.rb")].each { |f| require f }
Dir[File.join(__dir__, "support/**/*.rb")].each { |f| require f }

require "manageiq/providers/autosde"

VCR.configure do |config|
  config.ignore_hosts 'codeclimate.com' if ENV['CI']
  config.cassette_library_dir = File.join(ManageIQ::Providers::Autosde::Engine.root, 'spec/vcr_cassettes')
  config.default_cassette_options = {:record => :none, :allow_unused_http_interactions => true}
  config.hook_into :webmock

  VcrSecrets.define_all_cassette_placeholders(config, :autosde)
end
