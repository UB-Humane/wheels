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

  test "create notifies production admins/master mechanics" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    assert_enqueued_jobs 1, only: SendPushNotificationJob do
      post distribution_bike_requests_path(distributions(:downtown_dist)),
           params: { bike_request: valid_bike_request_params }
    end
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
           params: { bike_request: { due_date: "" } }
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

  test "create production request sends no notification" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    assert_no_enqueued_jobs only: SendPushNotificationJob do
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

  test "create production request saves owner when owner is a master mechanic" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    post production_bike_requests_path(productions(:main_production)),
         params: { bike_request: valid_bike_request_params.merge(owner_id: users(:master_mechanic_user).id) }
    assert_equal users(:master_mechanic_user), BikeRequest.last.owner
  end

  test "create production request saves owner when owner is an admin" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    post production_bike_requests_path(productions(:main_production)),
         params: { bike_request: valid_bike_request_params.merge(owner_id: users(:prod_admin).id) }
    assert_equal users(:prod_admin), BikeRequest.last.owner
  end

  test "create production request rejects an owner who is a volunteer" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    assert_no_difference "BikeRequest.count" do
      post production_bike_requests_path(productions(:main_production)),
           params: { bike_request: valid_bike_request_params.merge(owner_id: users(:prod_volunteer).id) }
    end
    assert_response :unprocessable_entity
  end

  test "create distribution request ignores owner_id param" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    post distribution_bike_requests_path(distributions(:downtown_dist)),
         params: { bike_request: valid_bike_request_params.merge(owner_id: users(:prod_admin).id) }
    assert_nil BikeRequest.last.owner
  end

  # --- new/create: production request on behalf of a distribution ---

  test "create production request with distribution_id creates a distribution request for an admin" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    assert_difference "BikeRequest.count", 1 do
      post production_bike_requests_path(productions(:main_production)),
           params: { bike_request: valid_bike_request_params.merge(distribution_id: distributions(:downtown_dist).id) }
    end
    br = BikeRequest.last
    assert_equal distributions(:downtown_dist), br.distribution
    assert_equal productions(:main_production), br.production
    assert br.pending?
    assert_nil br.owner
  end

  test "create production request with distribution_id creates a distribution request for a master mechanic" do
    post login_path, params: { email: users(:master_mechanic_user).email, password: "password" }
    post production_bike_requests_path(productions(:main_production)),
         params: { bike_request: valid_bike_request_params.merge(distribution_id: distributions(:downtown_dist).id) }
    assert_equal distributions(:downtown_dist), BikeRequest.last.distribution
  end

  test "create production request assigns submitting user as requestor when on behalf of a distribution" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    post production_bike_requests_path(productions(:main_production)),
         params: { bike_request: valid_bike_request_params.merge(distribution_id: distributions(:downtown_dist).id) }
    assert_equal users(:prod_admin), BikeRequest.last.user
  end

  test "create production request honors owner_id when distribution_id is also present" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    post production_bike_requests_path(productions(:main_production)),
         params: { bike_request: valid_bike_request_params.merge(
           distribution_id: distributions(:downtown_dist).id, owner_id: users(:master_mechanic_user).id
         ) }
    assert_equal users(:master_mechanic_user), BikeRequest.last.owner
  end

  test "create production request ignores distribution_id for a plain volunteer" do
    post login_path, params: { email: users(:prod_volunteer).email, password: "password" }
    post production_bike_requests_path(productions(:main_production)),
         params: { bike_request: valid_bike_request_params.merge(distribution_id: distributions(:downtown_dist).id) }
    br = BikeRequest.last
    assert_nil br.distribution
    assert br.pending?
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

  test "update approve notifies the submitter" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    assert_enqueued_jobs 1, only: SendPushNotificationJob do
      patch bike_request_path(bike_requests(:requested_bike)), params: { status: "approve" }
    end
  end

  test "update approve saves owner when owner is a master mechanic" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:requested_bike)),
          params: { status: "approve", owner_id: users(:master_mechanic_user).id }
    assert_equal users(:master_mechanic_user), bike_requests(:requested_bike).reload.owner
  end

  test "update approve saves owner when owner is an admin" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:requested_bike)),
          params: { status: "approve", owner_id: users(:prod_admin).id }
    assert_equal users(:prod_admin), bike_requests(:requested_bike).reload.owner
  end

  test "update approve rejects an owner who is a volunteer" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:requested_bike)),
          params: { status: "approve", owner_id: users(:prod_volunteer).id }
    br = bike_requests(:requested_bike).reload
    assert br.requested?
    assert_nil br.owner
    assert_redirected_to tickets_production_path(productions(:main_production), tab: "requested")
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

  test "update deny notifies the submitter" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    assert_enqueued_jobs 1, only: SendPushNotificationJob do
      patch bike_request_path(bike_requests(:requested_bike)), params: { status: "deny" }
    end
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

  test "update distributed returns 403 for a plain volunteer who is not the requestor" do
    post login_path, params: { email: users(:prod_volunteer).email, password: "password" }
    patch bike_request_path(bike_requests(:completed_bike)), params: { status: "distributed" }
    assert_response :forbidden
  end

  test "update distributed allows a production admin even on a distribution-submitted request" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:completed_bike)), params: { status: "distributed" }
    assert bike_requests(:completed_bike).reload.distributed?
  end

  test "update distributed redirects a production admin to production tickets, not the distribution's" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:completed_bike)), params: { status: "distributed" }
    assert_redirected_to tickets_production_path(productions(:main_production), tab: "distributed")
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

  test "update delivered from ready_for_delivery sets status to delivered for an admin" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:completed_bike)), params: { status: "delivered" }
    assert bike_requests(:completed_bike).reload.delivered?
  end

  test "update delivered notifies the submitter" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    assert_enqueued_jobs 1, only: SendPushNotificationJob do
      patch bike_request_path(bike_requests(:completed_bike)), params: { status: "delivered" }
    end
  end

  test "update delivered from ready_for_delivery returns 403 for a plain volunteer" do
    post login_path, params: { email: users(:prod_volunteer).email, password: "password" }
    patch bike_request_path(bike_requests(:completed_bike)), params: { status: "delivered" }
    assert_response :forbidden
  end

  test "update back to delivered from distributed allows an admin" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    br = bike_requests(:completed_bike)
    br.update_columns(status: BikeRequest.statuses[:distributed])
    patch bike_request_path(br), params: { status: "delivered" }
    assert br.reload.delivered?
  end

  test "update back to delivered from distributed returns 403 for a plain volunteer" do
    post login_path, params: { email: users(:prod_volunteer).email, password: "password" }
    br = bike_requests(:completed_bike)
    br.update_columns(status: BikeRequest.statuses[:distributed])
    patch bike_request_path(br), params: { status: "delivered" }
    assert_response :forbidden
  end

  test "update redirects to delivery path with tab param" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:completed_bike)), params: { status: "delivered" }
    assert_redirected_to delivery_production_path(productions(:main_production), tab: "delivered")
  end

  test "update taken_up sets status to taken_up" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:completed_bike)), params: { status: "taken_up" }
    assert bike_requests(:completed_bike).reload.taken_up?
  end

  test "update taken_up sends no notification" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    assert_no_enqueued_jobs only: SendPushNotificationJob do
      patch bike_request_path(bike_requests(:completed_bike)), params: { status: "taken_up" }
    end
  end

  test "update taken_up records the taker" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:completed_bike)), params: { status: "taken_up" }
    assert_equal users(:prod_admin), bike_requests(:completed_bike).reload.taker
  end

  test "update taken_up redirects to delivery taken_up tab" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:completed_bike)), params: { status: "taken_up" }
    assert_redirected_to delivery_production_path(productions(:main_production), tab: "taken_up")
  end

  test "update taken_up returns 403 for distribution user" do
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    patch bike_request_path(bike_requests(:completed_bike)), params: { status: "taken_up" }
    assert_response :forbidden
  end

  test "update delivered from taken_up allows the taker" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    br = bike_requests(:taken_up_bike)
    br.update_columns(taker_id: users(:prod_admin).id)
    patch bike_request_path(br), params: { status: "delivered" }
    assert br.reload.delivered?
  end

  test "update delivered from taken_up allows the master mechanic even if not the taker" do
    post login_path, params: { email: users(:master_mechanic_user).email, password: "password" }
    br = bike_requests(:taken_up_bike)
    br.update_columns(taker_id: users(:prod_admin).id)
    patch bike_request_path(br), params: { status: "delivered" }
    assert br.reload.delivered?
  end

  test "update delivered from taken_up allows an admin even if not the taker" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    br = bike_requests(:taken_up_bike)
    br.update_columns(taker_id: users(:master_mechanic_user).id)
    patch bike_request_path(br), params: { status: "delivered" }
    assert br.reload.delivered?
  end

  test "update delivered from taken_up returns 403 for a plain volunteer who is not the taker, owner, or admin/master mechanic" do
    post login_path, params: { email: users(:prod_volunteer).email, password: "password" }
    br = bike_requests(:taken_up_bike)
    br.update_columns(taker_id: users(:master_mechanic_user).id)
    patch bike_request_path(br), params: { status: "delivered" }
    assert_response :forbidden
  end

  test "update back_to_taken_up from delivered does not overwrite the taker" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    br = bike_requests(:completed_bike)
    br.update_columns(status: BikeRequest.statuses[:delivered], taker_id: users(:master_mechanic_user).id)
    patch bike_request_path(br), params: { status: "back_to_taken_up" }
    br.reload
    assert br.taken_up?
    assert_equal users(:master_mechanic_user), br.taker
  end

  test "update back_to_taken_up returns 403 for a plain volunteer" do
    post login_path, params: { email: users(:prod_volunteer).email, password: "password" }
    br = bike_requests(:completed_bike)
    br.update_columns(status: BikeRequest.statuses[:delivered])
    patch bike_request_path(br), params: { status: "back_to_taken_up" }
    assert_response :forbidden
  end

  test "update back_to_taken_up allows master mechanic" do
    post login_path, params: { email: users(:master_mechanic_user).email, password: "password" }
    br = bike_requests(:completed_bike)
    br.update_columns(status: BikeRequest.statuses[:delivered])
    patch bike_request_path(br), params: { status: "back_to_taken_up" }
    assert br.reload.taken_up?
  end

  test "update back_to_requested moves pending back to requested and is admin/master-mechanic only" do
    post login_path, params: { email: users(:prod_volunteer).email, password: "password" }
    patch bike_request_path(bike_requests(:pending_bike)), params: { status: "back_to_requested" }
    assert_response :forbidden

    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:pending_bike)), params: { status: "back_to_requested" }
    assert bike_requests(:pending_bike).reload.requested?
    assert_redirected_to tickets_production_path(productions(:main_production), tab: "requested")
  end

  test "update back_to_requested clears owner and taker" do
    br = bike_requests(:pending_bike)
    br.update_columns(owner_id: users(:master_mechanic_user).id, taker_id: users(:prod_volunteer).id)
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(br), params: { status: "back_to_requested" }
    br.reload
    assert_nil br.owner
    assert_nil br.taker
  end

  test "update back_to_pending moves ready_for_delivery back to pending and is admin/master-mechanic only" do
    post login_path, params: { email: users(:prod_volunteer).email, password: "password" }
    patch bike_request_path(bike_requests(:completed_bike)), params: { status: "back_to_pending" }
    assert_response :forbidden

    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:completed_bike)), params: { status: "back_to_pending" }
    assert bike_requests(:completed_bike).reload.pending?
    assert_redirected_to tickets_production_path(productions(:main_production), tab: "pending")
  end

  test "update back_to_ready_for_delivery moves taken_up back to ready_for_delivery and is admin/master-mechanic only" do
    post login_path, params: { email: users(:prod_volunteer).email, password: "password" }
    patch bike_request_path(bike_requests(:taken_up_bike)), params: { status: "back_to_ready_for_delivery" }
    assert_response :forbidden

    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch bike_request_path(bike_requests(:taken_up_bike)), params: { status: "back_to_ready_for_delivery" }
    assert bike_requests(:taken_up_bike).reload.ready_for_delivery?
    assert_redirected_to delivery_production_path(productions(:main_production), tab: "ready_for_delivery")
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

  test "complete_all returns 403 for a plain volunteer" do
    post login_path, params: { email: users(:prod_volunteer).email, password: "password" }
    patch complete_all_bike_request_path(bike_requests(:pending_bike))
    assert_response :forbidden
  end

  test "complete_all allows a production admin" do
    post login_path, params: { email: users(:prod_admin).email, password: "password" }
    patch complete_all_bike_request_path(bike_requests(:pending_bike))
    assert bike_requests(:pending_bike).reload.ready_for_delivery?
  end

  test "complete_all sets request status to ready_for_delivery" do
    post login_path, params: { email: users(:master_mechanic_user).email, password: "password" }
    patch complete_all_bike_request_path(bike_requests(:pending_bike))
    assert bike_requests(:pending_bike).reload.ready_for_delivery?
  end

  test "complete_all notifies the submitter" do
    post login_path, params: { email: users(:master_mechanic_user).email, password: "password" }
    assert_enqueued_jobs 1, only: SendPushNotificationJob do
      patch complete_all_bike_request_path(bike_requests(:pending_bike))
    end
  end

  test "complete_all also notifies the owner when one is assigned" do
    post login_path, params: { email: users(:master_mechanic_user).email, password: "password" }
    br = bike_requests(:pending_bike)
    br.update_columns(owner_id: users(:prod_admin).id)
    assert_enqueued_jobs 2, only: SendPushNotificationJob do
      patch complete_all_bike_request_path(br)
    end
  end

  test "complete_all redirects to delivery ready_for_delivery tab" do
    post login_path, params: { email: users(:master_mechanic_user).email, password: "password" }
    patch complete_all_bike_request_path(bike_requests(:pending_bike))
    assert_redirected_to delivery_production_path(productions(:main_production), tab: "ready_for_delivery")
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
    assert_equal (Date.today + 14), bike_requests(:denied_bike).reload.due_date
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

  test "resubmit clears owner and taker" do
    br = bike_requests(:denied_bike)
    br.update_columns(owner_id: users(:master_mechanic_user).id, taker_id: users(:prod_volunteer).id)
    post login_path, params: { email: users(:dist_user).email, password: "password" }
    patch bike_request_path(br), params: { bike_request: resubmit_params }
    br.reload
    assert_nil br.owner
    assert_nil br.taker
  end

  private

  def valid_bike_request_params
    {
      due_date: (Date.today + 14).to_s,
      bikes_attributes: { "0" => { bike_type: "male" } }
    }
  end

  def valid_bike_request_params_with_two_bikes
    {
      due_date: (Date.today + 14).to_s,
      bikes_attributes: {
        "0" => { bike_type: "male", name: "Alice" },
        "1" => { bike_type: "female", name: "Bob" }
      }
    }
  end

  def resubmit_params
    {
      due_date: (Date.today + 14).to_s,
      bikes_attributes: {}
    }
  end
end
