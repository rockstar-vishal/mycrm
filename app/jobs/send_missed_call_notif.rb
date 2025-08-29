class SendMissedCallNotif
  require 'uri'
  require 'net/http'
  require 'json'

  @queue = :send_missed_call_notif
  @send_missed_call_notif = Logger.new('log/send_missed_call_notif.log')

  def self.perform
    Company.send_notifications
  end
end
