# db/seeds.rb

puts "Destroying existing Alerts and NotificationChannels..."
Alert.destroy_all
NotificationChannel.destroy_all
puts "Existing data destroyed."

# --- 1. Create Notification Channels ---
log_channel = NotificationChannel.find_or_create_by!(type: 'LogChannel') do |channel|
  channel.is_enabled = true
  channel.config = {
  }
end
puts "Created/found LogChannel (ID: #{log_channel.id})"

telegram_channel = NotificationChannel.find_or_create_by!(type: 'TelegramChannel') do |channel|
  channel.is_enabled = true
  channel.config = {
    bot_token: ENV.fetch('TELEGRAM_BOT_TOKEN'),
    chat_id: ENV.fetch('TELEGRAM_CHAT_ID')
  }
end
puts "Created/found TelegramChannel (ID: #{telegram_channel.id})"

# --- 2. Create an Alert and associate it with channels ---
eth_usdt_alert = Alert.find_or_create_by!(
  from_currency: 'ETH',
  to_currency: 'USDT',
  direction: 'up'
) do |alert|
  alert.threshold_price = 4650 # Example threshold
  alert.status = 'active'
end

# Associate the alert with the created notification channels
eth_usdt_alert.notification_channels = [log_channel, telegram_channel].uniq
eth_usdt_alert.save!

puts "Created/found Alert for #{eth_usdt_alert.symbol} (ID: #{eth_usdt_alert.id})"
puts "  Associated with channels: #{eth_usdt_alert.notification_channels.map(&:type).join(', ')}"