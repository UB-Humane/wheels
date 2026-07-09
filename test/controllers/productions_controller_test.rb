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
      phone: "5550000001", requestor_name: "Other", due_date: 10.days.from_now,
      distribution: distributions(:downtown_dist),
      production: other_prod, user: users(:dist_user)
    )
    get tickets_production_path(productions(:main_production)), params: { tab: "requested" }
    assert_response :success
    assert_not assigns(:bike_requests).include?(other_request)
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
end
