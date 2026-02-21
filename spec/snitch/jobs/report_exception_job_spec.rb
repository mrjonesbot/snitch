# frozen_string_literal: true

require "spec_helper"

RSpec.describe Snitch::ReportExceptionJob do
  let(:record) do
    Snitch::ExceptionRecord.create!(
      exception_class: "RuntimeError",
      message: "something broke",
      backtrace: ["/app/models/user.rb:10:in `save!'"],
      fingerprint: "abc123def456",
      occurrence_count: 1,
      first_occurred_at: Time.current,
      last_occurred_at: Time.current
    )
  end

  let(:github_client) { instance_double(Snitch::GitHubClient) }

  before do
    allow(Snitch::GitHubClient).to receive(:new).and_return(github_client)
  end

  describe "#perform" do
    context "when record has no github_issue_number (new issue flow)" do
      it "creates a new GitHub issue" do
        expect(github_client).to receive(:create_issue).with(record).and_return(
          { number: 42, url: "https://github.com/owner/repo/issues/42" }
        )

        described_class.new.perform(record.id)
      end

      it "updates the record with the issue number and URL" do
        allow(github_client).to receive(:create_issue).and_return(
          { number: 42, url: "https://github.com/owner/repo/issues/42" }
        )

        described_class.new.perform(record.id)
        record.reload

        expect(record.github_issue_number).to eq(42)
        expect(record.github_issue_url).to eq("https://github.com/owner/repo/issues/42")
      end
    end

    context "when record already has github_issue_number (comment flow)" do
      before do
        record.update!(
          github_issue_number: 42,
          github_issue_url: "https://github.com/owner/repo/issues/42"
        )
      end

      it "comments on the existing issue instead of creating a new one" do
        expect(github_client).to receive(:comment_on_issue).with(record)
        expect(github_client).not_to receive(:create_issue)

        described_class.new.perform(record.id)
      end
    end

    context "when record does not exist" do
      it "returns without doing anything" do
        expect(github_client).not_to receive(:create_issue)
        expect(github_client).not_to receive(:comment_on_issue)

        described_class.new.perform(-1)
      end
    end
  end
end
