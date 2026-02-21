module Snitch
  class Event < ActiveRecord::Base
    self.table_name = "snitch_errors"

    serialize :backtrace, coder: JSON
    serialize :request_params, coder: JSON

    validates :exception_class, presence: true
    validates :fingerprint, presence: true

    scope :by_fingerprint, ->(fp) { where(fingerprint: fp) }
  end
end
