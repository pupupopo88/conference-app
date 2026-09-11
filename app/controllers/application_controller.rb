class ApplicationController < ActionController::Base
  # @rbs! include _RbsRailsPathHelpers

  include SessionsHelper

  before_action :set_variant!

  around_action :switch_locale

  def require_logged_in
    return if logged_in?

    login_location = request.get? ? login_path(return_to: request.fullpath) : login_path
    redirect_to login_location
  end

  # @rbs { () -> untyped } -> untyped
  def switch_locale(&action)
    locale = params[:locale] || current_user&.locale_setting&.preferred_locale || I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  private def set_variant!
    if Woothee.parse(request.user_agent)[:category] == :smartphone
      request.variant = :mobile
    end
  end
end
