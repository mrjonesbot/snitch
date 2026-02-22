# frozen_string_literal: true

require "spec_helper"

RSpec.describe Snitch::GitHubClient do
  let(:client) { described_class.new }
  let(:record) do
    Snitch::Event.create!(
      exception_class: "RuntimeError",
      message: "something broke",
      backtrace: ["/app/models/user.rb:10:in `save!'"],
      fingerprint: "abc123def456",
      occurrence_count: 1,
      first_occurred_at: Time.current,
      last_occurred_at: Time.current,
      request_url: "https://example.com/users",
      request_method: "POST",
      request_params: { "user" => { "name" => "Test" } }
    )
  end

  describe "#create_issue" do
    let(:github_response) do
      OpenStruct.new(number: 42, html_url: "https://github.com/owner/repo/issues/42")
    end

    before do
      stub_request(:post, "https://api.github.com/repos/owner/repo/issues")
        .to_return(
          status: 201,
          headers: { "Content-Type" => "application/json" },
          body: { number: 42, html_url: "https://github.com/owner/repo/issues/42" }.to_json
        )
    end

    it "creates a GitHub issue" do
      result = client.create_issue(record)
      expect(result[:number]).to eq(42)
      expect(result[:url]).to eq("https://github.com/owner/repo/issues/42")
    end

    it "includes the exception class in the title" do
      stub = stub_request(:post, "https://api.github.com/repos/owner/repo/issues")
        .with(body: hash_including("title" => a_string_matching(/RuntimeError/)))
        .to_return(
          status: 201,
          headers: { "Content-Type" => "application/json" },
          body: { number: 42, html_url: "https://github.com/owner/repo/issues/42" }.to_json
        )

      client.create_issue(record)
      expect(stub).to have_been_requested
    end

    it "includes the mention in the body" do
      stub = stub_request(:post, "https://api.github.com/repos/owner/repo/issues")
        .with(body: hash_including("body" => a_string_matching(/@claude/)))
        .to_return(
          status: 201,
          headers: { "Content-Type" => "application/json" },
          body: { number: 42, html_url: "https://github.com/owner/repo/issues/42" }.to_json
        )

      client.create_issue(record)
      expect(stub).to have_been_requested
    end

    it "includes backtrace in the body" do
      stub = stub_request(:post, "https://api.github.com/repos/owner/repo/issues")
        .with(body: hash_including("body" => a_string_matching(/user\.rb/)))
        .to_return(
          status: 201,
          headers: { "Content-Type" => "application/json" },
          body: { number: 42, html_url: "https://github.com/owner/repo/issues/42" }.to_json
        )

      client.create_issue(record)
      expect(stub).to have_been_requested
    end

    it "includes request context in the body" do
      stub = stub_request(:post, "https://api.github.com/repos/owner/repo/issues")
        .with(body: hash_including("body" => a_string_matching(/POST.*example\.com/)))
        .to_return(
          status: 201,
          headers: { "Content-Type" => "application/json" },
          body: { number: 42, html_url: "https://github.com/owner/repo/issues/42" }.to_json
        )

      client.create_issue(record)
      expect(stub).to have_been_requested
    end

    it "applies snitch and bug labels" do
      stub = stub_request(:post, "https://api.github.com/repos/owner/repo/issues")
        .with(body: hash_including("labels" => ["snitch", "bug"]))
        .to_return(
          status: 201,
          headers: { "Content-Type" => "application/json" },
          body: { number: 42, html_url: "https://github.com/owner/repo/issues/42" }.to_json
        )

      client.create_issue(record)
      expect(stub).to have_been_requested
    end

    it "uses a custom mention when configured" do
      Snitch.configuration.mention = "@devteam"

      stub = stub_request(:post, "https://api.github.com/repos/owner/repo/issues")
        .with(body: hash_including("body" => a_string_matching(/@devteam/)))
        .to_return(
          status: 201,
          headers: { "Content-Type" => "application/json" },
          body: { number: 42, html_url: "https://github.com/owner/repo/issues/42" }.to_json
        )

      client.create_issue(record)
      expect(stub).to have_been_requested
    end
  end

  describe "#comment_on_issue" do
    let(:record_with_issue) do
      r = record
      r.update!(github_issue_number: 42, github_issue_url: "https://github.com/owner/repo/issues/42", occurrence_count: 3)
      r
    end

    before do
      stub_request(:post, "https://api.github.com/repos/owner/repo/issues/42/comments")
        .to_return(
          status: 201,
          headers: { "Content-Type" => "application/json" },
          body: { id: 1 }.to_json
        )
      stub_request(:patch, "https://api.github.com/repos/owner/repo/issues/42")
        .to_return(
          status: 200,
          headers: { "Content-Type" => "application/json" },
          body: { number: 42, state: "open" }.to_json
        )
    end

    it "posts a comment on the existing issue" do
      stub = stub_request(:post, "https://api.github.com/repos/owner/repo/issues/42/comments")
        .to_return(
          status: 201,
          headers: { "Content-Type" => "application/json" },
          body: { id: 1 }.to_json
        )

      client.comment_on_issue(record_with_issue)
      expect(stub).to have_been_requested
    end

    it "includes occurrence count in the comment" do
      stub = stub_request(:post, "https://api.github.com/repos/owner/repo/issues/42/comments")
        .with(body: hash_including("body" => a_string_matching(/3/)))
        .to_return(
          status: 201,
          headers: { "Content-Type" => "application/json" },
          body: { id: 1 }.to_json
        )

      client.comment_on_issue(record_with_issue)
      expect(stub).to have_been_requested
    end

    it "reopens the GitHub issue when the event was reopened" do
      record_with_issue.update!(status: "open")

      stub_request(:post, "https://api.github.com/repos/owner/repo/issues/42/comments")
        .to_return(
          status: 201,
          headers: { "Content-Type" => "application/json" },
          body: { id: 1 }.to_json
        )
      reopen_stub = stub_request(:patch, "https://api.github.com/repos/owner/repo/issues/42")
        .with(body: hash_including("state" => "open"))
        .to_return(
          status: 200,
          headers: { "Content-Type" => "application/json" },
          body: { number: 42, state: "open" }.to_json
        )

      client.comment_on_issue(record_with_issue)
      expect(reopen_stub).to have_been_requested
    end

    it "does not reopen the GitHub issue when the event is not open" do
      record_with_issue.update!(status: "closed")

      stub_request(:post, "https://api.github.com/repos/owner/repo/issues/42/comments")
        .to_return(
          status: 201,
          headers: { "Content-Type" => "application/json" },
          body: { id: 1 }.to_json
        )

      client.comment_on_issue(record_with_issue)

      expect(WebMock).not_to have_requested(:patch, "https://api.github.com/repos/owner/repo/issues/42")
    end

    it "includes mention in the comment" do
      stub = stub_request(:post, "https://api.github.com/repos/owner/repo/issues/42/comments")
        .with(body: hash_including("body" => a_string_matching(/@claude/)))
        .to_return(
          status: 201,
          headers: { "Content-Type" => "application/json" },
          body: { id: 1 }.to_json
        )

      client.comment_on_issue(record_with_issue)
      expect(stub).to have_been_requested
    end
  end
end
