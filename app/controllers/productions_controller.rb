class ProductionsController < ApplicationController
  before_action :set_production
  before_action :check_access
  before_action :set_location_nav

  def show
    redirect_to tickets_production_path(@production)
  end

  def tickets
    @tab = params[:tab].presence_in(%w[requested pending completed delivered distributed archived]) || "requested"
    @tab_counts = @production.bike_requests.group(:status).count
    scope = @production.bike_requests.where(status: @tab)
                    .includes(:distribution, :user, :bikes)
                    .order(due_date: :asc)
    @pagy, @bike_requests = pagy(scope, limit: 20)
  end

  def users
    render plain: "Access denied", status: :forbidden and return unless @location_admin
    members_scope = @production.user_productions.includes(:user).order("users.name")
    @pagy_members, @members = pagy(members_scope, limit: 20)
    if params[:member_query].present?
      query = "%#{params[:member_query]}%"
      @member_search_results = User.where("name ILIKE ? OR email ILIKE ?", query, query)
                                   .order(:name).limit(10)
    end
  end

  private

  def set_production
    @production = Production.find(params[:id])
  end

  def check_access
    require_production_access(@production)
  end

  def set_location_nav
    @location_name         = @production.name
    @location_path         = tickets_production_path(@production)
    @location_admin        = production_admin?(@production)
    @location_users_path   = users_production_path(@production)
    @location_show_tickets = true
  end
end
