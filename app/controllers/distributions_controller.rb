class DistributionsController < ApplicationController
  before_action :set_distribution
  before_action :check_access
  before_action :set_location_nav

  def show
    redirect_to tickets_distribution_path(@distribution)
  end

  def tickets
    @location_active = :tickets
    @tab = params[:tab].presence_in(%w[requested pending ready_for_delivery delivered distributed archived]) || "requested"
    raw_counts = @distribution.bike_requests.group(:status).count
    @tab_counts = raw_counts.merge("requested" => (raw_counts["requested"] || 0) + (raw_counts["denied"] || 0))
    status_scope = @tab == "requested" ? %w[requested denied] : @tab
    scope = @distribution.bike_requests.where(status: status_scope)
                                .includes(:distribution, :user, :bikes, :owner)
                                .order(due_date: :asc)
    @pagy, @bike_requests = pagy(scope, limit: 20)
  end

  def users
    @location_active = :users
    render plain: "Access denied", status: :forbidden and return unless @location_admin
    members_scope = @distribution.user_distributions.includes(:user).order("users.name")
    @pagy_members, @members = pagy(members_scope, limit: 20)
    if params[:member_query].present?
      query = "%#{params[:member_query]}%"
      @member_search_results = User.where("name ILIKE ? OR email ILIKE ?", query, query)
                                   .order(:name).limit(10)
    end
  end

  private

  def set_distribution
    @distribution = Distribution.find(params[:id])
  end

  def check_access
    require_distribution_access(@distribution)
  end

  def set_location_nav
    @location_name         = @distribution.name
    @location_path         = tickets_distribution_path(@distribution)
    @location_admin        = distribution_admin?(@distribution)
    @location_users_path   = users_distribution_path(@distribution)
    @location_show_tickets = true
  end
end
