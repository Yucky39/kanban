class ApplicationController < Cybertrain::Controller
  # Kaisatsu: check the session id against the database on every request.
  before_action { |c| Cybertrain::Kaisatsu::Gate.resolve(c.ctx) }

  rescue_from Cybertrain::RecordNotFound, with: :record_not_found

  before_action :expose_sign_in_state

  private

  # The layout is a template, which cannot call controller methods: hand it a flag.
  def expose_sign_in_state
    @signed_in = signed_in?
  end

  def signed_in?
    Cybertrain::Kaisatsu::Gate.signed_in?(ctx)
  end

  def current_user_id
    Cybertrain::Kaisatsu::Gate.user_id(ctx)
  end

  # Use as: before_action :require_login
  def require_login
    return if signed_in?
    flash[:alert] = "Please sign in."
    redirect_to "/login", status: :see_other
  end

  def record_not_found
    render plain: "Not Found", status: :not_found
  end
end
