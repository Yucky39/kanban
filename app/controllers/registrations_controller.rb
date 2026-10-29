class RegistrationsController < ApplicationController
  # GET /signup
  def new_action
  end

  # POST /signup
  def create
    email = params[:email].to_s.strip.downcase
    password = params[:password].to_s
    unless signup_allowed?(request.client_ip, Time.now.to_i)
      flash.now[:alert] = "Too many sign-up attempts. Please try again later."
      return render(:new_action, status: :too_many_requests)
    end
    problem = signup_problem(email, password)
    unless problem.empty?
      flash.now[:alert] = problem
      return render(:new_action, status: :unprocessable_entity)
    end
    user = User.new(email: email, password_hash: Cybertrain::Kaisatsu::PasswordHash.create(password))
    unless user.save
      flash.now[:alert] = "The account could not be created"
      return render(:new_action, status: :unprocessable_entity)
    end
    send_confirmation(email)
    flash[:notice] = "Account created. We sent a link to confirm your email address. Please sign in."
    redirect_to "/login", status: :see_other
  end

  private

  # Every try counts, not only the failed ones: ten per address in 15 minutes.
  def signup_allowed?(ip, now)
    return true if ip.empty?
    Cybertrain::DB.with do |conn|
      Cybertrain::Kaisatsu::Throttle.hit(conn, "signup:" + ip, now, 10, 900)
    end
  end

  # A Cybertrain::DB.with block cannot see the controller's request: bind first.
  def send_confirmation(email)
    ip = request.client_ip
    now = Time.now.to_i
    Cybertrain::DB.with do |conn|
      Accounts.email_verification.request_verification(conn, email, ip, now)
    end
    nil
  end

  def signup_problem(email, password)
    return "Email can't be blank" if email.empty?
    return "Email is not valid" unless email.include?("@") && email.length <= 254
    policy = Cybertrain::Kaisatsu::PasswordHash.policy_error(password)
    return "Password: " + policy unless policy.empty?
    return "Email is already taken" unless User.where(email: email).first.nil?
    ""
  end
end
