# spec/services/binance_gateway_spec.rb
require 'rails_helper'
require 'net/http'

RSpec.describe BinanceGateway do
  describe '.fetch_price' do
    let(:symbol) { 'BTCUSDT' }
    let(:uri) { URI("#{BinanceGateway::BASE_URL}?symbol=#{symbol}") }

    before do
      allow(Rails.logger).to receive(:error)
    end

    context 'when the API call is successful' do
      it 'returns the price as a BigDecimal' do
        success_response = instance_double(
          Net::HTTPSuccess,
          is_a?: true,
          body: '{"symbol":"BTCUSDT","price":"65123.45"}'
        )
        allow(Net::HTTP).to receive(:get_response).with(uri).and_return(
          success_response
        )
        price = BinanceGateway.fetch_price(symbol)
        expect(price).to be_a(BigDecimal)
        expect(price).to eq(BigDecimal('65123.45'))
      end
    end

    context 'when the API returns a non-success status (e.g., 404)' do
      it 'returns nil' do
        not_found_response = instance_double(Net::HTTPNotFound, is_a?: false)
        allow(Net::HTTP).to receive(:get_response).with(uri).and_return(
          not_found_response
        )
        expect(BinanceGateway.fetch_price(symbol)).to be_nil
      end
    end


    context 'when the API response body is invalid JSON' do
      it 'logs an error and returns nil' do
        bad_json_response = instance_double(
          Net::HTTPSuccess,
          is_a?: true,
          body: 'this is not json'
        )
        allow(Net::HTTP).to receive(:get_response).with(uri).and_return(
          bad_json_response
        )

        expect(BinanceGateway.fetch_price(symbol)).to be_nil

        # This regex checks that the error is logged for the correct symbol.
        expect(Rails.logger).to have_received(:error).with(
          /BinanceGateway Error for #{symbol}:/
        )
      end
    end

    context 'when a network error occurs' do
      it 'logs the error and returns nil' do
        error_message = 'Failed to open TCP connection'
        allow(Net::HTTP).to receive(:get_response).with(uri).and_raise(
          StandardError,
          error_message
        )

        expect(BinanceGateway.fetch_price(symbol)).to be_nil

        expect(Rails.logger).to have_received(:error).with(
          "BinanceGateway Error for #{symbol}: #{error_message}"
        )
      end
    end
  end
end