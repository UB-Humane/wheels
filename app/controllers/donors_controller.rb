class DonorsController < ApplicationController
  include ProductionNav

  before_action :set_production
  before_action :check_access
  before_action :require_admin_access
  before_action :set_location_nav
  before_action :set_active_tab
  before_action :set_donor, only: [ :edit, :update ]

  def index
    @showing_archived = params[:archived] == "true"
    @query = params[:query].presence
    scope = @showing_archived ? @production.donors.archived : @production.donors.active
    if @query
      q = "%#{@query}%"
      scope = scope.where(
        "first_name ILIKE :q OR last_name ILIKE :q OR email ILIKE :q OR (first_name || ' ' || last_name) ILIKE :q",
        q: q
      )
    end
    @pagy, @donors = pagy(scope.order(:last_name, :first_name), limit: 20)
  end

  def new
    @donor = Donor.new
  end

  def create
    @donor = @production.donors.build(donor_params)
    if @donor.save
      redirect_to production_donors_path(@production), notice: "Donor added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if params[:archive]
      @donor.update!(archived: true)
      redirect_to production_donors_path(@production), notice: "#{@donor.full_name} archived."
    elsif params[:unarchive]
      @donor.update!(archived: false)
      redirect_to production_donors_path(@production, archived: true), notice: "#{@donor.full_name} unarchived."
    elsif @donor.update(donor_params)
      redirect_to production_donors_path(@production), notice: "Donor updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_production
    @production = Production.find(params[:production_id])
  end

  def check_access
    require_production_access(@production)
  end

  def require_admin_access
    render plain: "Access denied", status: :forbidden unless production_admin?(@production)
  end

  def set_active_tab
    @location_active = :donors
  end

  def set_donor
    @donor = @production.donors.find(params[:id])
  end

  def donor_params
    params.require(:donor).permit(:first_name, :last_name, :email, :mobile, :address)
  end
end
