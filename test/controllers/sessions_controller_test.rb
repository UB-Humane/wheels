require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "GET /login renders login form" do
    get login_path
    assert_response :success
  end

  test "GET /login redirects to root if already logged in" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    get login_path
    assert_redirected_to root_path
  end

  test "POST /login with valid credentials sets session and redirects" do
    user = users(:prod_admin)
    post login_path, params: { email: user.email, password: "password" }
    assert_redirected_to root_path
    assert_equal user.id, session[:user_id]
  end

  test "POST /login with invalid password re-renders form without setting session" do
    user = users(:prod_admin)
    post login_path, params: { email: user.email, password: "wrong" }
    assert_response :unprocessable_entity
    assert_nil session[:user_id]
  end

  test "POST /login with unknown email re-renders form without setting session" do
    post login_path, params: { email: "nobody@example.com", password: "password" }
    assert_response :unprocessable_entity
    assert_nil session[:user_id]
  end

  test "POST /login single-production user follows redirect to production dashboard" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    follow_redirect!
    assert_redirected_to production_path(productions(:main_production))
  end

  test "POST /login single-distribution user follows redirect to distribution dashboard" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    follow_redirect!
    assert_redirected_to distribution_path(distributions(:downtown_dist))
  end

  test "POST /login multi-location user stays on home page" do
    post login_path, params: { email: users(:multi_user).email, password: "password" }
    follow_redirect!
    assert_response :success
  end

  test "POST /login superadmin lands on home page" do
    post login_path, params: { email: users(:superadmin).email, password: "password" }
    follow_redirect!
    assert_response :success
  end

  test "DELETE /logout clears session and redirects to login" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    assert_not_nil session[:user_id]

    delete logout_path
    assert_redirected_to login_path
    assert_nil session[:user_id]
  end

  test "DELETE /logout works even when the user has no mobile number" do
    user = users(:prod_admin)
    user.update_columns(mobile_number: nil)
    post login_path, params: { email: user.email, password: "password" }
    assert_not_nil session[:user_id]

    delete logout_path
    assert_redirected_to login_path
    assert_nil session[:user_id]
  end

  # --- GET /auth/google_oauth2/callback ---

  test "omniauth callback logs in an existing user matched by email" do
    user = users(:prod_admin)
    mock_google_auth(email: user.email)
    get "/auth/google_oauth2/callback"
    assert_redirected_to root_path
    assert_equal user.id, session[:user_id]
  end

  test "omniauth callback does not create a duplicate user for an existing email" do
    mock_google_auth(email: users(:prod_admin).email)
    assert_no_difference "User.count" do
      get "/auth/google_oauth2/callback"
    end
  end

  test "omniauth callback creates a new user when no email match exists" do
    mock_google_auth(email: "newperson@example.com", name: "New Person")
    assert_difference "User.count", 1 do
      get "/auth/google_oauth2/callback"
    end
    user = User.find_by(email: "newperson@example.com")
    assert_equal "New Person", user.name
    assert_equal user.id, session[:user_id]
    assert_redirected_to root_path
  end

  test "omniauth callback falls back to email as name when Google provides no name" do
    mock_google_auth(email: "noname@example.com", name: "")
    get "/auth/google_oauth2/callback"
    assert_equal "noname@example.com", User.find_by(email: "noname@example.com").name
  end

  test "omniauth callback new user has no location assignments" do
    mock_google_auth(email: "newperson2@example.com")
    get "/auth/google_oauth2/callback"
    assert_empty User.find_by(email: "newperson2@example.com").all_locations
  end

  test "omniauth callback new user gets a usable password digest" do
    mock_google_auth(email: "newperson3@example.com")
    get "/auth/google_oauth2/callback"
    assert User.find_by(email: "newperson3@example.com").password_digest.present?
  end

  # --- GET /auth/failure ---

  test "omniauth failure redirects to login with an alert" do
    get "/auth/failure"
    assert_redirected_to login_path
    assert_equal "Google sign-in failed. Please try again.", flash[:alert]
  end

  private

  def mock_google_auth(email:, name: "Google User")
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "12345",
      info: { email: email, name: name }
    )
  end
end
