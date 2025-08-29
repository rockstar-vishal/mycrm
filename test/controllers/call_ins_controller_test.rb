require 'test_helper'

class CallInsControllerTest < ActionController::TestCase
  setup do
    @call_in = call_ins(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:call_ins)
  end

  test "should create call_in" do
    assert_difference('CallIn.count') do
      post :create, call_in: { active: @call_in.active, company_id: @call_in.company_id, number: @call_in.number, project_id: @call_in.project_id, source_name: @call_in.source_name, user_id: @call_in.user_id }
    end

    assert_response 201
  end

  test "should show call_in" do
    get :show, id: @call_in
    assert_response :success
  end

  test "should update call_in" do
    put :update, id: @call_in, call_in: { active: @call_in.active, company_id: @call_in.company_id, number: @call_in.number, project_id: @call_in.project_id, source_name: @call_in.source_name, user_id: @call_in.user_id }
    assert_response 204
  end

  test "should destroy call_in" do
    assert_difference('CallIn.count', -1) do
      delete :destroy, id: @call_in
    end

    assert_response 204
  end
end
