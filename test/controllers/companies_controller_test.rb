require 'test_helper'

class CompaniesControllerTest < ActionController::TestCase
  setup do
    @company = companies(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:companies)
  end

  test "should create company" do
    assert_difference('Company.count') do
      post :create, company: { allowed_fields: @company.allowed_fields, booking_done_id: @company.booking_done_id, dead_status_id: @company.dead_status_id, description: @company.description, domain: @company.domain, expected_site_visit_id: @company.expected_site_visit_id, index_fields: @company.index_fields, name: @company.name, popup_fields: @company.popup_fields, rejection_reasons: @company.rejection_reasons, sms_mask: @company.sms_mask }
    end

    assert_response 201
  end

  test "should show company" do
    get :show, id: @company
    assert_response :success
  end

  test "should update company" do
    put :update, id: @company, company: { allowed_fields: @company.allowed_fields, booking_done_id: @company.booking_done_id, dead_status_id: @company.dead_status_id, description: @company.description, domain: @company.domain, expected_site_visit_id: @company.expected_site_visit_id, index_fields: @company.index_fields, name: @company.name, popup_fields: @company.popup_fields, rejection_reasons: @company.rejection_reasons, sms_mask: @company.sms_mask }
    assert_response 204
  end

  test "should destroy company" do
    assert_difference('Company.count', -1) do
      delete :destroy, id: @company
    end

    assert_response 204
  end
end
