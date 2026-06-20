# Cross-Origin Resource Sharing (ADR-0014, webapp issue 01).
#
# The browser SPA (webapp) is served from a different origin than this API, so
# the browser blocks its fetch() calls unless we opt in via CORS. Because the
# refresh token rides in an httpOnly cookie, the web client makes credentialed
# requests (`fetch(..., { credentials: "include" })`), which requires:
#
#   * an explicit allow-list of origins — a wildcard "*" is forbidden when
#     credentials are allowed (browsers reject it); and
#   * `Access-Control-Allow-Credentials: true` (set by `credentials: true`).
#
# The allow-list is environment-configurable via WEB_CORS_ORIGINS (a
# comma-separated list). The default covers local Vite (5173) / Rails (3000)
# dev origins so the webapp works out of the box in development.
#
# The iOS client is native (no Origin header, not subject to CORS), so this is
# purely additive and does not affect the Bearer flow.

web_cors_origins =
  ENV.fetch("WEB_CORS_ORIGINS", "http://localhost:5173,http://localhost:3000")
     .split(",")
     .map(&:strip)
     .reject(&:empty?)

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*web_cors_origins)

    resource "*",
      headers: :any,
      methods: %i[get post put patch delete options head],
      credentials: true,
      expose: %w[Authorization]
  end
end
