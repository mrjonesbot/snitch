# frozen_string_literal: true

require "octokit"

module Snitch
  class GitHubClient
    def initialize
      @client = Octokit::Client.new(access_token: Snitch.configuration.github_token)
      @repo = Snitch.configuration.github_repo
    end

    def create_issue(event)
      title = build_title(event)
      body = build_issue_body(event)

      issue = @client.create_issue(@repo, title, body, labels: ["snitch", "bug"])

      {
        number: issue.number,
        url: issue.html_url
      }
    end

    def comment_on_issue(event)
      body = build_comment_body(event)

      if event.github_comment_id.present?
        @client.update_comment(@repo, event.github_comment_id, body)
      else
        comment = @client.add_comment(@repo, event.github_issue_number, body)
        event.update!(github_comment_id: comment.id)
      end

      reopen_issue(event) if event.status == "open"
    end

    def reopen_issue(event)
      @client.update_issue(@repo, event.github_issue_number, state: "open")
    end

    private

    def build_title(record)
      msg = record.message.to_s.truncate(100)
      "[Snitch] #{record.exception_class}: #{msg}"
    end

    def build_issue_body(record)
      mention = Snitch.configuration.mention
      <<~MARKDOWN
        ## Exception Details
        **Class:** `#{record.exception_class}`
        **Message:** #{record.message}
        **Occurrences:** #{record.occurrence_count}
        **First seen:** #{record.first_occurred_at&.utc}

        ## Backtrace
        ```ruby
        #{format_backtrace(record.backtrace)}
        ```

        ## Request Context
        - **URL:** #{record.request_method} #{record.request_url}
        - **Params:** `#{record.request_params}`

        ---
        #{mention} Please investigate this exception. Analyze the backtrace, identify the root cause, fix the issue, and open a pull request with your changes.
      MARKDOWN
    end

    def build_comment_body(record)
      <<~MARKDOWN
        **Occurrences:** #{record.occurrence_count} | **Latest:** #{record.last_occurred_at&.utc}
      MARKDOWN
    end

    def format_backtrace(backtrace)
      return "No backtrace available" if backtrace.nil? || backtrace.empty?

      lines = backtrace.is_a?(Array) ? backtrace : JSON.parse(backtrace) rescue [backtrace.to_s]
      lines.first(20).join("\n")
    end
  end
end
