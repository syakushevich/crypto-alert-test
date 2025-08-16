# app/services/price_fetcher_service.rb
class PriceFetcherService
  def self.call(symbols)
    threads = []
    fetched_prices = Concurrent::Hash.new

    symbols.each do |symbol|
      threads << Thread.new do
        price = PriceProvider.current.fetch_price(symbol)
        if price
          # Cache the current price for the AlertCheckerJob to use on its *next* run
          Rails.cache.write("price_#{symbol}", price, expires_in: 30.seconds)
          fetched_prices[symbol] = price
        else
          Rails.logger.warn "[PriceFetcherService] Failed to fetch price for #{symbol}"
        end
      end
    end

    threads.each(&:join)
    log_prices(fetched_prices.to_h)
  end

  private

  def self.log_prices(prices)
    if prices.any?
      log_str = prices.map { |symbol, price| "#{symbol}: #{price}" }.join(', ')
      Rails.logger.warn "[PriceFetcherService] Fetched & cached: #{log_str}"
    end
  end
end