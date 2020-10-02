# coding: utf-8

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'manageiq/providers/autosde/version'

Gem::Specification.new do |spec|
  spec.name          = "manageiq-providers-autosde"
  spec.version       = ManageIQ::Providers::Autosde::VERSION
  spec.authors       = ["ManageIQ Authors"]

  spec.summary       = "Autosde plugin for ManageIQ"
  spec.description   = "Autosde plugin for ManageIQ"
  spec.homepage      = "https://github.com/ManageIQ/manageiq-providers-autosde"
  spec.license       = "Apache-2.0"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "typhoeus", "~> 1.4"
  spec.add_development_dependency "simplecov"
end
