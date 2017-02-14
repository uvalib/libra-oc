# Overridden Devise::SessionsController
class Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  def new
    create
  end

  # POST /resource/sign_in
  def create
    if Rails.env.development?
      request.env['HTTP_REMOTE_USER'] = ENV['DEV_USER']
    end
    self.resource = warden.authenticate!(auth_options)
    set_flash_message(:notice, :signed_in) if is_flashing_format?
    sign_in(resource_name, resource)
    yield resource if block_given?
    redirect_to after_sign_in_path_for(resource)
  end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end

  private


  # Overwriting the sign_out redirect path method
  def after_sign_out_path_for(resource_or_scope)
    # caught by apache to trigger pubcookie logout
    '/logout'
  end

end
