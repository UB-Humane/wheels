class SessionsController < ApplicationController
  skip_before_action :require_authentication

  def new
    redirect_to root_path if current_user
  end

  def create
    user = User.find_by(email: params[:email])
    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to root_path
    else
      flash.now[:alert] = "Incorrect email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def omniauth
    auth = request.env["omniauth.auth"]
    user = User.find_by(email: auth.info.email)
    user ||= User.create!(name: auth.info.name.presence || auth.info.email, email: auth.info.email, password: SecureRandom.hex(32))
    session[:user_id] = user.id
    redirect_to root_path
  rescue ActiveRecord::RecordInvalid
    redirect_to login_path, alert: "Couldn't sign in with Google."
  end

  def omniauth_failure
    redirect_to login_path, alert: "Google sign-in failed. Please try again."
  end

  def destroy
    session.delete(:user_id)
    redirect_to login_path
  end
end
