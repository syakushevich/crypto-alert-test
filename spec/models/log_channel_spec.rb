# spec/models/log_channel_spec.rb
require 'rails_helper'

RSpec.describe LogChannel, type: :model do
  let(:alert) do
    create(
      :alert,
      from_currency: 'ETH',
      to_currency: 'USDT',
      threshold_price: 4000,
      direction: 'down'
    )
  end
  let(:channel) { LogChannel.new }

  describe '#notify' do
    before do
      # Freeze time to a specific point for the test
      travel_to Time.zone.local(2025, 8, 19, 12, 0, 0)

      allow(Rails.logger).to receive(:warn)
    end

    # Unfreeze time after the test
    after do
      travel_back
    end

    it 'logs a correctly formatted warning message' do
      expected_log_message = "[Notification] LogChannel: Alert ID:#{alert.id} - ETHUSDT crossed 4000.0 down. Logged at 2025-08-19 12:00:00 UTC"

      expect(Rails.logger).to receive(:warn).with(expected_log_message)

      channel.notify(alert)
    end
  end
end