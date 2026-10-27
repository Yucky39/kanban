class PasswordResetsController < ApplicationController
  # GET /password/forgot
  def new_action
  end

  # POST /password/forgot
  # The answer is the same whether or not the address has an account.
  def create
    send_reset_link(params[:email].to_s)
    flash[:notice] = "If that address has an account, we sent a link to reset the password."
    redirect_to "/login", status: :see_other
  end

  # GET /password/reset/:token
  def edit
    @token = params[:token].to_s
    unless token_still_valid?(@token)
      flash[:alert] = "That link is invalid or has expired."
      return redirect_to("/password/forgot", status: :see_other)
    end
    # The token is in the address bar: keep it out of the Referer header.
    response.set_header("Referrer-Policy", "no-referrer")
  end

  # POST /password/reset
  def update
    @token = params[:token].to_s
    outcome = finish_reset(@token, params[:password].to_s)
    if outcome.done?
      flash[:notice] = "Your password was changed. Please sign in."
      redirect_to "/login", status: :see_other
    elsif outcome.status == "weak_password"
      flash.now[:alert] = "Password: " + outcome.message
      response.set_header("Referrer-Policy", "no-referrer")
      render :edit, status: :unprocessable_entity
    else
      flash[:alert] = "That link is invalid or has expired."
      redirect_to "/password/forgot", status: :see_other
    end
  end

  private

  # Everything a Cybertrain::DB.with block needs is a local first: inside the block `self`
  # is not the controller under Spinel.
  def send_reset_link(email)
    ip = request.remote_addr
    now = Time.now.to_i
    Cybertrain::DB.with do |conn|
      Accounts.password_reset.request_reset(conn, email, ip, now)
    end
    nil
  end

  def token_still_valid?(token)
    now = Time.now.to_i
    # Declared first, then assigned inside the block: the value of a
    # Cybertrain::DB.with block is untyped, and a method call on it fails
    # at run time on Spinel 2026.10.26.7019.
    outcome = false
    Cybertrain::DB.with do |conn|
      outcome = Accounts.password_reset.token_valid?(conn, token, now)
    end
    outcome
  end

  def finish_reset(token, password)
    now = Time.now.to_i
    # Declared first, then assigned inside the block: the value of a
    # Cybertrain::DB.with block is untyped, and a method call on it fails
    # at run time on Spinel 2026.10.26.7019.
    outcome = Cybertrain::Kaisatsu::ResetOutcome.new("none", "")
    Cybertrain::DB.with do |conn|
      outcome = Accounts.password_reset.complete_reset(conn, token, password, now)
    end
    outcome
  end
end
