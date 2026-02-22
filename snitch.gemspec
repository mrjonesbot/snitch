# frozen_string_literal: true

require_relative "lib/snitch/version"

Gem::Specification.new do |spec|
  spec.name = "snitch-rails"
  spec.version = Snitch::VERSION
  spec.authors = ["RiseKit"]
  spec.summary = "Automatic GitHub issue creation for unhandled Rails exceptions."
  spec.description = "Snitch catches unhandled exceptions in your Rails app and opens GitHub issues with full context."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.files = Dir["app/**/*", "config/**/*", "lib/**/*", "LICENSE.txt", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 7.0"
  spec.add_dependency "octokit", "~> 9.0"
  spec.add_dependency "tailwindcss-ruby", "~> 4.0"

  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "factory_bot_rails"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "faraday-retry"
end
