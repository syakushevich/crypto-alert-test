# spec/services/alert_checker_service_spec.rb
require 'rails_helper'

RSpec.describe AlertCheckerService, type: :service do
  let!(:eth_up_alert) do
    Alert.create!(
      from_currency: 'ETH', to_currency: 'USDT',
      threshold_price: 4500, direction: 'up', status: 'active'
    )
  end
  let!(:btc_down_alert) do
    Alert.create!(
      from_currency: 'BTC', to_currency: 'USDT',
      threshold_price: 60000, direction: 'down', status: 'active'
    )
  end

  # The input hash for the service
  let(:active_alerts) do
    { eth_up_alert.symbol => [eth_up_alert], btc_down_alert.symbol => [btc_down_alert] }
  end

  before do
    allow(Rails.cache).to receive(:read_multi).and_return({})
    allow(Rails.cache).to receive(:write_multi)
    allow(NotificationService).to receive(:dispatch)
  end

  context "when an 'up' alert threshold is crossed" do
    it "triggers a notification and updates the alert status" do
      # 1. Define the cache state for this specific test
      cache_reads = { "price_ETHUSDT" => 4501.0, "previous_price_ETHUSDT" => 4499.0 }
      allow(Rails.cache).to receive(:read_multi).and_return(cache_reads)

      # 2. Set expectations for what should be called
      expect(NotificationService).to receive(:dispatch).with(eth_up_alert).once
      expect(Rails.cache).to receive(:write_multi).once

      # 3. Call the service
      described_class.check_all(active_alerts)

      # 4. Assert the outcome
      expect(eth_up_alert.reload.status).to eq('triggered')
    end
  end

  context "when an 'up' alert threshold is NOT crossed" do
    it "does not trigger a notification" do
      cache_reads = {
        "price_ETHUSDT" => 4400.0,
        "previous_price_ETHUSDT" => 4300.0
      }
      allow(Rails.cache).to receive(:read_multi).and_return(cache_reads)

      # Expect dispatch to NOT be called
      expect(NotificationService).not_to receive(:dispatch)
      expect(Rails.cache).to receive(:write_multi).once # Still updates previous_price

      described_class.check_all(active_alerts)

      expect(eth_up_alert.reload.status).to eq('active')
    end
  end

  context "when a 'down' alert threshold is crossed" do
    it "triggers a notification and updates the alert status" do
      cache_reads = {
        "price_BTCUSDT" => 59999.0,
        "previous_price_BTCUSDT" => 60001.0
      }
      allow(Rails.cache).to receive(:read_multi).and_return(cache_reads)

      expect(NotificationService).to receive(:dispatch).with(btc_down_alert).once
      expect(Rails.cache).to receive(:write_multi).once

      described_class.check_all(active_alerts)

      expect(btc_down_alert.reload.status).to eq('triggered')
    end
  end

  context "when price data is missing from the cache" do
    it "does not trigger a notification" do
      # Simulate only previous_price being present
      cache_reads = { "previous_price_ETHUSDT" => 4499.0 }
      allow(Rails.cache).to receive(:read_multi).and_return(cache_reads)

      expect(NotificationService).not_to receive(:dispatch)
      expect(Rails.cache).to receive(:write_multi).once

      described_class.check_all(active_alerts)

      expect(eth_up_alert.reload.status).to eq('active')
    end
  end
end