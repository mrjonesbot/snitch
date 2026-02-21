require "rails/generators"
require "rails/generators/active_record"

module Snitch
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("templates", __dir__)

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
