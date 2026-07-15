class DonorsController < ApplicationController
  before_action :set_production
  before_action :check_access
  before_action :set_location_nav
  before_action :set_donor, only: [ :edit, :update ]

  def index
    scope = params[:archived] == "true" ? @production.donors.archived : @production.donors.active
    @pagy, @donors = pagy(scope.order(:last_name, :first_name), limit: 20)
    @showing_archived = params[:archived] == "true"
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

  def set_location_nav
    @location_name           = @production.name
    @location_path           = tickets_production_path(@production)
    @location_admin          = production_admin?(@production)
    @location_users_path     = users_production_path(@production)
    @location_inventory_path = inventory_production_path(@production)
    @location_donors_path    = production_donors_path(@production)
    @location_show_tickets   = true
    @location_active         = :donors
  end

  def set_donor
    @donor = @production.donors.find(params[:id])
  end

  def donor_params
    params.require(:donor).permit(:first_name, :last_name, :email, :mobile, :address)
  end
end
