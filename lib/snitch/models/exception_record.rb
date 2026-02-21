module Snitch
  class ExceptionRecord < ActiveRecord::Base
    self.table_name = "snitch_exception_records"

    serialize :backtrace, coder: JSON
    serialize :request_params, coder: JSON

    validates :exception_class, presence: true
    validates :fingerprint, presence: true

    scope :by_fingerprint, ->(fp) { where(fingerprint: fp) }
  end
end
