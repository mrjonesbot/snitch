require "rails/generators"
require "rails/generators/active_record"

module Snitch
  module Generators
    class UpdateGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      def create_migration_file
        migration_template "add_github_comment_id_to_snitch_errors.rb.erb",
          "db/migrate/add_github_comment_id_to_snitch_errors.rb"
      end
    end
  end
end
