class ApplicationController < ActionController::Base
  include Pagy::Backend
  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :require_authentication
  before_action :require_mobile_number
  before_action :restrict_to_delivery_only_host

  helper_method :current_user, :production_admin?, :distribution_admin?, :production_master_mechanic?, :requestor_for?, :delivery_only_host?

  def self.delivery_only_host
    return nil if Rails.env.production? && ENV["APP_HOST"].blank?
    base = Rails.env.production? ? ENV["APP_HOST"] : "testing.wheelsforworkers.org"
    "delivery.#{base}"
  end

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def require_authentication
    redirect_to login_path unless current_user
  end

  def require_mobile_number
    return unless current_user
    redirect_to edit_mobile_number_path unless current_user.mobile_number.present?
  end

  def delivery_only_host?
    self.class.delivery_only_host.present? && request.host == self.class.delivery_only_host
  end

  def restrict_to_delivery_only_host
    return unless delivery_only_host?
    return if delivery_only_host_allowed?
    redirect_to delivery_production_path(Production.first)
  end

  def delivery_only_host_allowed?
    controller_name == "sessions" ||
      controller_name == "mobile_numbers" ||
      (controller_name == "productions" && action_name == "delivery") ||
      (controller_name == "bike_requests" && action_name == "update")
  end

  def require_superadmin
    render plain: "Access denied", status: :forbidden unless current_user&.superadmin?
  end

  def require_production_access(production)
    return if current_user&.superadmin?
    unless current_user&.productions&.include?(production)
      render plain: "Access denied", status: :forbidden
    end
  end

  def require_distribution_access(distribution)
    return if current_user&.superadmin?
    unless current_user&.distributions&.include?(distribution)
      render plain: "Access denied", status: :forbidden
    end
  end

  def production_admin?(production)
    current_user&.superadmin? ||
      current_user&.user_productions&.find_by(production: production)&.admin?
  end

  def production_master_mechanic?(production)
    current_user&.superadmin? ||
      current_user&.user_productions&.find_by(production: production)&.master_mechanic?
  end

  def requestor_for?(bike_request)
    return true if current_user&.superadmin?
    if bike_request.distribution.present?
      current_user&.distributions&.include?(bike_request.distribution)
    else
      current_user&.productions&.include?(bike_request.production)
    end
  end

  def distribution_admin?(distribution)
    current_user&.superadmin? ||
      current_user&.user_distributions&.find_by(distribution: distribution)&.role == "admin"
  end
end
