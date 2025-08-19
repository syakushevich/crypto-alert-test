# spec/services/price_provider_spec.rb
require 'rails_helper'

RSpec.describe PriceProvider do
  # Define a dummy provider for testing purposes
  class MockProvider; end

  # IMPORTANT: Because the provider is stored in a class variable,
  # its state will persist between tests. We must clean up after each test.
  after(:each) do
    PriceProvider.set_provider(BinanceGateway) # Reset to default
  end

  describe '.current' do
    it 'defaults to BinanceGateway' do
      expect(PriceProvider.current).to eq(BinanceGateway)
    end
  end

  describe '.set_provider' do
    it 'changes the current provider' do
      # Verify the initial state
      expect(PriceProvider.current).to eq(BinanceGateway)

      # Change the provider
      PriceProvider.set_provider(MockProvider)

      # Verify the new state
      expect(PriceProvider.current).to eq(MockProvider)
    end
  end
end