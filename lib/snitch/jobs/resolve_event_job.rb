# frozen_string_literal: true

module Snitch
  class ResolveEventJob < ActiveJob::Base
    queue_as :default

    retry_on StandardError, wait: :polynomially_later, attempts: 3

    def perform(github_issue_number)
      Event.where(github_issue_number: github_issue_number, status: "open")
           .update_all(status: "closed")
    end
  end
end
