require 'test_helper'

class RolesControllerTest < ActionController::TestCase
  setup do
    @role = roles(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:roles)
  end

  test "should create role" do
    assert_difference('Role.count') do
      post :create, role: { active: @role.active, name: @role.name }
    end

    assert_response 201
  end

  test "should show role" do
    get :show, id: @role
    assert_response :success
  end

  test "should update role" do
    put :update, id: @role, role: { active: @role.active, name: @role.name }
    assert_response 204
  end

  test "should destroy role" do
    assert_difference('Role.count', -1) do
      delete :destroy, id: @role
    end

    assert_response 204
  end
end
