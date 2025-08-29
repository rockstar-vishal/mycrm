require 'test_helper'

class BrokersControllerTest < ActionController::TestCase
  setup do
    @broker = brokers(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:brokers)
  end

  test "should create broker" do
    assert_difference('Broker.count') do
      post :create, broker: { email: @broker.email, firm_name: @broker.firm_name, locality: @broker.locality, mobile: @broker.mobile, name: @broker.name, rera_number: @broker.rera_number }
    end

    assert_response 201
  end

  test "should show broker" do
    get :show, id: @broker
    assert_response :success
  end

  test "should update broker" do
    put :update, id: @broker, broker: { email: @broker.email, firm_name: @broker.firm_name, locality: @broker.locality, mobile: @broker.mobile, name: @broker.name, rera_number: @broker.rera_number }
    assert_response 204
  end

  test "should destroy broker" do
    assert_difference('Broker.count', -1) do
      delete :destroy, id: @broker
    end

    assert_response 204
  end
end
