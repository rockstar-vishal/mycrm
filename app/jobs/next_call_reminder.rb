class NextCallReminder
  require 'uri'
  require 'net/http'
  require 'json'

  @queue = :next_call_reminder
  @send_missed_call_notif = Logger.new('log/next_call_reminder.log')

  def self.perform
    Company.send_next_call_reminder_notification
    Company.send_notifications
  end
end
