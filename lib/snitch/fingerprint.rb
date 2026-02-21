# frozen_string_literal: true

require "digest"

module Snitch
  module Fingerprint
    module_function

    def generate(exception)
      app_line = first_app_backtrace_line(exception)
      source = "#{exception.class.name}:#{app_line}"
      Digest::SHA256.hexdigest(source)
    end

    def first_app_backtrace_line(exception)
      return "" unless exception.backtrace

      exception.backtrace.find { |line| app_line?(line) } || ""
    end

    def app_line?(line)
      !line.include?("/gems/") && !line.include?("ruby/")
    end
  end
end
