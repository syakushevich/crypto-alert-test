# spec/services/price_fetcher_service_spec.rb
require 'rails_helper'

RSpec.describe PriceFetcherService, type: :service do
  let(:symbols_to_fetch) { ["ETHUSDT", "BTCUSDT"] }
  let(:eth_price) { 4500.0 }
  let(:btc_price) { 61000.0 }

  # Create a mock object for the PriceProvider
  let(:mock_provider) { double("PriceProvider") }

  before do
    allow(PriceProvider).to receive(:current).and_return(mock_provider)
    allow(Rails.cache).to receive(:write)
    allow(Rails.logger).to receive(:warn)
  end

  it "fetches prices in parallel and writes to cache on success" do
    # Set expectations on the mock provider
    expect(mock_provider).to receive(:fetch_price).with("ETHUSDT").and_return(eth_price)
    expect(mock_provider).to receive(:fetch_price).with("BTCUSDT").and_return(btc_price)

    # Set expectations on Rails.cache
    expect(Rails.cache).to receive(:write).with("price_ETHUSDT", eth_price, expires_in: 30.seconds).once
    expect(Rails.cache).to receive(:write).with("price_BTCUSDT", btc_price, expires_in: 30.seconds).once

    # Call the service
    described_class.call(symbols_to_fetch)
  end

  it "handles API failures gracefully and logs a warning" do
    # Simulate one success and one failure (returns nil)
    expect(mock_provider).to receive(:fetch_price).with("ETHUSDT").and_return(eth_price)
    expect(mock_provider).to receive(:fetch_price).with("FAILCOIN").and_return(nil)

    # Expect cache write for the success, but not for the failure
    expect(Rails.cache).to receive(:write).with("price_ETHUSDT", eth_price, expires_in: 30.seconds).once
    expect(Rails.cache).not_to receive(:write).with("price_FAILCOIN", anything, anything)

    # Expect a warning to be logged for the failure
    expect(Rails.logger).to receive(:warn).with("[PriceFetcherService] Failed to fetch price for FAILCOIN").once

    described_class.call(["ETHUSDT", "FAILCOIN"])
  end
end