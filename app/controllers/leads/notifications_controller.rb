module Leads
  class NotificationsController < ApplicationController


    before_action :set_lead,:set_templates, only: [:template_detail, :update_template_detail, :send_sms, :send_email, :shoot_email]
    before_action :set_notifications, only: [:shoot_notification, :template_detail]

    def send_sms
      render_modal('send_sms')
    end

    def send_email
      @email = current_user.emails.new
      render_modal('send_email')
    end

    def shoot_email
      @email = current_user.sent_emails.new(email_params)
      @email.receiver = @lead
      if @email.save
        flash[:notice] = 'Email Sent Successfully'
        xhr_redirect_to redirect_to: leads_path
      else
        render_modal('send_email')
        flash[:alert] = 'Notification Sending Failed!!'
      end
    end

    def shoot_notification
      respond_to do |format|
        format.js do
          @notification = @notifications.find_by(id: params[:notification_id])
          if @notification.send_sms current_user.id
            flash[:notice] = 'Notification Sent Successfully'
          else
            flash[:alert] = 'Notification Sending Failed!!'
          end
        end
      end
      xhr_redirect_to redirect_to: leads_path
    end

    def template_detail
      @template = @templates.find_by(id: params[:template_id])
      @notifications.load_methods(@template)
      respond_to do |format|
        format.js do
          @notification = @lead.notifications.new(body: @template.body, notification_template_id: @template.id)
        end
      end
    end

    def update_template_detail
      respond_to do |format|
        format.js do
          @template = @templates.find_by(id: params[:template_id])
          @notification = @lead.notifications.new(notifcation_params)
          @notification.assign_attributes(company_id: @company.id, notification_template_id: @template.id)
          @notification.save
        end
      end
    end

    private

    def set_lead
      @company = current_user.company
      @lead = @company.leads.find(params[:lead_id])
    end

    def set_templates
      @templates = @company.notification_templates
    end

    def notifcation_params
      params.require(:notification).permit!
    end

    def email_params
      params.require(:email).permit(
        :subject,
        :body,
        cc_email: []
      )
    end

    def set_notifications
      @notifications = current_user.company.notifications
    end

  end
end
