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

  # The bearer token is only known from the response of the login (token-auth) call,
  # so it cannot be a static secret. Scrub every token seen in a login response from
  # the recorded interactions (login responses always precede the requests using them).
  bearer_tokens = []
  config.before_record do |interaction|
    if interaction.request.uri.end_with?("/token-auth")
      token = JSON.parse(interaction.response.body)["token"] rescue nil
      bearer_tokens << token if token.present? && token != "BEARER_TOKEN"
    end

    bearer_tokens.each do |token|
      interaction.response.body = interaction.response.body.gsub(token, "BEARER_TOKEN")
      interaction.request.headers["Authorization"] = interaction.request.headers["Authorization"].map { |v| v.gsub(token, "BEARER_TOKEN") } if interaction.request.headers["Authorization"]
    end
  end
end
