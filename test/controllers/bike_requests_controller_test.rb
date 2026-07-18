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

  test "create sets status to requested" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    post distribution_bike_requests_path(distributions(:downtown_dist)),
         params: { bike_request: valid_bike_request_params }
    assert BikeRequest.last.requested?
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

  # --- new/create: production request ---

  test "new production request requires authentication" do
    get new_production_bike_request_path(productions(:main_production))
    assert_redirected_to login_path
  end

  test "new production request returns 403 for distribution user" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    get new_production_bike_request_path(productions(:main_production))
    assert_response :forbidden
  end

  test "new production request renders for production user" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    get new_production_bike_request_path(productions(:main_production))
    assert_response :success
  end

  test "create production request saves record" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    assert_difference "BikeRequest.count", 1 do
      post production_bike_requests_path(productions(:main_production)),
           params: { bike_request: valid_bike_request_params }
    end
  end

  test "create production request sets status to pending" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    post production_bike_requests_path(productions(:main_production)),
         params: { bike_request: valid_bike_request_params }
    assert BikeRequest.last.pending?
  end

  test "create production request assigns production" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    post production_bike_requests_path(productions(:main_production)),
         params: { bike_request: valid_bike_request_params }
    assert_equal productions(:main_production), BikeRequest.last.production
  end

  test "create production request has no distribution" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    post production_bike_requests_path(productions(:main_production)),
         params: { bike_request: valid_bike_request_params }
    assert_nil BikeRequest.last.distribution
  end

  test "create production request redirects to production tickets" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    post production_bike_requests_path(productions(:main_production)),
         params: { bike_request: valid_bike_request_params }
    assert_redirected_to tickets_production_path(productions(:main_production))
  end

  # --- edit ---

  test "edit requires authentication" do
    get edit_bike_request_path(bike_requests(:requested_bike))
    assert_redirected_to login_path
  end

  test "edit returns 403 for user without distribution access" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    get edit_bike_request_path(bike_requests(:requested_bike))
    assert_response :forbidden
  end

  test "edit renders form for authorized distribution user on requested card" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    get edit_bike_request_path(bike_requests(:requested_bike))
    assert_response :success
  end

  test "edit renders form for authorized distribution user on denied card" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    get edit_bike_request_path(bike_requests(:denied_bike))
    assert_response :success
  end

  # --- update: production approve/deny ---

  test "update approve requires authentication" do
    patch bike_request_path(bike_requests(:requested_bike)), params: { status: "approve" }
    assert_redirected_to login_path
  end

  test "update approve returns 403 for user without production access" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    patch bike_request_path(bike_requests(:requested_bike)), params: { status: "approve" }
    assert_response :forbidden
  end

  test "update approve sets status to pending" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:requested_bike)), params: { status: "approve" }
    assert bike_requests(:requested_bike).reload.pending?
  end

  test "update approve redirects to production pending tab" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:requested_bike)), params: { status: "approve" }
    assert_redirected_to tickets_production_path(productions(:main_production), tab: "pending")
  end

  test "update deny sets status to denied" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:requested_bike)), params: { status: "deny" }
    assert bike_requests(:requested_bike).reload.denied?
  end

  test "update deny redirects to production requested tab" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:requested_bike)), params: { status: "deny" }
    assert_redirected_to tickets_production_path(productions(:main_production), tab: "requested")
  end

  test "update delivered sets status to delivered" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:completed_bike)), params: { status: "delivered" }
    assert bike_requests(:completed_bike).reload.delivered?
  end

  test "update distributed returns 403 for non-requestor production user" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:completed_bike)), params: { status: "distributed" }
    assert_response :forbidden
  end

  test "update distributed allows distribution requestor" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    patch bike_request_path(bike_requests(:completed_bike)), params: { status: "distributed" }
    assert bike_requests(:completed_bike).reload.distributed?
  end

  test "update distributed redirects distribution requestor to distribution distributed tab" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    patch bike_request_path(bike_requests(:completed_bike)), params: { status: "distributed" }
    assert_redirected_to tickets_distribution_path(distributions(:downtown_dist), tab: "distributed")
  end

  test "update distributed allows production user on production-submitted request" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    br = bike_requests(:completed_bike)
    br.update_columns(distribution_id: nil)
    patch bike_request_path(br), params: { status: "distributed" }
    assert br.reload.distributed?
  end

  test "update ready_for_delivery sets status to ready_for_delivery" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:pending_bike)), params: { status: "ready_for_delivery" }
    assert bike_requests(:pending_bike).reload.ready_for_delivery?
  end

  test "update delivered from ready_for_delivery sets status to delivered" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:completed_bike)), params: { status: "delivered" }
    assert bike_requests(:completed_bike).reload.delivered?
  end

  test "update back to ready_for_delivery from delivered" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    br = bike_requests(:completed_bike)
    br.update_columns(status: BikeRequest.statuses[:delivered])
    patch bike_request_path(br), params: { status: "ready_for_delivery" }
    assert br.reload.ready_for_delivery?
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

  # --- archive / unarchive ---

  test "archive requires authentication" do
    patch bike_request_path(bike_requests(:pending_bike)), params: { status: "archive" }
    assert_redirected_to login_path
  end

  test "archive returns 403 for distribution user" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    patch bike_request_path(bike_requests(:pending_bike)), params: { status: "archive" }
    assert_response :forbidden
  end

  test "archive sets status to archived" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:pending_bike)), params: { status: "archive" }
    assert bike_requests(:pending_bike).reload.archived?
  end

  test "archive stores status before archival" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:pending_bike)), params: { status: "archive" }
    assert_equal BikeRequest.statuses[:pending], bike_requests(:pending_bike).reload.status_before_archival
  end

  test "archive redirects to production archived tab" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:pending_bike)), params: { status: "archive" }
    assert_redirected_to tickets_production_path(productions(:main_production), tab: "archived")
  end

  test "unarchive restores previous status" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:archived_bike)), params: { status: "unarchive" }
    assert bike_requests(:archived_bike).reload.pending?
  end

  test "unarchive clears status_before_archival" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:archived_bike)), params: { status: "unarchive" }
    assert_nil bike_requests(:archived_bike).reload.status_before_archival
  end

  test "unarchive redirects to restored status tab" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:archived_bike)), params: { status: "unarchive" }
    assert_redirected_to tickets_production_path(productions(:main_production), tab: "pending")
  end

  # --- complete_all ---

  test "complete_all requires authentication" do
    patch complete_all_bike_request_path(bike_requests(:pending_bike))
    assert_redirected_to login_path
  end

  test "complete_all returns 403 for distribution user" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    patch complete_all_bike_request_path(bike_requests(:pending_bike))
    assert_response :forbidden
  end

  test "complete_all returns 403 for production admin" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch complete_all_bike_request_path(bike_requests(:pending_bike))
    assert_response :forbidden
  end

  test "complete_all sets request status to ready_for_delivery" do
    post login_path, params: { email: users(:master_mechanic_user).email, password: "password" }
    patch complete_all_bike_request_path(bike_requests(:pending_bike))
    assert bike_requests(:pending_bike).reload.ready_for_delivery?
  end

  test "complete_all redirects to production ready_for_delivery tab" do
    post login_path, params: { email: users(:master_mechanic_user).email, password: "password" }
    patch complete_all_bike_request_path(bike_requests(:pending_bike))
    assert_redirected_to tickets_production_path(productions(:main_production), tab: "ready_for_delivery")
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

  test "resubmit sets status to requested" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    patch bike_request_path(bike_requests(:denied_bike)),
          params: { bike_request: resubmit_params }
    assert bike_requests(:denied_bike).reload.requested?
  end

  test "resubmit updates bike request fields" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    patch bike_request_path(bike_requests(:denied_bike)),
          params: { bike_request: resubmit_params }
    assert_equal "Updated Name", bike_requests(:denied_bike).reload.requestor_name
  end

  test "resubmit redirects to distribution requested tab" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    patch bike_request_path(bike_requests(:denied_bike)),
          params: { bike_request: resubmit_params }
    assert_redirected_to tickets_distribution_path(distributions(:downtown_dist), tab: "requested")
  end

  test "resubmit on requested card also sets requested" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    patch bike_request_path(bike_requests(:requested_bike)),
          params: { bike_request: resubmit_params }
    assert bike_requests(:requested_bike).reload.requested?
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
