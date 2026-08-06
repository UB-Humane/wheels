require "test_helper"

class MobileNumbersControllerTest < ActionDispatch::IntegrationTest
  def login_as(user)
    post login_path, params: { email: user.email, password: "password" }
  end

  test "edit requires authentication" do
    get edit_mobile_number_path
    assert_redirected_to login_path
  end

  test "edit renders for a logged-in user" do
    login_as(users(:prod_admin))
    get edit_mobile_number_path
    assert_response :success
  end

  test "update sets the mobile number and redirects to root" do
    user = users(:prod_admin)
    login_as(user)
    patch mobile_number_path, params: { user: { mobile_number: "5559876543" } }
    assert_redirected_to root_path
    assert_equal "5559876543", user.reload.mobile_number
  end

  test "update with a blank number re-renders with an error and does not change the record" do
    user = users(:prod_admin)
    login_as(user)
    old_number = user.mobile_number
    patch mobile_number_path, params: { user: { mobile_number: "" } }
    assert_response :unprocessable_entity
    assert_equal old_number, user.reload.mobile_number
  end

  test "update with an invalid format re-renders with the model's error" do
    user = users(:prod_admin)
    login_as(user)
    patch mobile_number_path, params: { user: { mobile_number: "not a number" } }
    assert_response :unprocessable_entity
    assert_not_equal "not a number", user.reload.mobile_number
  end
end
