# spec/models/alert_spec.rb
require 'rails_helper'

RSpec.describe Alert, type: :model do
  subject(:alert) { build(:alert) }

  describe 'associations' do
    it { should have_and_belong_to_many(:notification_channels) }
  end

  describe 'validations' do
    it { should validate_presence_of(:from_currency) }
    it { should validate_presence_of(:to_currency) }
    it { should validate_presence_of(:threshold_price) }
    it { should validate_presence_of(:direction) }
    it { should validate_presence_of(:status) }

    it { should validate_inclusion_of(:from_currency).in_array(%w[BTC ETH USDT]) }
    it { should validate_inclusion_of(:to_currency).in_array(%w[BTC ETH USDT]) }

    it { should validate_inclusion_of(:direction).in_array(%w[up down]) }
    it { should validate_inclusion_of(:status).in_array(%w[active triggered paused]) }

    it { should validate_numericality_of(:threshold_price).is_greater_than(0) }
    it { should_not allow_value(0).for(:threshold_price) }
    it { should_not allow_value(-100).for(:threshold_price) }
  end

  describe '#symbol' do
    it 'returns the concatenated and upcased currency pair' do
      alert = build(:alert, from_currency: 'eth', to_currency: 'usdt')
      expect(alert.symbol).to eq('ETHUSDT')
    end
  end

  describe '#symbol=' do
    context 'with a valid symbol' do
      it 'correctly parses and assigns from_currency and to_currency' do
        alert.symbol = 'BTCUSDT'
        expect(alert.from_currency).to eq('BTC')
        expect(alert.to_currency).to eq('USDT')
      end

      it 'handles lowercase symbols' do
        alert.symbol = 'ethbtc'
        expect(alert.from_currency).to eq('ETH')
        expect(alert.to_currency).to eq('BTC')
      end

      it 'handles different valid to_currencies' do
        alert.symbol = 'LINKETH'
        expect(alert.from_currency).to eq('LINK')
        expect(alert.to_currency).to eq('ETH')
      end
    end

    context 'with an invalid symbol' do
      it 'sets from_currency and to_currency to nil' do
        alert.symbol = 'INVALIDPAIR'
        expect(alert.from_currency).to be_nil
        expect(alert.to_currency).to be_nil
      end

      it 'handles symbols with numbers at the end that are not currencies' do
        alert.symbol = 'BTC123'
        expect(alert.from_currency).to be_nil
        expect(alert.to_currency).to be_nil
      end
    end
  end
end