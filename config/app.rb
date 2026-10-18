require "cybertrain/kaisatsu/full"
require "cybertrain/postal"

# Application settings; see Cybertrain::Config for every option.
# Environment variables (PORT, CYBERTRAIN_ENV, CYBERTRAIN_DATABASE,
# CYBERTRAIN_SECRET_KEY_BASE, CYBERTRAIN_HOST, CYBERTRAIN_SESSION_SAME_SITE,
# CYBERTRAIN_SESSION_PARTITIONED) are read before this block runs.
Cybertrain.configure do |c|
  # c.port = 3000
  # c.workers = 1

  # Production marks the session cookie Secure (HTTPS only). Turn it
  # off only if production is really served over plain http://.
  # c.session_secure = false
end
