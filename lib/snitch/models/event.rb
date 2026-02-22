module Snitch
  class Event < ActiveRecord::Base
    self.table_name = "snitch_errors"

    STATUSES = %w[open closed ignored].freeze

    serialize :backtrace, coder: JSON
    serialize :request_params, coder: JSON

    validates :exception_class, presence: true
    validates :fingerprint, presence: true
    validates :status, inclusion: { in: STATUSES }

    scope :by_fingerprint, ->(fp) { where(fingerprint: fp) }
    scope :open, -> { where(status: "open") }
    scope :closed, -> { where(status: "closed") }
    scope :ignored, -> { where(status: "ignored") }
  end
end
