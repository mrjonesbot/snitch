# frozen_string_literal: true

require "spec_helper"
require "action_controller"
require_relative "../../app/controllers/snitch/webhooks_controller"

RSpec.describe Snitch::WebhooksController do
  let(:secret) { "test-webhook-secret" }
  let(:issue_number) { 42 }
  let(:payload) do
    { action: "closed", issue: { number: issue_number } }.to_json
  end

  let(:app) { described_class.action(:github) }

  def signature_for(body, key)
    "sha256=#{OpenSSL::HMAC.hexdigest("SHA256", key, body)}"
  end

  def rack_env(body: payload, event: "issues", signature: signature_for(payload, secret))
    env = Rack::MockRequest.env_for(
      "/snitches/webhooks/github",
      method: "POST",
      input: body,
      "CONTENT_TYPE" => "application/json"
    )
    env["HTTP_X_HUB_SIGNATURE_256"] = signature if signature
    env["HTTP_X_GITHUB_EVENT"] = event
    env
  end

  before do
    Snitch.configuration.github_webhook_secret = secret
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
  end

  def enqueued_jobs
    ActiveJob::Base.queue_adapter.enqueued_jobs
  end

  describe "POST #github" do
    context "with a valid closed issue webhook" do
      it "enqueues ResolveEventJob with the issue number" do
        app.call(rack_env)

        jobs = enqueued_jobs.select { |j| j["job_class"] == "Snitch::ResolveEventJob" }
        expect(jobs.length).to eq(1)
        expect(jobs.first["arguments"]).to eq([issue_number])
      end

      it "returns 200" do
        status, = app.call(rack_env)
        expect(status).to eq(200)
      end
    end

    context "when webhook secret is not configured" do
      before { Snitch.configuration.github_webhook_secret = nil }

      it "returns 401" do
        status, = app.call(rack_env)
        expect(status).to eq(401)
      end
    end

    context "when signature is missing" do
      it "returns 401" do
        status, = app.call(rack_env(signature: nil))
        expect(status).to eq(401)
      end
    end

    context "when signature is invalid" do
      it "returns 401" do
        status, = app.call(rack_env(signature: "sha256=invalid"))
        expect(status).to eq(401)
      end
    end

    context "when event is not 'issues'" do
      it "returns 200 without enqueuing a job" do
        status, = app.call(rack_env(event: "push"))
        expect(status).to eq(200)
        expect(enqueued_jobs).to be_empty
      end
    end

    context "when action is not 'closed'" do
      let(:opened_payload) { { action: "opened", issue: { number: issue_number } }.to_json }

      it "returns 200 without enqueuing a job" do
        status, = app.call(rack_env(body: opened_payload, signature: signature_for(opened_payload, secret)))
        expect(status).to eq(200)
        expect(enqueued_jobs).to be_empty
      end
    end
  end
end
