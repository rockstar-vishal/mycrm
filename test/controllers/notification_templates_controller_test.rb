require 'test_helper'

class NotificationTemplatesControllerTest < ActionController::TestCase
  setup do
    @notification_template = notification_templates(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:notification_templates)
  end

  test "should create notification_template" do
    assert_difference('NotificationTemplate.count') do
      post :create, notification_template: { body: @notification_template.body, company_id: @notification_template.company_id, fields: @notification_template.fields, name: @notification_template.name }
    end

    assert_response 201
  end

  test "should show notification_template" do
    get :show, id: @notification_template
    assert_response :success
  end

  test "should update notification_template" do
    put :update, id: @notification_template, notification_template: { body: @notification_template.body, company_id: @notification_template.company_id, fields: @notification_template.fields, name: @notification_template.name }
    assert_response 204
  end

  test "should destroy notification_template" do
    assert_difference('NotificationTemplate.count', -1) do
      delete :destroy, id: @notification_template
    end

    assert_response 204
  end
end
