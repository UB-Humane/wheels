require "test_helper"

class ProductionsControllerTest < ActionDispatch::IntegrationTest
  test "show requires authentication" do
    get tickets_production_path(productions(:main_production))
    assert_redirected_to login_path
  end

  test "show allows superadmin without explicit production assignment" do
    post login_path, params: { email: users(:superadmin).email, password: "password" }
    get tickets_production_path(productions(:main_production))
    assert_response :success
  end

  test "show returns 403 for user without production access" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    get tickets_production_path(productions(:main_production))
    assert_response :forbidden
  end

  test "show renders for authorized user" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    get tickets_production_path(productions(:main_production))
    assert_response :success
  end

  test "nav renders a mobile menu alongside the desktop links, showing the active tab and grouping profile/logout below a divider" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    get tickets_production_path(productions(:main_production))
    assert_select "div.hidden.lg\\:flex a", text: "Bike Tickets"
    assert_select "div.lg\\:hidden[data-controller=nav-menu]" do
      assert_select "button[data-nav-menu-target=button]", text: /Bike Tickets/
      assert_select "div[data-nav-menu-target=panel][hidden]" do
        assert_select "a", text: "Delivery"
        assert_select "div.border-t" do
          assert_select "a", text: users(:prod_admin).name
          assert_select "form button", text: "Log out"
        end
      end
    end
  end

  test "show defaults to pending tab" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    get tickets_production_path(productions(:main_production))
    assert_response :success
  end

  test "show accepts valid tab parameter" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    get tickets_production_path(productions(:main_production)), params: { tab: "pending" }
    assert_response :success
  end

  test "show ignores invalid tab parameter and defaults to pending" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    get tickets_production_path(productions(:main_production)), params: { tab: "badtab" }
    assert_response :success
  end

  test "show returns 404 for nonexistent production" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    get tickets_production_path(id: 999999)
    assert_response :not_found
  end

  test "show only returns bike requests belonging to this production" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    other_prod = Production.create!(name: "Other Production")
    other_request = BikeRequest.create!(
      due_date: 10.days.from_now,
      distribution: distributions(:downtown_dist),
      production: other_prod, user: users(:dist_user)
    )
    get tickets_production_path(productions(:main_production)), params: { tab: "requested" }
    assert_response :success
    assert_not assigns(:bike_requests).include?(other_request)
  end

  test "show ignores ready_for_delivery/delivered/distributed tabs and defaults to requested" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    %w[ready_for_delivery delivered distributed].each do |tab|
      get tickets_production_path(productions(:main_production)), params: { tab: tab }
      assert_response :success
      assert_equal "requested", assigns(:tab)
    end
  end

  # --- delivery action ---

  test "delivery requires authentication" do
    get delivery_production_path(productions(:main_production))
    assert_redirected_to login_path
  end

  test "delivery returns 403 for user without production access" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    get delivery_production_path(productions(:main_production))
    assert_response :forbidden
  end

  test "delivery renders for authorized production user" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    get delivery_production_path(productions(:main_production))
    assert_response :success
  end

  test "delivery defaults to ready_for_delivery tab" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    get delivery_production_path(productions(:main_production))
    assert_equal "ready_for_delivery", assigns(:tab)
  end

  test "delivery ignores invalid tab parameter and defaults to ready_for_delivery" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    get delivery_production_path(productions(:main_production)), params: { tab: "badtab" }
    assert_response :success
    assert_equal "ready_for_delivery", assigns(:tab)
  end

  test "delivery accepts taken_up tab" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    get delivery_production_path(productions(:main_production)), params: { tab: "taken_up" }
    assert_response :success
    assert_equal "taken_up", assigns(:tab)
  end

  test "delivery ignores distributed tab and defaults to ready_for_delivery" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    get delivery_production_path(productions(:main_production)), params: { tab: "distributed" }
    assert_response :success
    assert_equal "ready_for_delivery", assigns(:tab)
  end

  # --- inventory action ---

  test "inventory requires authentication" do
    get inventory_production_path(productions(:main_production))
    assert_redirected_to login_path
  end

  test "inventory returns 403 for distribution user" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    get inventory_production_path(productions(:main_production))
    assert_response :forbidden
  end

  test "inventory renders for production user" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    get inventory_production_path(productions(:main_production))
    assert_response :success
  end

  test "inventory creates inventory record if none exists" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    productions(:main_production).inventory&.destroy
    assert_difference "ProductionInventory.count", 1 do
      get inventory_production_path(productions(:main_production))
    end
  end

  # --- users action ---

  test "users requires authentication" do
    get users_production_path(productions(:main_production))
    assert_redirected_to login_path
  end

  test "users returns 403 for volunteer" do
    post login_path, params: { email: users(:prod_volunteer).email, password: "password" }
    get users_production_path(productions(:main_production))
    assert_response :forbidden
  end

  test "users renders for production admin" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    get users_production_path(productions(:main_production))
    assert_response :success
    assert_not_nil assigns(:members)
  end

  test "users renders for superadmin" do
    post login_path, params: { email: users(:superadmin).email, password: "password" }
    get users_production_path(productions(:main_production))
    assert_response :success
  end

  test "users search by full name finds unassigned user" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    get users_production_path(productions(:main_production)), params: { member_query: users(:no_location_user).name }
    assert_includes assigns(:member_search_results), users(:no_location_user)
  end

  test "users search by partial name finds matching unassigned users" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    get users_production_path(productions(:main_production)), params: { member_query: "No Location" }
    assert_includes assigns(:member_search_results), users(:no_location_user)
  end

  test "users search by email finds unassigned user" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    get users_production_path(productions(:main_production)), params: { member_query: users(:no_location_user).email }
    assert_includes assigns(:member_search_results), users(:no_location_user)
  end

  test "users search by partial email finds unassigned user" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    get users_production_path(productions(:main_production)), params: { member_query: "no_location" }
    assert_includes assigns(:member_search_results), users(:no_location_user)
  end

  test "users search is case-insensitive" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    get users_production_path(productions(:main_production)), params: { member_query: users(:no_location_user).name.upcase }
    assert_includes assigns(:member_search_results), users(:no_location_user)
  end

  test "users includes already-assigned users in search results" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    get users_production_path(productions(:main_production)), params: { member_query: users(:prod_admin).name }
    assert_includes assigns(:member_search_results), users(:prod_admin)
  end

  test "users search with no match returns empty results" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    get users_production_path(productions(:main_production)), params: { member_query: "zzznomatch" }
    assert_empty assigns(:member_search_results)
  end

  test "users search not run when query is blank" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    get users_production_path(productions(:main_production)), params: { member_query: "" }
    assert_nil assigns(:member_search_results)
  end

  test "users search can return multiple results" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    # dist_user and no_location_user both unassigned; search "user" matches both
    get users_production_path(productions(:main_production)), params: { member_query: "user" }
    results = assigns(:member_search_results)
    assert_includes results, users(:no_location_user)
    assert_includes results, users(:dist_user)
  end

  # --- members action ---

  test "members requires authentication" do
    get members_production_path(productions(:main_production)), params: { q: "admin" }
    assert_redirected_to login_path
  end

  test "members returns 403 for user without production access" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    get members_production_path(productions(:main_production)), params: { q: "admin" }
    assert_response :forbidden
  end

  test "members returns matching master mechanics as JSON" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    get members_production_path(productions(:main_production)), params: { q: "Master Mechanic" }
    assert_response :success
    result = JSON.parse(response.body)
    assert_equal 1, result.length
    assert_equal users(:master_mechanic_user).id, result.first["id"]
    assert_equal users(:master_mechanic_user).name, result.first["name"]
  end

  test "members returns matching admins as JSON" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    get members_production_path(productions(:main_production)), params: { q: "Production Admin" }
    assert_response :success
    result = JSON.parse(response.body)
    assert_equal 1, result.length
    assert_equal users(:prod_admin).id, result.first["id"]
  end

  test "members does not return volunteers" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    get members_production_path(productions(:main_production)), params: { q: "Production Volunteer" }
    assert_response :success
    result = JSON.parse(response.body)
    assert_empty result
  end

  test "members does not return users outside the production" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    get members_production_path(productions(:main_production)), params: { q: "Distribution User" }
    assert_response :success
    result = JSON.parse(response.body)
    assert_empty result
  end

  # --- distributions_search action ---

  test "distributions_search requires authentication" do
    get distributions_search_production_path(productions(:main_production)), params: { q: "Downtown" }
    assert_redirected_to login_path
  end

  test "distributions_search returns 403 for a plain volunteer" do
    post login_path, params: { email: users(:prod_volunteer).email, password: "password" }
    get distributions_search_production_path(productions(:main_production)), params: { q: "Downtown" }
    assert_response :forbidden
  end

  test "distributions_search returns matching distributions as JSON for an admin" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    get distributions_search_production_path(productions(:main_production)), params: { q: "Downtown" }
    assert_response :success
    result = JSON.parse(response.body)
    assert_equal 1, result.length
    assert_equal distributions(:downtown_dist).id, result.first["id"]
    assert_equal distributions(:downtown_dist).name, result.first["name"]
  end

  test "distributions_search returns matching distributions as JSON for a master mechanic" do
    post login_path, params: { email: users(:master_mechanic_user).email, password: "password" }
    get distributions_search_production_path(productions(:main_production)), params: { q: "Uptown" }
    assert_response :success
    result = JSON.parse(response.body)
    assert_equal 1, result.length
    assert_equal distributions(:uptown_dist).id, result.first["id"]
  end

  test "distributions_search does not match unrelated names" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    get distributions_search_production_path(productions(:main_production)), params: { q: "Nonexistent" }
    assert_response :success
    result = JSON.parse(response.body)
    assert_empty result
  end

  # --- your_tickets action ---

  test "your_tickets requires authentication" do
    get your_tickets_production_path(productions(:main_production))
    assert_redirected_to login_path
  end

  test "your_tickets renders for production admin who is not a master mechanic" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    get your_tickets_production_path(productions(:main_production))
    assert_response :success
  end

  test "your_tickets returns 403 for production volunteer" do
    post login_path, params: { email: users(:prod_volunteer).email, password: "password" }
    get your_tickets_production_path(productions(:main_production))
    assert_response :forbidden
  end

  test "your_tickets returns 403 for distribution user" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    get your_tickets_production_path(productions(:main_production))
    assert_response :forbidden
  end

  test "your_tickets renders for master mechanic" do
    post login_path, params: { email: users(:master_mechanic_user).email, password: "password" }
    get your_tickets_production_path(productions(:main_production))
    assert_response :success
  end

  test "your_tickets renders for superadmin without explicit master mechanic role" do
    post login_path, params: { email: users(:superadmin).email, password: "password" }
    get your_tickets_production_path(productions(:main_production))
    assert_response :success
  end

  test "your_tickets defaults to pending tab" do
    post login_path, params: { email: users(:master_mechanic_user).email, password: "password" }
    get your_tickets_production_path(productions(:main_production))
    assert_equal "pending", assigns(:tab)
  end

  test "your_tickets ignores requested tab and defaults to pending" do
    post login_path, params: { email: users(:master_mechanic_user).email, password: "password" }
    get your_tickets_production_path(productions(:main_production)), params: { tab: "requested" }
    assert_equal "pending", assigns(:tab)
  end

  test "your_tickets ignores invalid tab and defaults to pending" do
    post login_path, params: { email: users(:master_mechanic_user).email, password: "password" }
    get your_tickets_production_path(productions(:main_production)), params: { tab: "badtab" }
    assert_equal "pending", assigns(:tab)
  end

  test "your_tickets accepts delivery statuses as tabs" do
    bike_requests(:taken_up_bike).update_columns(owner_id: users(:master_mechanic_user).id)
    post login_path, params: { email: users(:master_mechanic_user).email, password: "password" }
    get your_tickets_production_path(productions(:main_production)), params: { tab: "taken_up" }
    assert_response :success
    assert_equal "taken_up", assigns(:tab)
    assert_includes assigns(:bike_requests), bike_requests(:taken_up_bike)
  end

  test "your_tickets only shows requests owned by the current user" do
    bike_requests(:taken_up_bike).update_columns(owner_id: users(:prod_admin).id)
    post login_path, params: { email: users(:master_mechanic_user).email, password: "password" }
    get your_tickets_production_path(productions(:main_production)), params: { tab: "taken_up" }
    assert_not_includes assigns(:bike_requests), bike_requests(:taken_up_bike)
  end

  test "your_tickets tab_counts only reflect the current user's owned requests" do
    bike_requests(:taken_up_bike).update_columns(owner_id: users(:prod_admin).id)
    post login_path, params: { email: users(:master_mechanic_user).email, password: "password" }
    get your_tickets_production_path(productions(:main_production))
    assert_equal 0, assigns(:tab_counts)["taken_up"].to_i
  end

  test "your_tickets tab_counts excludes requested" do
    post login_path, params: { email: users(:master_mechanic_user).email, password: "password" }
    get your_tickets_production_path(productions(:main_production))
    assert_not_includes assigns(:tab_counts).keys, "requested"
  end
end
