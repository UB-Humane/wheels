require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  def login_as_superadmin
    post login_path, params: { email: users(:superadmin).email, password: "password" }
  end

  def login_as_regular_user
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
  end

  # --- index ---

  test "index requires authentication" do
    get admin_users_path
    assert_redirected_to login_path
  end

  test "index returns 403 for non-superadmin" do
    login_as_regular_user
    get admin_users_path
    assert_response :forbidden
  end

  test "index lists all users for superadmin" do
    login_as_superadmin
    get admin_users_path
    assert_response :success
  end

  # --- new ---

  test "new requires superadmin" do
    login_as_regular_user
    get new_admin_user_path
    assert_response :forbidden
  end

  test "new renders form for superadmin" do
    login_as_superadmin
    get new_admin_user_path
    assert_response :success
  end

  # --- create ---

  test "create requires superadmin" do
    login_as_regular_user
    post admin_users_path, params: { user: new_user_params }
    assert_response :forbidden
  end

  test "create saves user and redirects to index" do
    login_as_superadmin
    assert_difference "User.count", 1 do
      post admin_users_path, params: { user: new_user_params }
    end
    assert_redirected_to admin_users_path
  end

  test "create with invalid params re-renders new form" do
    login_as_superadmin
    assert_no_difference "User.count" do
      post admin_users_path, params: { user: { name: "", email: "", password: "p", password_confirmation: "p" } }
    end
    assert_response :unprocessable_entity
  end

  test "create builds user with production assignment when enabled" do
    login_as_superadmin
    prod = productions(:main_production)
    params = new_user_params
    assert_difference "UserProduction.count", 1 do
      post admin_users_path, params: {
        user: params,
        production_access_enabled: { prod.id => "1" },
        production_access_role: { prod.id => "volunteer" }
      }
    end
    user = User.find_by(email: params[:email])
    assert_not_nil user
    assert_includes user.productions, prod
  end

  test "create skips production assignment when not enabled" do
    login_as_superadmin
    assert_no_difference "UserProduction.count" do
      post admin_users_path, params: { user: new_user_params }
    end
  end

  test "create builds user with distribution assignment when enabled" do
    login_as_superadmin
    dist = distributions(:downtown_dist)
    params = new_user_params
    assert_difference "UserDistribution.count", 1 do
      post admin_users_path, params: {
        user: params,
        distribution_access_enabled: { dist.id => "1" },
        distribution_access_role: { dist.id => "admin" }
      }
    end
    user = User.find_by(email: params[:email])
    assert_not_nil user
    assert_includes user.distributions, dist
  end

  test "create skips location assignments for superadmin user" do
    login_as_superadmin
    prod = productions(:main_production)
    params = new_user_params.merge(superadmin: true)
    assert_no_difference "UserProduction.count" do
      post admin_users_path, params: {
        user: params,
        production_access_enabled: { prod.id => "1" },
        production_access_role: { prod.id => "volunteer" }
      }
    end
  end

  test "update skips location assignments for superadmin user" do
    login_as_superadmin
    prod = productions(:main_production)
    assert_no_difference "UserProduction.count" do
      patch admin_user_path(users(:superadmin)), params: {
        user: { name: users(:superadmin).name, email: users(:superadmin).email },
        production_access_enabled: { prod.id => "1" },
        production_access_role: { prod.id => "volunteer" }
      }
    end
  end

  # --- edit ---

  test "edit requires superadmin" do
    login_as_regular_user
    get edit_admin_user_path(users(:no_location_user))
    assert_response :forbidden
  end

  test "edit renders form for superadmin" do
    login_as_superadmin
    get edit_admin_user_path(users(:no_location_user))
    assert_response :success
  end

  # --- update ---

  test "update requires superadmin" do
    login_as_regular_user
    patch admin_user_path(users(:no_location_user)), params: { user: { name: "Changed" } }
    assert_response :forbidden
  end

  test "update changes user attributes" do
    login_as_superadmin
    user = users(:no_location_user)
    patch admin_user_path(user), params: { user: { name: "Updated Name", email: user.email } }
    assert_redirected_to admin_users_path
    assert_equal "Updated Name", user.reload.name
  end

  test "update with blank password does not change password" do
    login_as_superadmin
    user = users(:no_location_user)
    old_digest = user.password_digest
    patch admin_user_path(user), params: { user: { name: user.name, email: user.email, password: "" } }
    assert_redirected_to admin_users_path
    assert_equal old_digest, user.reload.password_digest
  end

  test "update with new password changes password" do
    login_as_superadmin
    user = users(:no_location_user)
    patch admin_user_path(user), params: { user: { name: user.name, email: user.email, password: "newpassword" } }
    assert_redirected_to admin_users_path
    assert user.reload.authenticate("newpassword")
  end

  test "update replaces location assignments" do
    login_as_superadmin
    user = users(:prod_admin)
    dist = distributions(:downtown_dist)
    assert_difference "UserDistribution.count", 1 do
      patch admin_user_path(user), params: {
        user: { name: user.name, email: user.email },
        distribution_access_enabled: { dist.id => "1" },
        distribution_access_role: { dist.id => "volunteer" }
      }
    end
    assert_includes user.reload.distributions, dist
  end

  test "update with invalid params re-renders edit" do
    login_as_superadmin
    patch admin_user_path(users(:no_location_user)), params: { user: { name: "", email: "" } }
    assert_response :unprocessable_entity
  end

  test "update sets mobile_number" do
    login_as_superadmin
    user = users(:no_location_user)
    patch admin_user_path(user), params: { user: { name: user.name, email: user.email, mobile_number: "5551234567" } }
    assert_redirected_to admin_users_path
    assert_equal "5551234567", user.reload.mobile_number
  end

  # --- destroy ---

  test "destroy requires superadmin" do
    login_as_regular_user
    delete admin_user_path(users(:no_location_user))
    assert_response :forbidden
  end

  test "destroy removes user and redirects to index" do
    login_as_superadmin
    user = User.create!(name: "Temp User", email: "tempdelete@example.com", password: "password")
    assert_difference "User.count", -1 do
      delete admin_user_path(user)
    end
    assert_redirected_to admin_users_path
  end

  test "destroy does not allow superadmin to delete themselves" do
    login_as_superadmin
    assert_no_difference "User.count" do
      delete admin_user_path(users(:superadmin))
    end
  end

  private

  def new_user_params
    {
      name: "Brand New User",
      email: "brandnew_#{SecureRandom.hex(4)}@example.com",
      password: "password",
      password_confirmation: "password",
      superadmin: false
    }
  end
end
