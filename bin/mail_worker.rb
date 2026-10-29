# Sends the mail that the web application queued (see app/models/mail_setup.rb).
# A separate program on purpose: it links OpenSSL for SMTP over TLS, which the
# web binary cannot.
#
#   cybertrain spin run mail_worker            run until stopped
#   cybertrain spin run mail_worker -- --once  one pass, then exit
#
# Settings (environment):
#
#   KAISATSU_SMTP_HOST       the SMTP server (required)
#   KAISATSU_SMTP_PORT       587 by default
#   KAISATSU_SMTP_TLS        unset: STARTTLS is required, and never downgraded to
#                            plain text if it fails
#                            "implicit": TLS from the start (port 465)
#                            "optional": STARTTLS when offered, plain text otherwise;
#                            for a relay on the same machine (a mail catcher in
#                            development). The password is only ever sent over
#                            TLS or to a loopback address.
#   KAISATSU_SMTP_USER / KAISATSU_SMTP_PASSWORD
#   KAISATSU_HELO            the name given in EHLO (default localhost)
#   KAISATSU_MAIL_SPOOL      the spool directory (default storage/mail_spool)
#
# On macOS with Homebrew, build with
#   export LIBRARY_PATH=$(brew --prefix openssl@3)/lib CPATH=$(brew --prefix openssl@3)/include
require "cybertrain/postal"
require "cybertrain/postal/smtp_factory"

def setting(name, fallback)
  value = ENV[name]
  value.nil? || value.empty? ? fallback : value
end

host = setting("KAISATSU_SMTP_HOST", "")
if host.empty?
  puts "mail_worker: KAISATSU_SMTP_HOST is not set"
  exit(1)
end

tls = setting("KAISATSU_SMTP_TLS", "")
factory = Cybertrain::Postal::SmtpDeliveryFactory.new(
  host,
  setting("KAISATSU_SMTP_PORT", "587").to_i,
  tls == "implicit",
  setting("KAISATSU_HELO", "localhost")
)
factory.require_tls = false if tls == "optional"
user = setting("KAISATSU_SMTP_USER", "")
factory.credentials(user, setting("KAISATSU_SMTP_PASSWORD", "")) unless user.empty?

spool = Cybertrain::Postal::Spool.new(setting("KAISATSU_MAIL_SPOOL", "storage/mail_spool"))
policy = Cybertrain::Postal::RetryPolicy.new(8, 30.0, 3600.0)
runner = Cybertrain::Postal::SpoolRunner.new(spool, factory, policy)
once = ARGV.include?("--once")

# failed/ can hold a reset link, so it is emptied after a week, once a day.
day = 24 * 3600
last_purge = 0

running = true
while running
  now = Time.now.to_i
  spool.recover_stale(now, 600)
  if now - last_purge >= day
    spool.purge_failed(now, 7 * day)
    last_purge = now
  end
  report = runner.run_once(now)
  if report.delivered + report.deferred + report.failed > 0
    puts "[mail_worker] delivered=#{report.delivered} deferred=#{report.deferred} failed=#{report.failed} refused=#{report.refused}"
    STDOUT.flush
  end
  if once
    running = false
  else
    sleep(5)
  end
end
