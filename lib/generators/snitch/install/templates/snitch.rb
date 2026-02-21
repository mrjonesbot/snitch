Snitch.configure do |config|
  # Required: GitHub personal access token
  config.github_token = ENV["SNITCH_GITHUB_TOKEN"]

  # Required: GitHub repository (owner/repo format)
  config.github_repo = "owner/repo"

  # Who to @mention in GitHub issues (default: "@claude")
  # config.mention = "@claude"

  # Enable/disable Snitch (default: true)
  # config.enabled = Rails.env.production?

  # Exceptions to ignore (default: RecordNotFound, RoutingError)
  # config.ignored_exceptions += [CustomError]
end
