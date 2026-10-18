class EmailChangesController < ApplicationController
  before_action :require_login, only: [:new_action, :create]

  # GET /account/email
  def new_action
  end

  # POST /account/email
  # Nothing changes yet: a link goes to the new address. The answer does not say
  # whether the address is already in use.
  def create
    outcome = ask_for_change(current_user_id, params[:email].to_s, params[:password].to_s)
    if outcome.accepted?
      flash[:notice] = "If that address can be used, we sent a link to it. The change takes effect when you confirm."
      redirect_to "/", status: :see_other
    elsif outcome.status == "throttled"
      flash.now[:alert] = "Too many attempts. Try again later."
      render :new_action, status: 429
    elsif outcome.status == "wrong_password"
      flash.now[:alert] = "The password is not correct."
      render :new_action, status: :unprocessable_entity
    else
      flash.now[:alert] = "Enter a different, valid email address."
      render :new_action, status: :unprocessable_entity
    end
  end

  # GET /email/change/:token
  # Opening the link only shows a button.
  def edit
    @token = params[:token].to_s
    unless token_still_valid?(@token)
      flash[:alert] = "That link is invalid or has expired."
      return redirect_to("/login", status: :see_other)
    end
    response.set_header("Referrer-Policy", "no-referrer")
  end

  # POST /email/change
  def update
    outcome = confirm(params[:token].to_s)
    if outcome.done?
      flash[:notice] = "Your email address was changed. Please sign in with the new address."
    elsif outcome.status == "taken"
      flash[:alert] = "That address is now used by another account, so nothing was changed."
    else
      flash[:alert] = "That link is invalid or has expired."
    end
    redirect_to "/login", status: :see_other
  end

  private

  # Everything a DB.with block needs is a local first: inside the block `self`
  # is not the controller under Spinel.
  def ask_for_change(user_id, new_email, password)
    now = Time.now.to_i
    DB.with do |conn|
      Accounts.email_change.request_change(conn, user_id, new_email, password, now)
    end
  end

  def token_still_valid?(token)
    now = Time.now.to_i
    DB.with do |conn|
      Accounts.email_change.token_valid?(conn, token, now)
    end
  end

  def confirm(token)
    now = Time.now.to_i
    DB.with do |conn|
      Accounts.email_change.complete_change(conn, token, now)
    end
  end
end
