class EmailVerificationsController < ApplicationController
  # GET /email/resend
  def new_action
  end

  # POST /email/resend
  # The answer is the same whether or not the address has an account, or is confirmed.
  def create
    send_link(params[:email].to_s)
    flash[:notice] = "If that address needs confirming, we sent a link."
    redirect_to "/login", status: :see_other
  end

  # GET /email/verify/:token
  # Opening the link only shows a button: mail scanners and link previews fetch
  # links, and must not confirm an address by doing so.
  def edit
    @token = params[:token].to_s
    unless token_still_valid?(@token)
      flash[:alert] = "That link is invalid or has expired."
      return redirect_to("/email/resend", status: :see_other)
    end
    response.set_header("Referrer-Policy", "no-referrer")
  end

  # POST /email/verify
  def update
    if confirm(params[:token].to_s).done?
      flash[:notice] = "Your email address is confirmed."
      redirect_to "/login", status: :see_other
    else
      flash[:alert] = "That link is invalid or has expired."
      redirect_to "/email/resend", status: :see_other
    end
  end

  private

  # Everything a Cybertrain::DB.with block needs is a local first: inside the block `self`
  # is not the controller under Spinel.
  def send_link(email)
    ip = request.remote_addr
    now = Time.now.to_i
    Cybertrain::DB.with do |conn|
      Accounts.email_verification.request_verification(conn, email, ip, now)
    end
    nil
  end

  def token_still_valid?(token)
    now = Time.now.to_i
    Cybertrain::DB.with do |conn|
      Accounts.email_verification.token_valid?(conn, token, now)
    end
  end

  def confirm(token)
    now = Time.now.to_i
    Cybertrain::DB.with do |conn|
      Accounts.email_verification.complete_verification(conn, token, now)
    end
  end
end
