# app/services/notification_service.rb
class NotificationService
  def self.dispatch(alert)
    Rails.logger.info "[NotificationService] Dispatching notifications for Alert ID:#{alert.id}"

    alert.notification_channels.where(is_enabled: true).each do |channel|
      begin
        channel.notify(alert)
      rescue StandardError => e
        # Prevent one failing channel from stopping the others
        Rails.logger.error "[NotificationService] Failed to send notification via #{channel.type} for Alert ID:#{alert.id}. Error: #{e.message}"
      end
    end
  end
end