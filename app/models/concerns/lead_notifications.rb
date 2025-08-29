module LeadNotifications

  extend ActiveSupport::Concern

  included do

    before_validation :set_changes
    after_commit :notify_lead_assign_user

    def notify_lead_assign_user
      if self.company.can_send_lead_assignment_mail && self.company.mailchimp_integration.active? && @changes.present? && @changes["user_id"].present?
        Resque.enqueue(::ProessAssignmentChangeNotification, self.id)
      end
      if self.company.push_notification_setting.present? && self.company.push_notification_setting.is_active? && @changes.present? && @changes["user_id"].present? && self.company.events.include?('lead_assign')
        Resque.enqueue(::ProcessMobilePushNotification, self.id)
        Resque.enqueue(::ProcessWebPushNotification, self.id)
      end
    end


    def set_changes
      @changes = self.changes
    end

  end
end