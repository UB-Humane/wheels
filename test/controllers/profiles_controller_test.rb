require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  def login_as(user)
    post login_path, params: { email: user.email, password: "password" }
  end

  # --- edit ---

  test "edit requires authentication" do
    get edit_profile_path
    assert_redirected_to login_path
  end

  test "edit renders form for the logged-in user" do
    login_as(users(:prod_admin))
    get edit_profile_path
    assert_response :success
  end

  # --- update ---

  test "update requires authentication" do
    patch profile_path, params: { user: { name: "Changed" } }
    assert_redirected_to login_path
  end

  test "update changes the current user's attributes" do
    user = users(:prod_admin)
    login_as(user)
    patch profile_path, params: { user: { name: "Updated Name", email: user.email } }
    assert_redirected_to edit_profile_path
    assert_equal "Updated Name", user.reload.name
  end

  test "update cannot change another user's attributes" do
    user = users(:prod_admin)
    other = users(:dist_user)
    login_as(user)
    patch profile_path, params: { user: { name: "Hijacked", email: user.email } }
    assert_not_equal "Hijacked", other.reload.name
  end

  test "update with blank password does not change password" do
    user = users(:prod_admin)
    login_as(user)
    old_digest = user.password_digest
    patch profile_path, params: { user: { name: user.name, email: user.email, password: "" } }
    assert_redirected_to edit_profile_path
    assert_equal old_digest, user.reload.password_digest
  end

  test "update with new password changes password" do
    user = users(:prod_admin)
    login_as(user)
    patch profile_path, params: { user: { name: user.name, email: user.email, password: "newpassword", password_confirmation: "newpassword" } }
    assert_redirected_to edit_profile_path
    assert user.reload.authenticate("newpassword")
  end

  test "update with invalid params re-renders edit" do
    user = users(:prod_admin)
    login_as(user)
    patch profile_path, params: { user: { name: "", email: "" } }
    assert_response :unprocessable_entity
  end

  test "update sets mobile_number" do
    user = users(:prod_admin)
    login_as(user)
    patch profile_path, params: { user: { name: user.name, email: user.email, mobile_number: "5551234567" } }
    assert_redirected_to edit_profile_path
    assert_equal "5551234567", user.reload.mobile_number
  end

  test "update with invalid mobile_number re-renders edit" do
    user = users(:prod_admin)
    login_as(user)
    patch profile_path, params: { user: { name: user.name, email: user.email, mobile_number: "not a number" } }
    assert_response :unprocessable_entity
  end

  test "update cannot set superadmin flag" do
    user = users(:prod_admin)
    login_as(user)
    patch profile_path, params: { user: { name: user.name, email: user.email, superadmin: true } }
    assert_not user.reload.superadmin?
  end
end
