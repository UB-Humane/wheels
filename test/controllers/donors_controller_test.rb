require "test_helper"

class DonorsControllerTest < ActionDispatch::IntegrationTest
  def login_as_prod_admin
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
  end

  def login_as_prod_volunteer
    post login_path, params: { email: users(:prod_volunteer).email, password: "password" }
  end

  def login_as_dist_user
    post login_path, params: { email: users(:dist_user).email, password: "password" }
  end

  def production
    productions(:main_production)
  end

  # --- index ---

  test "index requires authentication" do
    get production_donors_path(production)
    assert_redirected_to login_path
  end

  test "index returns 403 for production volunteer" do
    login_as_prod_volunteer
    get production_donors_path(production)
    assert_response :forbidden
  end

  test "index returns 403 for distribution user" do
    login_as_dist_user
    get production_donors_path(production)
    assert_response :forbidden
  end

  test "index renders for production admin" do
    login_as_prod_admin
    get production_donors_path(production)
    assert_response :success
  end

  test "index shows only active donors by default" do
    login_as_prod_admin
    get production_donors_path(production)
    assert_includes assigns(:donors), donors(:active_donor)
    assert_not_includes assigns(:donors), donors(:archived_donor)
  end

  test "index shows archived donors when requested" do
    login_as_prod_admin
    get production_donors_path(production, archived: true)
    assert_includes assigns(:donors), donors(:archived_donor)
    assert_not_includes assigns(:donors), donors(:active_donor)
  end

  test "index search by first name finds donor" do
    login_as_prod_admin
    get production_donors_path(production, query: "Jane")
    assert_includes assigns(:donors), donors(:active_donor)
    assert_not_includes assigns(:donors), donors(:minimal_donor)
  end

  test "index search by full name finds donor" do
    login_as_prod_admin
    get production_donors_path(production, query: "Jane Doe")
    assert_includes assigns(:donors), donors(:active_donor)
  end

  test "index search by email finds donor" do
    login_as_prod_admin
    get production_donors_path(production, query: "jane@example.com")
    assert_includes assigns(:donors), donors(:active_donor)
  end

  test "index search is case-insensitive" do
    login_as_prod_admin
    get production_donors_path(production, query: "JANE")
    assert_includes assigns(:donors), donors(:active_donor)
  end

  test "index search with no match returns empty list" do
    login_as_prod_admin
    get production_donors_path(production, query: "zzznomatch")
    assert_empty assigns(:donors)
  end

  # --- new ---

  test "new requires authentication" do
    get new_production_donor_path(production)
    assert_redirected_to login_path
  end

  test "new returns 403 for production volunteer" do
    login_as_prod_volunteer
    get new_production_donor_path(production)
    assert_response :forbidden
  end

  test "new returns 403 for distribution user" do
    login_as_dist_user
    get new_production_donor_path(production)
    assert_response :forbidden
  end

  test "new renders for production admin" do
    login_as_prod_admin
    get new_production_donor_path(production)
    assert_response :success
  end

  # --- create ---

  test "create requires authentication" do
    post production_donors_path(production), params: { donor: { first_name: "Test", last_name: "Person" } }
    assert_redirected_to login_path
  end

  test "create returns 403 for production volunteer" do
    login_as_prod_volunteer
    post production_donors_path(production), params: { donor: { first_name: "New", last_name: "Donor" } }
    assert_response :forbidden
  end

  test "create returns 403 for distribution user" do
    login_as_dist_user
    post production_donors_path(production), params: { donor: { first_name: "New", last_name: "Donor" } }
    assert_response :forbidden
  end

  test "create saves donor and redirects" do
    login_as_prod_admin
    assert_difference "Donor.count", 1 do
      post production_donors_path(production), params: { donor: { first_name: "New", last_name: "Donor" } }
    end
    assert_redirected_to production_donors_path(production)
  end

  test "create assigns donor to production" do
    login_as_prod_admin
    post production_donors_path(production), params: { donor: { first_name: "New", last_name: "Donor" } }
    assert_equal production, Donor.last.production
  end

  test "create with missing first name re-renders new" do
    login_as_prod_admin
    assert_no_difference "Donor.count" do
      post production_donors_path(production), params: { donor: { first_name: "", last_name: "Donor" } }
    end
    assert_response :unprocessable_entity
  end

  test "create with missing last name re-renders new" do
    login_as_prod_admin
    assert_no_difference "Donor.count" do
      post production_donors_path(production), params: { donor: { first_name: "New", last_name: "" } }
    end
    assert_response :unprocessable_entity
  end

  # --- edit ---

  test "edit requires authentication" do
    get edit_production_donor_path(production, donors(:active_donor))
    assert_redirected_to login_path
  end

  test "edit returns 403 for production volunteer" do
    login_as_prod_volunteer
    get edit_production_donor_path(production, donors(:active_donor))
    assert_response :forbidden
  end

  test "edit returns 403 for distribution user" do
    login_as_dist_user
    get edit_production_donor_path(production, donors(:active_donor))
    assert_response :forbidden
  end

  test "edit renders for production admin" do
    login_as_prod_admin
    get edit_production_donor_path(production, donors(:active_donor))
    assert_response :success
  end

  # --- update ---

  test "update requires authentication" do
    patch production_donor_path(production, donors(:active_donor)), params: { donor: { first_name: "Updated" } }
    assert_redirected_to login_path
  end

  test "update returns 403 for production volunteer" do
    login_as_prod_volunteer
    patch production_donor_path(production, donors(:active_donor)), params: { donor: { first_name: "Updated", last_name: "Doe" } }
    assert_response :forbidden
  end

  test "update returns 403 for distribution user" do
    login_as_dist_user
    patch production_donor_path(production, donors(:active_donor)), params: { donor: { first_name: "Updated", last_name: "Doe" } }
    assert_response :forbidden
  end

  test "update saves changes and redirects" do
    login_as_prod_admin
    patch production_donor_path(production, donors(:active_donor)),
          params: { donor: { first_name: "Updated", last_name: "Doe" } }
    assert_equal "Updated", donors(:active_donor).reload.first_name
    assert_redirected_to production_donors_path(production)
  end

  test "update with invalid params re-renders edit" do
    login_as_prod_admin
    patch production_donor_path(production, donors(:active_donor)),
          params: { donor: { first_name: "", last_name: "Doe" } }
    assert_response :unprocessable_entity
  end

  # --- archive ---

  test "archive sets archived to true" do
    login_as_prod_admin
    patch production_donor_path(production, donors(:active_donor)), params: { archive: true }
    assert donors(:active_donor).reload.archived?
  end

  test "archive redirects to active donors list" do
    login_as_prod_admin
    patch production_donor_path(production, donors(:active_donor)), params: { archive: true }
    assert_redirected_to production_donors_path(production)
  end

  # --- unarchive ---

  test "unarchive sets archived to false" do
    login_as_prod_admin
    patch production_donor_path(production, donors(:archived_donor)), params: { unarchive: true }
    assert_not donors(:archived_donor).reload.archived?
  end

  test "unarchive redirects to archived donors list" do
    login_as_prod_admin
    patch production_donor_path(production, donors(:archived_donor)), params: { unarchive: true }
    assert_redirected_to production_donors_path(production, archived: true)
  end
end
