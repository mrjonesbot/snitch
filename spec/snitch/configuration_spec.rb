# frozen_string_literal: true

require "spec_helper"

RSpec.describe Snitch::Configuration do
  describe "defaults" do
    subject(:config) { described_class.new }

    it "has nil github_token by default" do
      expect(config.github_token).to be_nil
    end

    it "has nil github_repo by default" do
      expect(config.github_repo).to be_nil
    end

    it "defaults mention to @claude" do
      expect(config.mention).to eq("@claude")
    end

    it "defaults enabled to true" do
      expect(config.enabled).to be true
    end

    it "has default ignored exceptions" do
      expect(config.ignored_exceptions).to contain_exactly(
        "ActiveRecord::RecordNotFound",
        "ActionController::RoutingError"
      )
    end
  end

  describe "Snitch.configure" do
    it "yields configuration for customization" do
      Snitch.configure do |config|
        config.github_token = "my-token"
        config.github_repo = "user/myrepo"
        config.mention = "@team"
        config.enabled = false
      end

      config = Snitch.configuration
      expect(config.github_token).to eq("my-token")
      expect(config.github_repo).to eq("user/myrepo")
      expect(config.mention).to eq("@team")
      expect(config.enabled).to be false
    end

    it "allows adding custom ignored exceptions" do
      Snitch.configure do |config|
        config.ignored_exceptions += [RuntimeError]
      end

      expect(Snitch.configuration.ignored_exceptions).to include(RuntimeError)
    end
  end

  describe "Snitch.reset!" do
    it "restores defaults" do
      Snitch.configure { |c| c.github_token = "changed" }
      Snitch.reset!
      expect(Snitch.configuration.github_token).to be_nil
    end
  end
end
