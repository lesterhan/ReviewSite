class SessionsController < ApplicationController
  skip_before_filter :require_login, only: [:callback]
  skip_authorization_check

  def callback
    session[:userinfo] = request.env["omniauth.auth"].uid
    session[:user_name] = request.env["omniauth.auth"].info.name

    @current_user = User.where(email: current_email).first_or_create do |user|
      user.name = real_name_or_default
      user.okta_name = current_okta_name
      user.admin = false
    end

    redirect_back_or(root_path)
  end

  def set_temp_okta
    self.current_okta_name = params["temp-okta"]
    redirect_to root_path
  end

end
