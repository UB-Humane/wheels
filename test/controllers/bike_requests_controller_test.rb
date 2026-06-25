require "test_helper"

class BikeRequestsControllerTest < ActionDispatch::IntegrationTest
  # --- new ---

  test "new requires authentication" do
    get new_distribution_bike_request_path(distributions(:downtown_dist))
    assert_redirected_to login_path
  end

  test "new returns 403 for user without distribution access" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    get new_distribution_bike_request_path(distributions(:downtown_dist))
    assert_response :forbidden
  end

  test "new renders form for authorized distribution user" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    get new_distribution_bike_request_path(distributions(:downtown_dist))
    assert_response :success
  end

  test "new pre-populates due_date to two weeks from today" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    get new_distribution_bike_request_path(distributions(:downtown_dist))
    assert_equal Date.today + 14, assigns(:bike_request).due_date
  end

  # --- create ---

  test "create requires authentication" do
    post distribution_bike_requests_path(distributions(:downtown_dist)),
         params: { bike_request: valid_bike_request_params }
    assert_redirected_to login_path
  end

  test "create returns 403 for user without distribution access" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    post distribution_bike_requests_path(distributions(:downtown_dist)),
         params: { bike_request: valid_bike_request_params }
    assert_response :forbidden
  end

  test "create saves record and redirects to distribution" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    assert_difference "BikeRequest.count", 1 do
      post distribution_bike_requests_path(distributions(:downtown_dist)),
           params: { bike_request: valid_bike_request_params }
    end
    assert_redirected_to tickets_distribution_path(distributions(:downtown_dist))
  end

  test "create sets status to pending" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    post distribution_bike_requests_path(distributions(:downtown_dist)),
         params: { bike_request: valid_bike_request_params }
    assert BikeRequest.last.pending?
  end

  test "create saves nested bikes" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    assert_difference "Bike.count", 2 do
      post distribution_bike_requests_path(distributions(:downtown_dist)),
           params: { bike_request: valid_bike_request_params_with_two_bikes }
    end
  end

  test "create assigns current user as submitter" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    post distribution_bike_requests_path(distributions(:downtown_dist)),
         params: { bike_request: valid_bike_request_params }
    assert_equal users(:dist_user), BikeRequest.last.user
  end

  test "create assigns distribution from URL" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    post distribution_bike_requests_path(distributions(:downtown_dist)),
         params: { bike_request: valid_bike_request_params }
    assert_equal distributions(:downtown_dist), BikeRequest.last.distribution
  end

  test "create with invalid params re-renders new form" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    assert_no_difference "BikeRequest.count" do
      post distribution_bike_requests_path(distributions(:downtown_dist)),
           params: { bike_request: { phone: "", requestor_name: "", due_date: "" } }
    end
    assert_response :unprocessable_entity
  end

  # --- edit ---

  test "edit requires authentication" do
    get edit_bike_request_path(bike_requests(:pending_bike))
    assert_redirected_to login_path
  end

  test "edit returns 403 for user without distribution access" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    get edit_bike_request_path(bike_requests(:pending_bike))
    assert_response :forbidden
  end

  test "edit renders form for authorized distribution user on pending card" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    get edit_bike_request_path(bike_requests(:pending_bike))
    assert_response :success
  end

  test "edit renders form for authorized distribution user on denied card" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    get edit_bike_request_path(bike_requests(:denied_bike))
    assert_response :success
  end

  # --- update: production approve/deny ---

  test "update approve requires authentication" do
    patch bike_request_path(bike_requests(:pending_bike)), params: { status: "approve" }
    assert_redirected_to login_path
  end

  test "update approve returns 403 for user without production access" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    patch bike_request_path(bike_requests(:pending_bike)), params: { status: "approve" }
    assert_response :forbidden
  end

  test "update approve sets status to requested" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:pending_bike)), params: { status: "approve" }
    assert bike_requests(:pending_bike).reload.requested?
  end

  test "update approve redirects to production requested tab" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:pending_bike)), params: { status: "approve" }
    assert_redirected_to tickets_production_path(productions(:main_production), tab: "requested")
  end

  test "update deny sets status to denied" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:pending_bike)), params: { status: "deny" }
    assert bike_requests(:pending_bike).reload.denied?
  end

  test "update deny redirects to production pending tab" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:pending_bike)), params: { status: "deny" }
    assert_redirected_to tickets_production_path(productions(:main_production), tab: "pending")
  end

  test "update delivered sets status to delivered" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:completed_bike)), params: { status: "delivered" }
    assert bike_requests(:completed_bike).reload.delivered?
  end

  test "update distributed sets status to distributed" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:completed_bike)), params: { status: "distributed" }
    assert bike_requests(:completed_bike).reload.distributed?
  end

  test "update completed sets status to completed" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:requested_bike)), params: { status: "completed" }
    assert bike_requests(:requested_bike).reload.completed?
  end

  test "update delivered from completed sets status to delivered" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:completed_bike)), params: { status: "delivered" }
    assert bike_requests(:completed_bike).reload.delivered?
  end

  test "update back to completed from delivered" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    br = bike_requests(:completed_bike)
    br.update_columns(status: BikeRequest.statuses[:delivered])
    patch bike_request_path(br), params: { status: "completed" }
    assert br.reload.completed?
  end

  test "update back to delivered from distributed" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    br = bike_requests(:completed_bike)
    br.update_columns(status: BikeRequest.statuses[:distributed])
    patch bike_request_path(br), params: { status: "delivered" }
    assert br.reload.delivered?
  end

  test "update redirects to production path with tab param" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:completed_bike)), params: { status: "delivered" }
    assert_redirected_to tickets_production_path(productions(:main_production), tab: "delivered")
  end

  # --- update: distribution resubmit ---

  test "resubmit requires authentication" do
    patch bike_request_path(bike_requests(:denied_bike)),
          params: { bike_request: resubmit_params }
    assert_redirected_to login_path
  end

  test "resubmit returns 403 for user without distribution access" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:denied_bike)),
          params: { bike_request: resubmit_params }
    assert_response :forbidden
  end

  test "resubmit sets status to pending" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    patch bike_request_path(bike_requests(:denied_bike)),
          params: { bike_request: resubmit_params }
    assert bike_requests(:denied_bike).reload.pending?
  end

  test "resubmit updates bike request fields" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    patch bike_request_path(bike_requests(:denied_bike)),
          params: { bike_request: resubmit_params }
    assert_equal "Updated Name", bike_requests(:denied_bike).reload.requestor_name
  end

  test "resubmit redirects to distribution pending tab" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    patch bike_request_path(bike_requests(:denied_bike)),
          params: { bike_request: resubmit_params }
    assert_redirected_to tickets_distribution_path(distributions(:downtown_dist), tab: "pending")
  end

  test "resubmit on pending card also sets pending" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    patch bike_request_path(bike_requests(:pending_bike)),
          params: { bike_request: resubmit_params }
    assert bike_requests(:pending_bike).reload.pending?
  end

  private

  def valid_bike_request_params
    {
      phone: "5555550001",
      requestor_name: "New Person",
      due_date: (Date.today + 14).to_s,
      bikes_attributes: { "0" => { bike_type: "male" } }
    }
  end

  def valid_bike_request_params_with_two_bikes
    {
      phone: "5555550002",
      requestor_name: "Two Bikes",
      due_date: (Date.today + 14).to_s,
      bikes_attributes: {
        "0" => { bike_type: "male", name: "Alice" },
        "1" => { bike_type: "female", name: "Bob" }
      }
    }
  end

  def resubmit_params
    {
      phone: "5555550099",
      requestor_name: "Updated Name",
      due_date: (Date.today + 14).to_s,
      bikes_attributes: {}
    }
  end
end
