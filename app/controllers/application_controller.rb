class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  include Hydra::Controller::ControllerBehavior
  include Hyrax::ThemedLayoutController
  with_themed_layout '1_column'

  helper Openseadragon::OpenseadragonHelper


  # Adds Hyrax behaviors into the application controller
  include Hyrax::Controller

  include Hyrax::ThemedLayoutController
  with_themed_layout '1_column'

  protect_from_forgery with: :exception

  rescue_from CanCan::AccessDenied, :with => :render404
  rescue_from ActionController::RoutingError, :with => :render404
  rescue_from ActionView::MissingTemplate, :with => :render404

  #rescue_from Exception do |exception|
  #  puts "======> #{exception.class}"
  #  puts "#{exception.message}"
  #  puts "#{exception.backtrace}"
  #  render404
  #end

  def render404
    if user_signed_in?
      render :file => "#{Rails.root}/public/404.html", :status => :not_found, :layout => false
    else
      # This is the case where someone logs in with Shiboleth but does not have an account. This happens because of one of the following:
      # 1) They work here and are trying to see if Libra is active, but have no reason to upload,
      # 2) They are a student who has submitted to SIS, but has jumped the gun and went to Libra before their thesis had been created,
      # 3) They are a random UVA student who stumbled here but has no business here.
      render :file => "#{Rails.root}/public/401.html", :status => :unauthorized, :layout => false
    end
  end

  def render404public
    render :file => "#{Rails.root}/public/404-public.html", :status => :not_found, :layout => false
  end

  #
  # ensure the current user is an administrator
  #
  def enforce_user_is_admin
    return if user_signed_in? && current_user.admin?
    raise CanCan::AccessDenied
  end

  def set_debugging_override

    @grounds_override = false
    if ENV['ENABLE_TEST_FEATURES']
      @grounds_override = params[:grounds] if params[:grounds].present?
    end
  end

end
