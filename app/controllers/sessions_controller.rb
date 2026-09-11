class SessionsController < ApplicationController
  # @rbs return: void
  def new
    @return_to = url_from(params[:return_to])
  end

  # @rbs return: void
  def create
    return_to = url_from(params[:return_to])

    case params[:provider]
    when "email"
      if (auth = AuthenticationProviderEmailAndPassword.find_by(email: params[:email]))
        if auth.authenticate(params[:password])
          user = auth.user
        else
          flash[:alert] = "Invalid email or password"
          redirect_to login_path(return_to:)
          return
        end
      else
        flash[:alert] = "Invalid email or password"
        redirect_to login_path(return_to:)
        return
      end
    else
      flash[:alert] = "Unknown provider"
      redirect_to login_path(return_to:)
      return
    end

    reset_session
    session[:user_id] = user.id if user

    redirect_to return_to || operators_path
  end

  # @rbs return: void
  def destroy
    session[:user_id] = nil
    reset_session
    redirect_to about_path
  end
end
