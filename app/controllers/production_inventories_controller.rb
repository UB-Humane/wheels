class ProductionInventoriesController < ApplicationController
  before_action :set_inventory

  def update
    item = params[:item].presence_in(%w[helmets locks])
    return head :bad_request unless item

    case params[:action_type]
    when "take"
      current = @inventory.public_send(item)
      @inventory.update!(item => [ current - 1, 0 ].max)
    when "add"
      qty = params[:quantity].to_i
      return head :bad_request unless qty > 0
      @inventory.with_lock { @inventory.increment!(item.to_sym, qty) }
    end

    redirect_to inventory_production_path(@inventory.production)
  end

  private

  def set_inventory
    @inventory = ProductionInventory.find(params[:id])
    return render plain: "Access denied", status: :forbidden unless authorized?
  end

  def authorized?
    current_user&.superadmin? || current_user&.productions&.include?(@inventory.production)
  end
end
