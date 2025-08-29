require 'active_support/concern'

module Worker

  extend ActiveSupport::Concern

  included do

    class << self

      def send_notifications
        companies = all.joins(:push_notification_setting).where(push_notification_setting: {is_active: true})
        companies.each do |company|
          users = User.ncd_in_next_fifteen_minutes(company)
          if users.present?
            users.send_browser_push_notifications(company)
          end
        end
      end

      def send_next_call_reminder_notification
        companies = all.where.not(events: nil).where("'ncd_reminder' = ANY (events)")
        companies.each do |company|
          users = User.ncd_in_next_fifteen_minutes(company)
          if users.present?
            users.send_push_notifications(company)
          end
        end
      end

    end

  end

end
