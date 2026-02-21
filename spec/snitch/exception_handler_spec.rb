# frozen_string_literal: true

require "spec_helper"

RSpec.describe Snitch::ExceptionHandler do
  let(:exception) do
    ex = RuntimeError.new("test error")
    ex.set_backtrace(["/app/models/user.rb:10:in `save!'"])
    ex
  end

  before do
    allow(Snitch::ReportExceptionJob).to receive(:perform_later)
  end

  describe ".handle" do
    context "when enabled" do
      it "creates a new ExceptionRecord" do
        expect { described_class.handle(exception) }
          .to change(Snitch::ExceptionRecord, :count).by(1)
      end

      it "returns the created record" do
        record = described_class.handle(exception)
        expect(record).to be_a(Snitch::ExceptionRecord)
        expect(record.exception_class).to eq("RuntimeError")
        expect(record.message).to eq("test error")
        expect(record.occurrence_count).to eq(1)
      end

      it "sets timestamps on the record" do
        record = described_class.handle(exception)
        expect(record.first_occurred_at).to be_present
        expect(record.last_occurred_at).to be_present
      end

      it "stores backtrace as array" do
        record = described_class.handle(exception)
        expect(record.backtrace).to eq(["/app/models/user.rb:10:in `save!'"])
      end

      it "generates a fingerprint" do
        record = described_class.handle(exception)
        expect(record.fingerprint).to match(/\A[a-f0-9]{64}\z/)
      end

      it "enqueues ReportExceptionJob" do
        expect(Snitch::ReportExceptionJob).to receive(:perform_later).with(kind_of(Integer))
        described_class.handle(exception)
      end
    end

    context "when disabled" do
      before { Snitch.configuration.enabled = false }

      it "does not create a record" do
        expect { described_class.handle(exception) }
          .not_to change(Snitch::ExceptionRecord, :count)
      end

      it "returns nil" do
        expect(described_class.handle(exception)).to be_nil
      end
    end

    context "with ignored exceptions" do
      it "ignores exceptions matching string class names" do
        Snitch.configuration.ignored_exceptions = ["RuntimeError"]
        expect { described_class.handle(exception) }
          .not_to change(Snitch::ExceptionRecord, :count)
      end

      it "ignores exceptions matching class constants" do
        Snitch.configuration.ignored_exceptions = [RuntimeError]
        expect { described_class.handle(exception) }
          .not_to change(Snitch::ExceptionRecord, :count)
      end

      it "does not ignore non-matching exceptions" do
        Snitch.configuration.ignored_exceptions = [ArgumentError]
        expect { described_class.handle(exception) }
          .to change(Snitch::ExceptionRecord, :count).by(1)
      end
    end

    context "deduplication" do
      it "increments occurrence_count for same fingerprint" do
        record1 = described_class.handle(exception)
        record2 = described_class.handle(exception)

        expect(record2.id).to eq(record1.id)
        expect(record2.occurrence_count).to eq(2)
      end

      it "does not create a second record for same fingerprint" do
        described_class.handle(exception)
        expect { described_class.handle(exception) }
          .not_to change(Snitch::ExceptionRecord, :count)
      end

      it "updates last_occurred_at on subsequent occurrences" do
        record = described_class.handle(exception)
        original_last = record.last_occurred_at

        travel_time = record.last_occurred_at + 1.hour
        allow(Time).to receive(:current).and_return(travel_time)

        described_class.handle(exception)
        record.reload

        expect(record.last_occurred_at).to eq(travel_time)
      end

      it "updates message and backtrace on subsequent occurrences" do
        described_class.handle(exception)

        new_ex = RuntimeError.new("updated message")
        new_ex.set_backtrace(["/app/models/user.rb:10:in `save!'"])

        described_class.handle(new_ex)

        record = Snitch::ExceptionRecord.last
        expect(record.message).to eq("updated message")
      end

      it "creates separate records for different fingerprints" do
        ex2 = ArgumentError.new("different")
        ex2.set_backtrace(["/app/controllers/foo.rb:5:in `index'"])

        described_class.handle(exception)
        expect { described_class.handle(ex2) }
          .to change(Snitch::ExceptionRecord, :count).by(1)
      end
    end

    context "when job enqueue fails" do
      before do
        allow(Snitch::ReportExceptionJob).to receive(:perform_later).and_raise("queue down")
      end

      it "still creates the record" do
        expect { described_class.handle(exception) }
          .to change(Snitch::ExceptionRecord, :count).by(1)
      end

      it "does not raise" do
        expect { described_class.handle(exception) }.not_to raise_error
      end
    end
  end
end
