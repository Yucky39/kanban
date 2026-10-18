class SessionsController < ApplicationController
  # GET /login
  def new_action
  end

  # POST /login
  def create
    result = login_result
    if result.ok?
      Cybertrain::Kaisatsu::Gate.sign_in(ctx, result.session_id, result.user_id)
      flash[:notice] = "Signed in."
      redirect_to "/", status: :see_other
    elsif result.status == "throttled"
      flash.now[:alert] = "Too many attempts. Try again later."
      render :new_action, status: 429
    else
      flash.now[:alert] = "Invalid email or password."
      render :new_action, status: :unprocessable_entity
    end
  end

  # DELETE /logout
  def destroy
    sign_out_now
    flash[:notice] = "Signed out."
    redirect_to "/login", status: :see_other
  end

  private

  def login_result
    email = params[:email].to_s
    password = params[:password].to_s
    ip = request.remote_addr
    now = Time.now.to_i
    # Everything the block needs is a local first: inside a DB.with block
    # `self` is not the controller under Spinel, so request/ctx/params would not resolve.
    DB.with do |conn|
      Accounts.authenticator.login(conn, email, password, ip, now)
    end
  end

  def sign_out_now
    context = ctx
    DB.with { |conn| Cybertrain::Kaisatsu::Gate.sign_out(context, conn) }
    nil
  end
end
