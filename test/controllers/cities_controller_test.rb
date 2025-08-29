require 'test_helper'

class CitiesControllerTest < ActionController::TestCase
  setup do
    @city = cities(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:cities)
  end

  test "should create city" do
    assert_difference('City.count') do
      post :create, city: { name: @city.name }
    end

    assert_response 201
  end

  test "should show city" do
    get :show, id: @city
    assert_response :success
  end

  test "should update city" do
    put :update, id: @city, city: { name: @city.name }
    assert_response 204
  end

  test "should destroy city" do
    assert_difference('City.count', -1) do
      delete :destroy, id: @city
    end

    assert_response 204
  end
end
