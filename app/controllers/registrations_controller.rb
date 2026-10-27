class RegistrationsController < ApplicationController
  # GET /signup
  def new_action
  end

  # POST /signup
  def create
    email = params[:email].to_s.strip.downcase
    password = params[:password].to_s
    problem = signup_problem(email, password)
    unless problem.empty?
      flash.now[:alert] = problem
      return render(:new_action, status: :unprocessable_entity)
    end
    user = User.new(email: email, password_hash: Cybertrain::Kaisatsu::PasswordHash.create(password))
    user.save
    send_confirmation(email)
    flash[:notice] = "Account created. We sent a link to confirm your email address. Please sign in."
    redirect_to "/login", status: :see_other
  end

  private

  # A Cybertrain::DB.with block cannot see the controller's request: bind first.
  def send_confirmation(email)
    ip = request.remote_addr
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
