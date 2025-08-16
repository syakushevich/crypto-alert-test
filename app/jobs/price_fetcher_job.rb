# app/jobs/price_fetcher_job.rb
class PriceFetcherJob < ApplicationJob
  queue_as :low_priority # Fetching can be a lower priority than checking

  def perform
    symbols = Alert.where(status: 'active').group_by(&:symbol).keys
    PriceFetcherService.call(symbols)
  end
end
