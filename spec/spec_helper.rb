# frozen_string_literal: true

require "active_record"
require "active_job"
require "action_dispatch"
require "webmock/rspec"
require "snitch"
require "snitch/models/exception_record"
require "snitch/jobs/report_exception_job"

# Set up in-memory SQLite database
ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: ":memory:"
)

ActiveRecord::Schema.define do
  create_table :snitch_exception_records, force: true do |t|
    t.string :exception_class, null: false
    t.text :message
    t.text :backtrace
    t.string :fingerprint, null: false
    t.string :request_url
    t.string :request_method
    t.text :request_params
    t.integer :occurrence_count, default: 1
    t.integer :github_issue_number
    t.string :github_issue_url
    t.datetime :first_occurred_at
    t.datetime :last_occurred_at
    t.timestamps
  end

  add_index :snitch_exception_records, :fingerprint, unique: true
  add_index :snitch_exception_records, :exception_class
end

# Configure ActiveJob for testing
ActiveJob::Base.queue_adapter = :test
ActiveJob::Base.logger = Logger.new(nil)

# Disable external requests
WebMock.disable_net_connect!

RSpec.configure do |config|
  config.before(:each) do
    Snitch.reset!
    Snitch.configure do |c|
      c.github_token = "test-token"
      c.github_repo = "owner/repo"
      c.enabled = true
    end
  end

  config.after(:each) do
    Snitch::ExceptionRecord.delete_all
  end

  config.order = :random
end
