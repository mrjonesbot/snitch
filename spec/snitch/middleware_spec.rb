# frozen_string_literal: true

require "spec_helper"

RSpec.describe Snitch::Middleware do
  let(:app) { ->(env) { [200, {}, ["OK"]] } }
  let(:middleware) { described_class.new(app) }
  let(:env) { { "REQUEST_METHOD" => "GET", "PATH_INFO" => "/test" } }

  describe "#call" do
    context "when the app succeeds" do
      it "returns the app response" do
        result = middleware.call(env)
        expect(result).to eq([200, {}, ["OK"]])
      end

      it "does not call ExceptionHandler" do
        expect(Snitch::ExceptionHandler).not_to receive(:handle)
        middleware.call(env)
      end
    end

    context "when the app raises an exception" do
      let(:error) { RuntimeError.new("something broke") }
      let(:app) { ->(_env) { raise error } }

      before do
        error.set_backtrace(["/app/models/user.rb:10:in `save!'"])
        allow(Snitch::ExceptionHandler).to receive(:handle)
      end

      it "calls ExceptionHandler.handle with the exception and env" do
        expect(Snitch::ExceptionHandler).to receive(:handle).with(error, env)
        expect { middleware.call(env) }.to raise_error(RuntimeError, "something broke")
      end

      it "re-raises the exception" do
        expect { middleware.call(env) }.to raise_error(RuntimeError, "something broke")
      end

      it "re-raises even if handler fails" do
        allow(Snitch::ExceptionHandler).to receive(:handle).and_raise("handler boom")
        expect { middleware.call(env) }.to raise_error(RuntimeError, "something broke")
      end
    end
  end
end
