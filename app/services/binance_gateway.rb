# app/services/binance_gateway.rb
require "net/http"
require "json"

class BinanceGateway
  BASE_URL = "https://api.binance.com/api/v3/ticker/price"

  def self.fetch_price(symbol)
    uri = URI("#{BASE_URL}?symbol=#{symbol.upcase}")
    response = Net::HTTP.get_response(uri)

    return nil unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    BigDecimal(data["price"])
  rescue JSON::ParserError, Net::HTTPError, StandardError => e
    Rails.logger.error "BinanceGateway Error for #{symbol}: #{e.message}"
    nil
  end
end