# app/models/telegram_channel.rb
require 'telegram/bot' # Add this line

class TelegramChannel < NotificationChannel
  validates :config, presence: true
  validate :telegram_config_is_valid

  def notify(alert)
    bot_token = config['bot_token']
    chat_id = config['chat_id']

    unless bot_token.present? && chat_id.present?
      Rails.logger.warn "[Notification] TelegramChannel: Skipping notification for Alert ID:#{alert.id}. Telegram config missing or incomplete: #{config}"
      return
    end

    message = "Crypto Alert: #{alert.symbol} crossed #{alert.threshold_price} #{alert.direction}."
    Rails.logger.info "[Notification] TelegramChannel: Attempting to send '#{message}' to chat_id #{chat_id} (Alert ID:#{alert.id})"

    begin
      Telegram::Bot::Client.run(bot_token) do |bot|
        bot.api.send_message(chat_id: chat_id, text: message)
      end
      Rails.logger.info "[Notification] Telegram message sent for Alert ID:#{alert.id}"
    rescue Telegram::Bot::Forbidden => e
      Rails.logger.warn "[Notification] Telegram notification failed for Alert ID:#{alert.id}: Bot was blocked by the user or chat. Error: #{e.message}"
      # You might want to disable or delete this channel
    rescue StandardError => e
      Rails.logger.error "[Notification] Telegram notification failed for Alert ID:#{alert.id}: #{e.message}"
    end
  end

  private

  def telegram_config_is_valid
    if config.is_a?(Hash)
      errors.add(:config, "bot_token is missing") unless config['bot_token'].present?
      errors.add(:config, "chat_id is missing") unless config['chat_id'].present?
    else
      errors.add(:config, "must be a hash")
    end
  end
end