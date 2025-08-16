class CreateAlerts < ActiveRecord::Migration[7.1]
  def change
    create_table :alerts do |t|
      t.string :from_currency, null: false
      t.string :to_currency, null: false
      t.decimal :threshold_price, precision: 16, scale: 8, null: false
      t.string :direction, null: false
      t.string :status, null: false, default: "active"

      t.timestamps
    end
  end
end
