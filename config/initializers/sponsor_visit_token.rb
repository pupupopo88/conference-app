Rails.application.config.x.sponsor_visit_token_secret = ENV.fetch("SPONSOR_VISIT_TOKEN_SECRET") do
  if Rails.env.production?
    raise "SPONSOR_VISIT_TOKEN_SECRET is required in production"
  end

  "development-and-test-sponsor-visit-token-secret"
end
