require "test_helper"

class ProductionInventoriesControllerTest < ActionDispatch::IntegrationTest
  def inventory
    production_inventories(:main_inventory)
  end

  test "update requires authentication" do
    patch production_inventory_path(inventory), params: { item: "helmets", action_type: "take" }
    assert_redirected_to login_path
  end

  test "update returns 403 for distribution user" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    patch production_inventory_path(inventory), params: { item: "helmets", action_type: "take" }
    assert_response :forbidden
  end

  test "take helmets decrements count" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch production_inventory_path(inventory), params: { item: "helmets", action_type: "take" }
    assert_equal 9, inventory.reload.helmets
  end

  test "take locks decrements count" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch production_inventory_path(inventory), params: { item: "locks", action_type: "take" }
    assert_equal 4, inventory.reload.locks
  end

  test "take does not go below zero" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    inventory.update!(helmets: 0)
    patch production_inventory_path(inventory), params: { item: "helmets", action_type: "take" }
    assert_equal 0, inventory.reload.helmets
  end

  test "add helmets increments count" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch production_inventory_path(inventory), params: { item: "helmets", action_type: "add", quantity: "5" }
    assert_equal 15, inventory.reload.helmets
  end

  test "add locks increments count" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch production_inventory_path(inventory), params: { item: "locks", action_type: "add", quantity: "3" }
    assert_equal 8, inventory.reload.locks
  end

  test "add rejects quantity of zero" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch production_inventory_path(inventory), params: { item: "helmets", action_type: "add", quantity: "0" }
    assert_response :bad_request
  end

  test "add rejects negative quantity" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch production_inventory_path(inventory), params: { item: "helmets", action_type: "add", quantity: "-3" }
    assert_response :bad_request
  end

  test "update with invalid item returns 400" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch production_inventory_path(inventory), params: { item: "money", action_type: "take" }
    assert_response :bad_request
  end

  test "update redirects to inventory page" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch production_inventory_path(inventory), params: { item: "helmets", action_type: "take" }
    assert_redirected_to inventory_production_path(productions(:main_production))
  end
end
