# frozen_string_literal: true

module Snitch
  class Configuration
    attr_accessor :github_token, :github_repo, :mention, :enabled, :ignored_exceptions

    def initialize
      @github_token = nil
      @github_repo = nil
      @mention = "@claude"
      @enabled = true
      @ignored_exceptions = [
        "ActiveRecord::RecordNotFound",
        "ActionController::RoutingError"
      ]
    end
  end
end
