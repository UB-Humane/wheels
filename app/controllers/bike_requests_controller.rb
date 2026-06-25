class BikeRequestsController < ApplicationController
  before_action :set_distribution, only: [ :new, :create ]
  before_action :check_distribution_access, only: [ :new, :create ]
  before_action :set_bike_request, only: [ :edit, :update ]

  def new
    @bike_request = BikeRequest.new(due_date: Date.today + 14)
    @bike_request.bikes.build
    @production = Production.first
  end

  def create
    @production = Production.first
    @bike_request = BikeRequest.new(bike_request_params)
    @bike_request.distribution = @distribution
    @bike_request.production = @production
    @bike_request.user = current_user

    if @bike_request.save
      redirect_to tickets_distribution_path(@distribution), notice: "Bike request submitted."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    return render plain: "Access denied", status: :forbidden unless authorized_for_distribution?
  end

  def update
    if params[:status].in?(%w[approve deny completed delivered distributed])
      return render plain: "Access denied", status: :forbidden unless authorized_for_production?
      handle_production_update
    else
      return render plain: "Access denied", status: :forbidden unless authorized_for_distribution?
      handle_distribution_resubmit
    end
  end

  private

  def handle_production_update
    attributes = case params[:status]
    when "approve"      then { status: :requested }
    when "deny"         then { status: :denied, denial_reason: params[:denial_reason].presence }
    when "completed"    then { status: :completed }
    when "delivered"    then { status: :delivered }
    when "distributed"  then { status: :distributed }
    end

    original_status = @bike_request.status

    if attributes && @bike_request.update(attributes)
      tab = case params[:status]
            when "approve" then "requested"
            when "deny"    then "pending"
            else @bike_request.status.to_s
            end
      redirect_to tickets_production_path(@bike_request.production, tab: tab)
    else
      redirect_to tickets_production_path(@bike_request.production, tab: original_status),
        alert: @bike_request.errors.full_messages.first
    end
  end

  def handle_distribution_resubmit
    if @bike_request.update(resubmit_params.merge(status: :pending, denial_reason: nil))
      redirect_to tickets_distribution_path(@bike_request.distribution, tab: "pending")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def set_distribution
    @distribution = Distribution.find(params[:distribution_id])
  end

  def check_distribution_access
    require_distribution_access(@distribution)
  end

  def set_bike_request
    @bike_request = BikeRequest.find(params[:id])
  end

  def authorized_for_production?
    current_user&.superadmin? || current_user&.productions&.include?(@bike_request.production)
  end

  def authorized_for_distribution?
    current_user&.superadmin? || current_user&.distributions&.include?(@bike_request.distribution)
  end

  def bike_request_params
    params.require(:bike_request).permit(
      :phone, :requestor_name, :due_date,
      bikes_attributes: [ :name, :bike_type, :age, :height, :notes ]
    )
  end

  def resubmit_params
    params.require(:bike_request).permit(
      :phone, :requestor_name, :due_date,
      bikes_attributes: [ :id, :name, :bike_type, :age, :height, :notes, :_destroy ]
    )
  end
end
