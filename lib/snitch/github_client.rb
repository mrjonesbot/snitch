# frozen_string_literal: true

require "octokit"

module Snitch
  class GitHubClient
    def initialize
      @client = Octokit::Client.new(access_token: Snitch.configuration.github_token)
      @repo = Snitch.configuration.github_repo
    end

    def create_issue(exception_record)
      title = build_title(exception_record)
      body = build_issue_body(exception_record)

      issue = @client.create_issue(@repo, title, body, labels: ["snitch", "bug"])

      {
        number: issue.number,
        url: issue.html_url
      }
    end

    def comment_on_issue(exception_record)
      body = build_comment_body(exception_record)
      @client.add_comment(@repo, exception_record.github_issue_number, body)
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
        #{mention} Please investigate this exception. Analyze the backtrace, identify the root cause, and suggest a fix.
      MARKDOWN
    end

    def build_comment_body(record)
      mention = Snitch.configuration.mention
      <<~MARKDOWN
        ## New Occurrence
        **Total occurrences:** #{record.occurrence_count}
        **Latest occurrence:** #{record.last_occurred_at&.utc}

        ## Latest Request Context
        - **URL:** #{record.request_method} #{record.request_url}
        - **Params:** `#{record.request_params}`

        ---
        #{mention} This exception has occurred again. Please review if the previous analysis still applies.
      MARKDOWN
    end

    def format_backtrace(backtrace)
      return "No backtrace available" if backtrace.nil? || backtrace.empty?

      lines = backtrace.is_a?(Array) ? backtrace : JSON.parse(backtrace) rescue [backtrace.to_s]
      lines.first(20).join("\n")
    end
  end
end
