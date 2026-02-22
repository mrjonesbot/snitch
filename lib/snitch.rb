# frozen_string_literal: true

require "snitch/version"
require "snitch/configuration"
require "snitch/fingerprint"
require "snitch/middleware"
require "snitch/exception_handler"
require "snitch/github_client"
require "snitch/models/event" if defined?(ActiveRecord)
require "snitch/jobs/report_exception_job" if defined?(ActiveJob)
require "snitch/engine" if defined?(Rails)

module Snitch
  class Error < StandardError; end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset!
      @configuration = Configuration.new
    end
  end
end
