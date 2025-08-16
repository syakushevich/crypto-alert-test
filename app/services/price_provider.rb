# app/services/price_provider.rb
require_relative 'binance_gateway'

class PriceProvider
  @current_provider = BinanceGateway

  def self.set_provider(provider_class)
    @current_provider = provider_class
  end

  def self.current
    @current_provider
  end
end