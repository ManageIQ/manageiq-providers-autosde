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
  config.ignore_hosts 'codeclimate.com' if ENV['CI']
  config.cassette_library_dir = File.join(ManageIQ::Providers::Autosde::Engine.root, 'spec/vcr_cassettes')
  config.default_cassette_options={:record => :once }
  config.hook_into :webmock  # without this, cassettes silently fail to generate
  %w[client_id secret_id username password].each do |field|
    config.filter_sensitive_data "<#{field}>" do |interaction|
      begin
        JSON.parse(interaction.request.body)[field]
      rescue JSON::ParserError
      end
    end
  end
end
