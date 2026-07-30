class BikeRequestsController < ApplicationController
  before_action :set_distribution,          only: [ :new, :create ], if: -> { params[:distribution_id].present? }
  before_action :check_distribution_access, only: [ :new, :create ], if: -> { params[:distribution_id].present? }
  before_action :set_production_requester,  only: [ :new, :create ], if: -> { params[:production_id].present? }
  before_action :check_production_access,   only: [ :new, :create ], if: -> { params[:production_id].present? }
  before_action :set_bike_request, only: [ :edit, :update, :complete_all ]

  def new
    @bike_request = BikeRequest.new(due_date: Date.today + 14)
    @bike_request.bikes.build
  end

  def create
    @bike_request = BikeRequest.new(bike_request_params)
    if @distribution
      @bike_request.distribution = @distribution
      @bike_request.production   = Production.first
    else
      @bike_request.production = @production_requester
      @bike_request.status     = :pending
    end
    @bike_request.user = current_user

    if @bike_request.save
      redirect_to(@distribution ? tickets_distribution_path(@distribution) : tickets_production_path(@bike_request.production),
                  notice: "Bike request submitted.")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    return render plain: "Access denied", status: :forbidden unless authorized_for_distribution?
  end

  def complete_all
    return render plain: "Access denied", status: :forbidden unless production_master_mechanic?(@bike_request.production)
    @bike_request.update_columns(status: BikeRequest.statuses[:ready_for_delivery]) if @bike_request.pending?
    redirect_to delivery_production_path(@bike_request.production, tab: "ready_for_delivery")
  end

  def update
    if params[:status] == "distributed"
      return render plain: "Access denied", status: :forbidden unless requestor_for?(@bike_request)
      @bike_request.update!(status: :distributed)
      if @bike_request.distribution.present?
        redirect_to tickets_distribution_path(@bike_request.distribution, tab: "distributed")
      else
        redirect_to tickets_production_path(@bike_request.production, tab: "distributed")
      end
    elsif params[:status].in?(%w[approve deny ready_for_delivery taken_up delivered archive unarchive])
      return render plain: "Access denied", status: :forbidden unless authorized_for_production?
      if params[:status] == "delivered" && @bike_request.taken_up?
        return render plain: "Access denied", status: :forbidden unless authorized_to_complete_delivery?
      end
      handle_production_update
    else
      return render plain: "Access denied", status: :forbidden unless authorized_for_distribution?
      handle_distribution_resubmit
    end
  end

  private

  def handle_production_update
    restored = BikeRequest.statuses.key(@bike_request.status_before_archival) if params[:status] == "unarchive"
    original_status = @bike_request.status

    attributes = case params[:status]
    when "approve"      then { status: :pending, owner_id: params[:owner_id].presence }
    when "deny"         then { status: :denied, denial_reason: params[:denial_reason].presence }
    when "ready_for_delivery" then { status: :ready_for_delivery }
    when "taken_up"     then { status: :taken_up }.merge(original_status == "ready_for_delivery" ? { taker_id: current_user.id } : {})
    when "delivered"    then { status: :delivered }
    when "archive"      then { status: :archived, status_before_archival: @bike_request.read_attribute(:status) }
    when "unarchive"    then { status: restored, status_before_archival: nil }
    end

    if attributes && @bike_request.update(attributes)
      tab = case params[:status]
            when "approve"   then "pending"
            when "deny"      then "requested"
            when "archive"   then "archived"
            when "unarchive" then (restored == "denied" ? "requested" : restored)
            else @bike_request.status.to_s
            end
      redirect_to production_tab_path(@bike_request.production, tab)
    else
      redirect_to production_tab_path(@bike_request.production, original_status),
        alert: @bike_request.errors.full_messages.first
    end
  end

  def production_tab_path(production, tab)
    if BikeRequest::DELIVERY_STATUSES.include?(tab.to_s)
      delivery_production_path(production, tab: tab)
    else
      tickets_production_path(production, tab: tab)
    end
  end

  def handle_distribution_resubmit
    if @bike_request.update(resubmit_params.merge(status: :requested, denial_reason: nil))
      redirect_to tickets_distribution_path(@bike_request.distribution, tab: "requested")
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

  def set_production_requester
    @production_requester = Production.find(params[:production_id])
  end

  def check_production_access
    require_production_access(@production_requester)
  end

  def set_bike_request
    @bike_request = BikeRequest.find(params[:id])
  end

  def authorized_for_production?
    current_user&.superadmin? || current_user&.productions&.include?(@bike_request.production)
  end

  def authorized_to_complete_delivery?
    current_user == @bike_request.taker || production_master_mechanic?(@bike_request.production)
  end

  def authorized_for_distribution?
    return false if @bike_request.distribution.nil?
    current_user&.superadmin? || current_user&.distributions&.include?(@bike_request.distribution)
  end

  def bike_request_params
    permitted = [ :phone, :requestor_name, :due_date,
                  { bikes_attributes: [ :name, :bike_type, :age, :height, :notes ] } ]
    permitted.unshift(:owner_id) if @production_requester.present?
    params.require(:bike_request).permit(*permitted)
  end

  def resubmit_params
    params.require(:bike_request).permit(
      :phone, :requestor_name, :due_date,
      bikes_attributes: [ :id, :name, :bike_type, :age, :height, :notes, :_destroy ]
    )
  end
end
