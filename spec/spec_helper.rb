require 'simplecov'
SimpleCov.start

ENV["RAILS_ENV"] ||= 'test'
require 'pathname'
require Pathname.new(__dir__).join("manageiq/config/environment").to_s
require 'rspec/rails'


require 'miq-hash_struct'


Dir[Rails.root.join("spec/shared/**/*.rb")].each { |f| require f }
Dir[File.join(__dir__, "support/**/*.rb")].each { |f| require f }

require "manageiq-providers-autosde"

# Enable this if we want to record new VCR cassettes.
# WebMock.allow_net_connect!
#
RSpec.configure do |config|
  config.add_setting :autosde_appliance_host, :default => '9.151.190.224'
  config.add_setting :autosde_appliance_host_with_auth_token, :default => '9.151.190.206'
  config.add_setting :autosde_site_manager_user, :default => 'autosde'
  config.add_setting :autosde_site_manager_password, :default => 'change_me'
  config.add_setting :autosde_test_system, :default => {
      :management_ip => "9.151.156.155", :name => "my_xiv", :storage_family => "",
      :system_type => {
          :name => "a_line", :short_version => "4", :uuid => "c87d3686-6a36-4358-bc8d-7028d24d60d3",
          :version => "4"}, :uuid => "f09afcc9-53be-4573-8b6f-1e5787d34d05"}

  config.include FactoryBot::Syntax::Methods
  config.before :all do
    ManageIQ::Providers::BaseManager.delete_all
    Zone.delete_all
  end
  config.after :all do
    ManageIQ::Providers::BaseManager.delete_all
    Zone.delete_all
  end
end

VCR.configure do |config|
  # config.ignore_hosts 'codeclimate.com' if ENV['CI']
  config.allow_http_connections_when_no_cassette = true
  config.cassette_library_dir = File.join(ManageIQ::Providers::Autosde::Engine.root, 'spec/vcr_cassettes')
  config.default_cassette_options = {record: :new_episodes}

  # output cassette debug into to console
  config.debug_logger = IO.new STDOUT.fileno

  # without this, cassettes sometimes silently fail to generate
  config.hook_into :webmock

  # mask secret fields from all requests in the cassettes
  %w[username password].each do |field|
    config.filter_sensitive_data "<#{field}>" do |interaction|
      begin
        JSON.parse(interaction.request.body)[field]
      rescue JSON::ParserError
      end
    end
  end
end
