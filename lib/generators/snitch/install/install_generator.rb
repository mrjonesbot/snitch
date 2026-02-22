require "rails/generators"
require "rails/generators/active_record"

module Snitch
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      def ensure_gemfile_require
        gemfile = File.join(destination_root, "Gemfile")
        return unless File.exist?(gemfile)

        content = File.read(gemfile)

        # Skip if require: "snitch" is already present
        return if content.match?(/gem\s+["']snitch-rails["'].*require:\s*["']snitch["']/)

        # Add require: "snitch" to the existing gem line
        if content.match?(/gem\s+["']snitch-rails["']/)
          gsub_file "Gemfile",
            /(gem\s+["']snitch-rails["'])/,
            '\1, require: "snitch"'
        end
      end

      def create_migration_file
        migration_template "create_snitch_errors.rb.erb",
          "db/migrate/create_snitch_errors.rb"
      end

      def create_initializer
        template "snitch.rb", "config/initializers/snitch.rb"
      end
    end
  end
end
