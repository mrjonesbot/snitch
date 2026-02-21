# frozen_string_literal: true

module Snitch
  class ReportExceptionJob < ActiveJob::Base
    queue_as :default

    retry_on StandardError, wait: :polynomially_longer, attempts: 3

    def perform(event_id)
      record = Event.find_by(id: event_id)
      return unless record

      client = GitHubClient.new

      if record.github_issue_number.present?
        client.comment_on_issue(record)
      else
        result = client.create_issue(record)
        record.update!(
          github_issue_number: result[:number],
          github_issue_url: result[:url]
        )
      end
    end
  end
end
