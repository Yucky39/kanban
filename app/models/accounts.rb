# Where Kaisatsu finds accounts: the users table.
class AccountDirectory < Cybertrain::Kaisatsu::UserDirectory
  def credentials_for(login)
    user = User.find_by(email: login)
    return Cybertrain::Kaisatsu::Credentials.missing if user.nil?
    Cybertrain::Kaisatsu::Credentials.new(true, user.id.to_s, user.password_hash)
  end

  def email_for(user_id)
    user = User.find_by(id: user_id.to_i)
    user.nil? ? "" : user.email
  end

  def email_verified?(user_id)
    user = User.find_by(id: user_id.to_i)
    !user.nil? && !user.email_verified_at.nil?
  end

  def mark_email_verified(user_id)
    user = User.find_by(id: user_id.to_i)
    return nil if user.nil?
    user.email_verified_at = Time.now.to_i
    user.save
    nil
  end

  def email_taken?(email, except_user_id)
    other = User.where(email: email).first
    !other.nil? && other.id.to_s != except_user_id
  end

  def begin_email_change(user_id, new_email)
    user = User.find_by(id: user_id.to_i)
    return nil if user.nil?
    user.pending_email = new_email
    user.save
    nil
  end

  def pending_email(user_id)
    user = User.find_by(id: user_id.to_i)
    user.nil? ? "" : user.pending_email.to_s
  end

  # The unique index on users.email is the last word: if the address was
  # taken in the meantime, the save fails and nothing changes.
  def apply_email_change(user_id)
    user = User.find_by(id: user_id.to_i)
    return false if user.nil?
    pending = user.pending_email.to_s
    return false if pending.empty? || email_taken?(pending, user_id)
    user.email = pending
    user.pending_email = ""
    user.email_verified_at = Time.now.to_i
    user.save
  rescue Cybertrain::DB::Error
    false
  end

  def store_password_hash(user_id, password_hash)
    user = User.find_by(id: user_id.to_i)
    return nil if user.nil?
    user.password_hash = password_hash
    user.save
    nil
  end
end

# Sends the mail on its own thread, so a slow mail server neither holds a
# database connection nor shows (through response time) whether an account
# exists. The thread is started from a method (spikes/NOTES.md rule 21).
class BackgroundNotifier < Cybertrain::Kaisatsu::Notifier
  def initialize(inner)
    @inner = inner
  end

  def send_password_reset(email, link)
    spawn_reset(@inner, email, link)
  end

  def send_email_verification(email, link)
    spawn_verification(@inner, email, link)
  end

  def send_email_change_link(new_email, link)
    spawn_change_link(@inner, new_email, link)
  end

  def send_email_change_requested(old_email, new_email)
    spawn_change_requested(@inner, old_email, new_email)
  end

  def send_email_changed(old_email, new_email)
    spawn_changed_notice(@inner, old_email, new_email)
  end

  def send_password_changed(email)
    spawn_changed(@inner, email)
  end

  private

  def spawn_change_link(inner, new_email, link)
    Thread.new { inner.send_email_change_link(new_email, link) }
    nil
  end

  def spawn_change_requested(inner, old_email, new_email)
    Thread.new { inner.send_email_change_requested(old_email, new_email) }
    nil
  end

  def spawn_changed_notice(inner, old_email, new_email)
    Thread.new { inner.send_email_changed(old_email, new_email) }
    nil
  end

  def spawn_verification(inner, email, link)
    Thread.new { inner.send_email_verification(email, link) }
    nil
  end

  def spawn_reset(inner, email, link)
    Thread.new { inner.send_password_reset(email, link) }
    nil
  end

  def spawn_changed(inner, email)
    Thread.new { inner.send_password_changed(email) }
    nil
  end
end

# The application's Kaisatsu objects, built on first use with every
# argument bound to a local first (spikes/NOTES.md rule 58).
module Accounts
  @authenticator = nil
  @password_reset = nil
  @email_verification = nil
  @email_change = nil

  def self.authenticator
    built = @authenticator
    if built.nil?
      directory = AccountDirectory.new
      built = Cybertrain::Kaisatsu::Authenticator.new(directory)
      @authenticator = built
    end
    built
  end

  # The mail sender, chosen in app/models/mail_setup.rb.
  def self.notifier
    MailSetup.notifier
  end

  # Where reset links point. Set KAISATSU_BASE_URL in production
  # (https://example.com, no trailing slash); it is never taken from the
  # request, whose Host header a client controls.
  def self.base_url
    configured = ENV["KAISATSU_BASE_URL"]
    configured.nil? || configured.empty? ? "http://127.0.0.1:3000" : configured
  end

  # Whether the account's address was confirmed (for a banner, or to
  # hold back a feature until it is).
  def self.email_verified?(user_id)
    AccountDirectory.new.email_verified?(user_id)
  end

  def self.email_change
    built = @email_change
    if built.nil?
      directory = AccountDirectory.new
      inner = notifier
      mailer = BackgroundNotifier.new(inner)
      built = Cybertrain::Kaisatsu::EmailChange.new(directory, mailer, base_url)
      @email_change = built
    end
    built
  end

  def self.email_verification
    built = @email_verification
    if built.nil?
      directory = AccountDirectory.new
      inner = notifier
      mailer = BackgroundNotifier.new(inner)
      built = Cybertrain::Kaisatsu::EmailVerification.new(directory, mailer, base_url)
      @email_verification = built
    end
    built
  end

  def self.password_reset
    built = @password_reset
    if built.nil?
      auth = authenticator
      directory = AccountDirectory.new
      inner = notifier
      mailer = BackgroundNotifier.new(inner)
      built = Cybertrain::Kaisatsu::PasswordReset.new(auth, directory, mailer, base_url)
      @password_reset = built
    end
    built
  end
end
