class CreateNotificationChannels < ActiveRecord::Migration[7.1]
  def change
    create_table :notification_channels do |t|
      t.string :type, null: false
      t.text :config
      t.boolean :is_enabled, null: false, default: true

      t.timestamps
    end
  end
end
