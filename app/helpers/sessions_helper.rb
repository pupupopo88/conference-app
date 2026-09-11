# @rbs module-self ActionController::Base
module SessionsHelper
  class UnauthorizedError < StandardError
  end

  # @rbs @current_user: User

  def github_auth_path(return_to:)
    return "/auth/github" if return_to.blank?

    query = {return_to:}.to_query
    "/auth/github?#{query}"
  end

  # @rbs return: User
  def current_user!
    raise UnauthorizedError unless session[:user_id]

    @current_user ||= User.find(session[:user_id])
  end

  # @rbs return: User?
  def current_user
    current_user!
  rescue UnauthorizedError
    nil
  end

  # @rbs return: Symbol
  def current_locale
    I18n.locale
  end

  # @rbs return: bool
  def logged_in?
    current_user!.present?
  rescue UnauthorizedError
    false
  end
end
