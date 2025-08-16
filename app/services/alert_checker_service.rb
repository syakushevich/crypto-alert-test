# app/services/alert_checker_service.rb
class AlertCheckerService
  # Receives all active alerts, grouped by symbol.
  def self.check_all(active_alerts_by_symbol)
    symbols = active_alerts_by_symbol.keys

    # Read the current and previous prices from the cache.
    current_prices = Rails.cache.read_multi(*symbols.map { |s| "price_#{s}" })
    previous_prices = Rails.cache.read_multi(*symbols.map { |s| "previous_price_#{s}" })

    symbols.each do |symbol|
      current_price = current_prices["price_#{symbol}"]
      previous_price = previous_prices["previous_price_#{symbol}"]

      # Skip if we don't have both prices needed to detect a crossing.
      next unless current_price && previous_price

      alerts_for_symbol = active_alerts_by_symbol[symbol]
      alerts_for_symbol.each do |alert|
        if triggered?(alert, previous_price, current_price)
          trigger_alert(alert)
        end
      end
    end

    # After all checks, update the 'previous_price' cache for the next run.
    # The new 'current_price' was already written by the PriceFetcherService.
    prices_to_cache = current_prices.transform_keys { |k| k.sub("price_", "previous_price_") }
    Rails.cache.write_multi(prices_to_cache, expires_in: 1.hour)
  end

  private

  def self.triggered?(alert, previous_price, current_price)
    threshold = alert.threshold_price
    if alert.direction == 'up'
      previous_price <= threshold && current_price > threshold
    elsif alert.direction == 'down'
      previous_price >= threshold && current_price < threshold
    else
      false
    end
  end

  def self.trigger_alert(alert)
    Rails.logger.info "[AlertCheckerService] TRIGGERED: Alert ID:#{alert.id} for #{alert.symbol}."
    NotificationService.dispatch(alert)
    alert.update(status: 'triggered')
  end
end