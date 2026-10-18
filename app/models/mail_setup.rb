# Queues Kaisatsu's mail for cybertrain-postal. The web binary only writes the
# message to a spool directory (a file per message); bin/mail_worker.rb, a
# separate program, sends them. They are separate because a binary that links
# OpenSSL (needed for SMTP over TLS) cannot also run the CyberTrain web server
# at this Spinel release: every request fails with "undefined method 'getbyte'".
#
# Web settings (environment):
#
#   KAISATSU_MAIL_FROM       the sender address; when empty, mail is only printed
#                            to the log (development)
#   KAISATSU_MAIL_FROM_NAME  optional display name
#   KAISATSU_MAIL_SPOOL      the spool directory (default storage/mail_spool);
#                            the worker must be given the same one
#
# SMTP settings belong to the worker; see bin/mail_worker.rb. Nothing about the
# recipient or the link is written to the log.
#
# Each message carries valid_for (seconds), the same as its link's lifetime: the
# worker moves a mail that outlived it to failed/ instead of sending it. Delivery
# is at least once, so a mail can arrive twice; every one here is harmless then.
class PostalNotifier < Cybertrain::Kaisatsu::Notifier
  def initialize(delivery, from_address, from_name)
    @delivery = delivery
    @from_address = from_address
    @from_name = from_name
  end

  def send_password_reset(email, link)
    enqueue_text(email, "Reset your password",
                 "Someone asked to reset the password for this account.\n\n" \
                 "Open this link within one hour to choose a new password:\n\n" +
                 link + "\n\n" \
                 "If it was not you, ignore this mail: your password stays the same.\n", 3600)
  end

  def send_email_verification(email, link)
    enqueue_text(email, "Confirm your email address",
                 "Please confirm that this is your email address.\n\n" \
                 "Open this link and press the button within three days:\n\n" +
                 link + "\n\n" \
                 "If you did not create an account, ignore this mail.\n", 259200)
  end

  def send_email_change_link(new_email, link)
    enqueue_text(new_email, "Confirm your new email address",
                 "Someone asked to use this address to sign in to the account.\n\n" \
                 "Open this link and press the button within a day to confirm:\n\n" +
                 link + "\n\n" \
                 "If it was not you, ignore this mail: nothing changes until you confirm.\n", 86400)
  end

  def send_email_change_requested(old_email, new_email)
    enqueue_text(old_email, "A change of your sign-in address was requested",
                 "A change of the sign-in address of this account to another address " \
                 "was requested. It takes effect only when the new address is confirmed.\n\n" \
                 "If it was not you, change your password now.\n", 86400)
  end

  def send_email_changed(old_email, new_email)
    enqueue_text(old_email, "Your sign-in address was changed",
                 "The sign-in address of this account was changed to another address, " \
                 "and every signed-in session was ended.\n\n" \
                 "If it was not you, contact the administrator at once.\n", 86400)
  end

  def send_password_changed(email)
    enqueue_text(email, "Your password was changed",
                 "The password for this account was just changed, and every signed-in " \
                 "session was ended.\n\n" \
                 "If it was not you, reset the password now and check your account.\n", 86400)
  end

  private

  def enqueue_text(to, subject, body, valid_for)
    sender = Cybertrain::Postal::Address.build(@from_address, @from_name)
    message = Cybertrain::Postal::Message.new(sender)
    message.add_to(Cybertrain::Postal::Address.build(to, ""))
    message.subject = subject
    message.text_body = body
    message.valid_for = valid_for
    result = @delivery.deliver(message)
    puts "[kaisatsu] mail not queued (code #{result.code})" unless result.ok?
    nil
  rescue Cybertrain::Postal::InvalidMessage
    puts "[kaisatsu] mail not queued (the message was refused as invalid)"
    nil
  end
end

module MailSetup
  def self.notifier
    from = ENV["KAISATSU_MAIL_FROM"]
    return Cybertrain::Kaisatsu::ConsoleNotifier.new if from.nil? || from.empty?

    name = ENV["KAISATSU_MAIL_FROM_NAME"]
    dir = ENV["KAISATSU_MAIL_SPOOL"]
    spool = Cybertrain::Postal::Spool.new(dir.nil? || dir.empty? ? "storage/mail_spool" : dir)
    delivery = Cybertrain::Postal::QueueDelivery.new(spool)
    PostalNotifier.new(delivery, from, name.nil? ? "" : name)
  end
end
