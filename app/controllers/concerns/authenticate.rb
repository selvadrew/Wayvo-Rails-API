module Authenticate
  def current_user
    @current_user = User.find_by(access_token: params[:access_token])
  end

  def authenticate_with_token!
    render json: { error: "Not Authenticated. Please logout and login again.", is_success: false, error_code: "logout"}, status: :unauthorized unless current_user.present?
  end



end
