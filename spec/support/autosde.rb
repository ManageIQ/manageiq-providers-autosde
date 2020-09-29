RSpec.configure do |config|
  config.add_setting :autosde_appliance_host, :default => '9.151.190.224'
  config.add_setting :autosde_appliance_host_with_auth_token, :default => '9.151.190.206'
  config.add_setting :autosde_site_manager_user, :default => 'autosde'
  config.add_setting :autosde_site_manager_password, :default => 'change_me'

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
  config.ignore_hosts 'codeclimate.com' if ENV['CI']
  config.cassette_library_dir = File.join(ManageIQ::Providers::Autosde::Engine.root, 'spec/vcr_cassettes')
  config.default_cassette_options = {record: :none, allow_unused_http_interactions: true}

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

