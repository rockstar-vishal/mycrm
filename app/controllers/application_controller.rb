class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :authenticate_user!
  before_action :check_authorization, :set_push_notification_attr, :set_pusher_attributes, if: :user_signed_in?

  def render_modal(partial, options = {backdrop: true, keyboard: true})
    respond_to do |format|
      format.js{ render partial: 'shared/modal', locals: { partial: partial, options: options} }
      format.html { render(:text => "Invalid request")}
    end
  end

  def xhr_redirect_to(args)
    @args = args
    flash.keep
    render 'shared/xhr_redirect_to'
  end

  def set_push_notification_attr
    if current_user.company.present? && current_user.company.can_send_push_notification?
      Pushpad.auth_token = current_user.company.push_notification_setting.token
      Pushpad.project_id = current_user.company.push_notification_setting.project_key
      gon.can_subscribe = true
      gon.user_uuid = current_user.uuid
      gon.project_id = Pushpad.project_id
      gon.hmac_signature = Pushpad.signature_for current_user.uuid
    end
  end


  def set_pusher_attributes
    if current_user.company.present? && current_user.company.is_pusher_active?
      gon.channel = current_user.company.uuid
      gon.pusher_active = true
      gon.current_user_uuid = current_user.uuid
      gon.events = current_user.company.events
    end
  end

  def check_authorization
    if current_user.is_sysad?
      redirect_to companies_path unless AccessControl.route_is_accessible_sysad({controller: params[:controller], :action=>params[:action], user: current_user})
    elsif current_user.is_super?
      redirect_to leads_path unless AccessControl.route_is_accessible_superadmin({controller: params[:controller], :action=>params[:action], user: current_user})
    elsif current_user.is_manager?
      redirect_to leads_path unless AccessControl.route_is_accessible_manager({controller: params[:controller], :action=>params[:action], user: current_user})
    elsif current_user.is_supervisor?
      redirect_to onsite_leads_path unless AccessControl.route_is_accessible_supervisor({controller: params[:controller], :action=>params[:action]})
    else
      redirect_to leads_path unless AccessControl.route_is_accessible_executive({controller: params[:controller], :action=>params[:action], user: current_user})
    end
  end

end
