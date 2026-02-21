# frozen_string_literal: true

require "spec_helper"

RSpec.describe Snitch::Fingerprint do
  def build_exception(klass = RuntimeError, message = "test error", backtrace: nil)
    ex = klass.new(message)
    ex.set_backtrace(backtrace || [
      "/app/models/user.rb:10:in `save!'",
      "/gems/activerecord-7.0/lib/active_record/base.rb:100:in `save'",
      "/app/controllers/users_controller.rb:5:in `create'"
    ])
    ex
  end

  describe ".generate" do
    it "returns a SHA256 hex digest" do
      fingerprint = described_class.generate(build_exception)
      expect(fingerprint).to match(/\A[a-f0-9]{64}\z/)
    end

    it "produces consistent fingerprints for the same exception class and app line" do
      ex1 = build_exception(RuntimeError, "first message")
      ex2 = build_exception(RuntimeError, "different message")

      expect(described_class.generate(ex1)).to eq(described_class.generate(ex2))
    end

    it "produces different fingerprints for different exception classes" do
      ex1 = build_exception(RuntimeError, "error")
      ex2 = build_exception(ArgumentError, "error")

      expect(described_class.generate(ex1)).not_to eq(described_class.generate(ex2))
    end

    it "produces different fingerprints for different app lines" do
      ex1 = build_exception(RuntimeError, "error", backtrace: ["/app/models/user.rb:10:in `foo'"])
      ex2 = build_exception(RuntimeError, "error", backtrace: ["/app/models/user.rb:20:in `bar'"])

      expect(described_class.generate(ex1)).not_to eq(described_class.generate(ex2))
    end

    it "handles exceptions with no backtrace" do
      ex = RuntimeError.new("no trace")
      ex.set_backtrace(nil)

      fingerprint = described_class.generate(ex)
      expect(fingerprint).to match(/\A[a-f0-9]{64}\z/)
    end
  end

  describe ".first_app_backtrace_line" do
    it "selects the first non-gem, non-ruby line" do
      ex = build_exception
      line = described_class.first_app_backtrace_line(ex)
      expect(line).to eq("/app/models/user.rb:10:in `save!'")
    end

    it "skips gem lines" do
      ex = build_exception(RuntimeError, "err", backtrace: [
        "/gems/some_gem/lib/thing.rb:5:in `call'",
        "/app/services/foo.rb:12:in `run'"
      ])
      line = described_class.first_app_backtrace_line(ex)
      expect(line).to eq("/app/services/foo.rb:12:in `run'")
    end

    it "skips ruby stdlib lines" do
      ex = build_exception(RuntimeError, "err", backtrace: [
        "/ruby/3.2.0/lib/net/http.rb:5:in `request'",
        "/app/services/api.rb:8:in `fetch'"
      ])
      line = described_class.first_app_backtrace_line(ex)
      expect(line).to eq("/app/services/api.rb:8:in `fetch'")
    end

    it "returns empty string when backtrace is nil" do
      ex = RuntimeError.new("err")
      ex.set_backtrace(nil)
      expect(described_class.first_app_backtrace_line(ex)).to eq("")
    end

    it "returns empty string when all lines are gem/ruby lines" do
      ex = build_exception(RuntimeError, "err", backtrace: [
        "/gems/activerecord/lib/ar.rb:1:in `call'",
        "/ruby/3.2.0/lib/net/http.rb:5:in `request'"
      ])
      expect(described_class.first_app_backtrace_line(ex)).to eq("")
    end
  end
end
