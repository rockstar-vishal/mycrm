require 'test_helper'

class LeadsControllerTest < ActionController::TestCase
  setup do
    @lead = leads(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:leads)
  end

  test "should create lead" do
    assert_difference('Lead.count') do
      post :create, lead: { address: @lead.address, budget: @lead.budget, call_in_id: @lead.call_in_id, city: @lead.city, comment: @lead.comment, company_id: @lead.company_id, country: @lead.country, date: @lead.date, dead_reason: @lead.dead_reason, email: @lead.email, lead_no: @lead.lead_no, mobile: @lead.mobile, name: @lead.name, ncd: @lead.ncd, other_emails: @lead.other_emails, other_phones: @lead.other_phones, project_id: @lead.project_id, source_id: @lead.source_id, state: @lead.state, status_id: @lead.status_id, user_id: @lead.user_id, visit_comments: @lead.visit_comments, visit_date: @lead.visit_date }
    end

    assert_response 201
  end

  test "should show lead" do
    get :show, id: @lead
    assert_response :success
  end

  test "should update lead" do
    put :update, id: @lead, lead: { address: @lead.address, budget: @lead.budget, call_in_id: @lead.call_in_id, city: @lead.city, comment: @lead.comment, company_id: @lead.company_id, country: @lead.country, date: @lead.date, dead_reason: @lead.dead_reason, email: @lead.email, lead_no: @lead.lead_no, mobile: @lead.mobile, name: @lead.name, ncd: @lead.ncd, other_emails: @lead.other_emails, other_phones: @lead.other_phones, project_id: @lead.project_id, source_id: @lead.source_id, state: @lead.state, status_id: @lead.status_id, user_id: @lead.user_id, visit_comments: @lead.visit_comments, visit_date: @lead.visit_date }
    assert_response 204
  end

  test "should destroy lead" do
    assert_difference('Lead.count', -1) do
      delete :destroy, id: @lead
    end

    assert_response 204
  end
end
