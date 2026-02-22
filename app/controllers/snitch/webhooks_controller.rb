# frozen_string_literal: true

module Snitch
  class WebhooksController < ActionController::Base
    skip_forgery_protection

    def github
      secret = Snitch.configuration.github_webhook_secret
      return head :unauthorized unless secret.present?

      body = request.body.read
      signature = request.headers["X-Hub-Signature-256"]
      expected = "sha256=#{OpenSSL::HMAC.hexdigest("SHA256", secret, body)}"
      return head :unauthorized unless signature.present? && Rack::Utils.secure_compare(expected, signature)

      return head :ok unless request.headers["X-GitHub-Event"] == "issues"

      payload = JSON.parse(body)
      return head :ok unless payload["action"] == "closed"

      issue_number = payload.dig("issue", "number")
      ResolveEventJob.perform_later(issue_number)

      head :ok
    end
  end
end
