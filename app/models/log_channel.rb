# app/models/log_channel.rb
class LogChannel < NotificationChannel
  def notify(alert)
    log_message = "[Notification] LogChannel: Alert ID:#{alert.id} - #{alert.symbol} crossed #{alert.threshold_price} #{alert.direction}. Logged at #{Time.current}"
    Rails.logger.warn log_message
  end
end