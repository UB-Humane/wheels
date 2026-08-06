require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  DELIVERY_HOST = "delivery.testing.wheelsforworkers.org"

  def login_as(user)
    post login_path, params: { email: user.email, password: "password" }
  end

  test "delivery-only host redirects Bike Tickets to the Delivery dashboard" do
    host! DELIVERY_HOST
    login_as(users(:prod_admin))
    get tickets_production_path(productions(:main_production))
    assert_redirected_to delivery_production_path(productions(:main_production))
  end

  test "delivery-only host renders the Delivery dashboard directly" do
    host! DELIVERY_HOST
    login_as(users(:prod_admin))
    get delivery_production_path(productions(:main_production))
    assert_response :success
  end

  test "delivery-only host allows bike request updates" do
    host! DELIVERY_HOST
    login_as(users(:prod_admin))
    patch bike_request_path(bike_requests(:completed_bike)), params: { status: "taken_up" }
    assert_redirected_to delivery_production_path(productions(:main_production), tab: "taken_up")
    assert bike_requests(:completed_bike).reload.taken_up?
  end

  test "delivery-only host redirects the admin panel even for a superadmin" do
    host! DELIVERY_HOST
    login_as(users(:superadmin))
    get admin_root_path
    assert_redirected_to delivery_production_path(productions(:main_production))
  end

  test "delivery-only host redirects signup" do
    host! DELIVERY_HOST
    get signup_path
    assert_redirected_to delivery_production_path(productions(:main_production))
  end

  test "delivery-only host still allows login" do
    host! DELIVERY_HOST
    get login_path
    assert_response :success
  end

  test "delivery-only host redirects root" do
    host! DELIVERY_HOST
    login_as(users(:prod_admin))
    get root_path
    assert_redirected_to delivery_production_path(productions(:main_production))
  end

  test "delivery-only host redirects your_tickets, inventory, donors, and users" do
    host! DELIVERY_HOST
    login_as(users(:master_mechanic_user))
    production = productions(:main_production)

    get your_tickets_production_path(production)
    assert_redirected_to delivery_production_path(production)

    get inventory_production_path(production)
    assert_redirected_to delivery_production_path(production)

    get users_production_path(production)
    assert_redirected_to delivery_production_path(production)
  end

  test "normal host is unaffected by the delivery-only restriction" do
    login_as(users(:prod_admin))
    get tickets_production_path(productions(:main_production))
    assert_response :success
  end

  # --- require_mobile_number ---

  test "a user without a mobile number is redirected to add one" do
    user = users(:prod_admin)
    user.update_columns(mobile_number: nil)
    login_as(user)
    get tickets_production_path(productions(:main_production))
    assert_redirected_to edit_mobile_number_path
  end

  test "a user without a mobile number is redirected from the admin panel" do
    user = users(:superadmin)
    user.update_columns(mobile_number: nil)
    login_as(user)
    get admin_root_path
    assert_redirected_to edit_mobile_number_path
  end

  test "a user without a mobile number is redirected from root" do
    user = users(:prod_admin)
    user.update_columns(mobile_number: nil)
    login_as(user)
    get root_path
    assert_redirected_to edit_mobile_number_path
  end

  test "a user with a mobile number is not redirected" do
    login_as(users(:prod_admin))
    get tickets_production_path(productions(:main_production))
    assert_response :success
  end

  test "on the delivery-only host, a numberless user is sent to add a number, not looped to delivery" do
    host! DELIVERY_HOST
    user = users(:prod_admin)
    user.update_columns(mobile_number: nil)
    login_as(user)
    get delivery_production_path(productions(:main_production))
    assert_redirected_to edit_mobile_number_path
  end

  test "the mobile number page itself renders on the delivery-only host" do
    host! DELIVERY_HOST
    user = users(:prod_admin)
    user.update_columns(mobile_number: nil)
    login_as(user)
    get edit_mobile_number_path
    assert_response :success
  end
end
