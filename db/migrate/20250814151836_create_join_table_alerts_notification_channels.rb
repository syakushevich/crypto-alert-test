class CreateJoinTableAlertsNotificationChannels < ActiveRecord::Migration[7.1]
  def change
    create_join_table :alerts, :notification_channels do |t|
      t.index [:alert_id, :notification_channel_id], name: "idx_on_alert_id_and_notification_channel_id"
    end
  end
end
