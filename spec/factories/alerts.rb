# spec/factories/alerts.rb
FactoryBot.define do
  factory :alert do
    from_currency { 'BTC' }
    to_currency { 'USDT' }
    threshold_price { 50000.0 }
    direction { 'up' }
    status { 'active' }
  end
end