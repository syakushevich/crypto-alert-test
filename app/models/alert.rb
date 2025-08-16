class Alert < ApplicationRecord
  has_and_belongs_to_many :notification_channels

  validates :from_currency, presence: true, inclusion: { in: %w[BTC ETH USDT] }
  validates :to_currency, presence: true, inclusion: { in: %w[BTC ETH USDT] }
  validates :threshold_price, presence: true, numericality: { greater_than: 0 }
  validates :direction, presence: true, inclusion: { in: %w[up down] }
  validates :status, presence: true, inclusion: { in: %w[active triggered paused] }

  def symbol
    "#{from_currency}#{to_currency}".upcase
  end

  # Setter for the virtual attribute to parse the input
  def symbol=(value)
    match = value.upcase.match(/^([A-Z0-9]+)(USDT|USDC|BTC|ETH|BNB)$/)
    if match
      self.from_currency = match[1]
      self.to_currency = match[2]
    else
      self.from_currency = nil
      self.to_currency = nil
    end
  end
end