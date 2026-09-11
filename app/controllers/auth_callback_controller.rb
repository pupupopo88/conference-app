class AuthCallbackController < ApplicationController
  # @rbs return: void
  def create
    if params[:provider] != "github"
      flash[:alert] = "Unknown provider"
      redirect_to login_path
      return
    end

    user = AuthenticationProviderGithub.find_or_create_user_from_auth_hash(request.env["omniauth.auth"]) do |user|
      DetermineUserRoleJob.perform_later(user.id)
      user.profile.ensure_image_from_github
      user.mark_all_announcement_unread!
    end

    reset_session
    session[:user_id] = user.id

    return_to = request.env["omniauth.params"]["return_to"]
    redirect_to url_from(return_to) || setting_path
  end
end
