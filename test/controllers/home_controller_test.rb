require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "unauthenticated request redirects to login" do
    get root_path
    assert_redirected_to login_path
  end

  test "superadmin with no location assignments sees home page with admin panel link" do
    post login_path, params: { email: users(:superadmin).email, password: "password" }
    get root_path
    assert_response :success
    assert_match admin_root_path, response.body
  end

  test "single-location production user redirects to production dashboard" do
    user = users(:prod_admin)
    post login_path, params: { email: user.email, password: "password" }
    get root_path
    assert_redirected_to production_path(productions(:main_production))
  end

  test "single-location distribution user redirects to distribution dashboard" do
    user = users(:dist_user)
    post login_path, params: { email: user.email, password: "password" }
    get root_path
    assert_redirected_to distribution_path(distributions(:downtown_dist))
  end

  test "multi-location user renders home page" do
    user = users(:multi_user)
    post login_path, params: { email: user.email, password: "password" }
    get root_path
    assert_response :success
  end

  test "user with no location assignments sees pending message" do
    post login_path, params: { email: users(:no_location_user).email, password: "password" }
    get root_path
    assert_response :success
    assert_match "no location assignments", response.body
  end

  test "superadmin sees all productions on home page" do
    post login_path, params: { email: users(:superadmin).email, password: "password" }
    get root_path
    assert_equal Production.count, assigns(:productions).count
  end

  test "superadmin sees all distributions on home page" do
    post login_path, params: { email: users(:superadmin).email, password: "password" }
    get root_path
    assert_equal Distribution.count, assigns(:distributions).count
  end

  test "superadmin with a location assignment renders home page with both location and admin panel link" do
    user = users(:superadmin_with_location)
    post login_path, params: { email: user.email, password: "password" }
    get root_path
    assert_response :success
    assert_match admin_root_path, response.body
  end

  test "renders the install-to-home-screen banner" do
    post login_path, params: { email: users(:superadmin).email, password: "password" }
    get root_path
    assert_select "#install-banner"
  end
end
