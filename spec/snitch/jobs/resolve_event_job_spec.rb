# frozen_string_literal: true

require "spec_helper"

RSpec.describe Snitch::ResolveEventJob do
  let(:event) do
    Snitch::Event.create!(
      exception_class: "RuntimeError",
      message: "something broke",
      backtrace: ["/app/models/user.rb:10:in `save!'"],
      fingerprint: "abc123def456",
      occurrence_count: 1,
      github_issue_number: 42,
      first_occurred_at: Time.current,
      last_occurred_at: Time.current
    )
  end

  describe "#perform" do
    it "closes an open event matching the issue number" do
      event
      described_class.new.perform(42)
      expect(event.reload.status).to eq("closed")
    end

    it "does nothing when no matching event exists" do
      expect {
        described_class.new.perform(999)
      }.not_to raise_error
    end

    it "does nothing when matching event is already closed" do
      event.update!(status: "closed")
      described_class.new.perform(42)
      expect(event.reload.status).to eq("closed")
    end

    it "does nothing when matching event is ignored" do
      event.update!(status: "ignored")
      described_class.new.perform(42)
      expect(event.reload.status).to eq("ignored")
    end
  end
end
