class ApplicationController < ActionController::Base
  include Pagy::Backend
  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :require_authentication

  helper_method :current_user, :production_admin?, :distribution_admin?, :production_master_mechanic?, :requestor_for?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def require_authentication
    redirect_to login_path unless current_user
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
