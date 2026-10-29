class ApplicationController < Cybertrain::Controller
  # Kaisatsu: check the session id against the database on every request.
  before_action :resolve_kaisatsu_session

  rescue_from Cybertrain::RecordNotFound, with: :record_not_found

  before_action :expose_sign_in_state

  private

  # The layout is a template, which cannot call controller methods: hand it a flag.
  def expose_sign_in_state
    @signed_in = signed_in?
  end

  # Who is signed in is looked up once per request and kept here, not in the
  # cookie. A controller that does not inherit this one never runs it.
  def resolve_kaisatsu_session
    @kaisatsu_user_id = Cybertrain::Kaisatsu::Gate.resolve(ctx)
    nil
  end

  def signed_in?
    current_user_id.bytesize > 0
  end

  def current_user_id
    uid = @kaisatsu_user_id
    uid.nil? ? "" : uid
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
