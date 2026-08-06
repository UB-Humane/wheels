module ProductionNav
  extend ActiveSupport::Concern

  private

  def production_ticket_owner_eligible?
    production_admin?(@production) || production_master_mechanic?(@production)
  end

  def set_location_nav
    @location_name         = @production.name
    @location_path         = tickets_production_path(@production)
    @location_admin        = production_admin?(@production)
    @location_users_path   = users_production_path(@production)
    @location_inventory_path = inventory_production_path(@production)
    @location_donors_path    = production_donors_path(@production)
    @location_show_tickets   = true
    @location_show_delivery  = true
    @location_delivery_path  = delivery_production_path(@production)
    @location_show_your_tickets = production_ticket_owner_eligible?
    @location_your_tickets_path = your_tickets_production_path(@production)
  end
end
