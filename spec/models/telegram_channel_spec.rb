# spec/models/telegram_channel_spec.rb
require 'rails_helper'
require 'telegram/bot'

RSpec.describe TelegramChannel, type: :model do
  let(:alert) do
    create(
      :alert,
      from_currency: 'BTC',
      to_currency: 'USDT',
      threshold_price: 65000,
      direction: 'up'
    )
  end

  describe 'validations' do
    context 'with valid configuration' do
      it 'is valid' do
        channel =
          TelegramChannel.new(
            config: { 'bot_token' => 'fake_token', 'chat_id' => '12345' }
          )
        expect(channel).to be_valid
      end
    end

    context 'with invalid configuration' do
      it 'is invalid if config is not a hash' do
        channel = TelegramChannel.new(config: 'not a hash')
        expect(channel).not_to be_valid
        expect(channel.errors[:config]).to include('must be a hash')
      end

      it 'is invalid if config is missing' do
        channel = TelegramChannel.new(config: nil)
        expect(channel).not_to be_valid
        expect(channel.errors[:config]).to include("can't be blank")
      end

      it 'is invalid without a bot_token' do
        channel = TelegramChannel.new(config: { 'chat_id' => '12345' })
        expect(channel).not_to be_valid
        expect(channel.errors[:config]).to include('bot_token is missing')
      end

      it 'is invalid without a chat_id' do
        channel = TelegramChannel.new(config: { 'bot_token' => 'fake_token' })
        expect(channel).not_to be_valid
        expect(channel.errors[:config]).to include('chat_id is missing')
      end
    end
  end

  describe '#notify' do
    let(:valid_config) do
      { 'bot_token' => 'test_token_123', 'chat_id' => 'test_chat_456' }
    end
    let(:channel) { TelegramChannel.new(config: valid_config) }

    let(:bot_api) { double("Telegram::Bot::Api") }
    let(:bot) { instance_double(Telegram::Bot::Client, api: bot_api) }

    before do
      # Stub the main entry point for the Telegram client.
      allow(Telegram::Bot::Client).to receive(:run).and_yield(bot)

      allow(bot_api).to receive(:send_message)

      # Stub Rails.logger to prevent log noise and to allow us to expect calls.
      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:warn)
      allow(Rails.logger).to receive(:error)
    end

    context 'when configuration is valid and API call succeeds' do
      it 'sends a correctly formatted message to the Telegram API' do
        expected_message = 'Crypto Alert: BTCUSDT crossed 65000.0 up.'

        # We expect the `send_message` method to be called with specific arguments.
        expect(bot_api).to receive(:send_message).with(
          chat_id: valid_config['chat_id'],
          text: expected_message
        )

        channel.notify(alert)
      end

      it 'logs the attempt and success messages' do
        # Use `.ordered` to ensure logs appear in the correct sequence.
        expect(Rails.logger).to receive(:info).with(/Attempting to send/).ordered
        expect(Rails.logger).to receive(:info).with(/Telegram message sent/).ordered

        channel.notify(alert)
      end
    end

    context 'when configuration is incomplete' do
      let(:incomplete_config) do
        { 'bot_token' => 'test_token_123', 'chat_id' => '' }
      end
      let(:channel_with_incomplete_config) do
        TelegramChannel.new(config: incomplete_config)
      end

      it 'does not attempt to send a message' do
        # The core client method should not even be called.
        expect(Telegram::Bot::Client).not_to receive(:run)
        channel_with_incomplete_config.notify(alert)
      end

      it 'logs a warning about the incomplete configuration' do
        expect(Rails.logger).to receive(:warn).with(
          /Skipping notification.*config missing or incomplete/
        )
        channel_with_incomplete_config.notify(alert)
      end
    end

    context 'when the Telegram API raises an error' do
      before do
        # The telegram-bot gem autoloads its error classes. Since we are stubbing
        # the client, the file defining this error is never loaded.
        # We define it here for the purpose of our test.
        module Telegram
          module Bot
            class Forbidden < StandardError; end
          end
        end
      end

      it 'logs a warning when a Forbidden error is raised' do
        # Simulate the API raising a specific "Forbidden" error.
        error_message = 'bot was blocked by the user'
        allow(bot_api).to receive(:send_message).and_raise(
          Telegram::Bot::Forbidden,
          error_message
        )

        expect(Rails.logger).to receive(:warn).with(/Bot was blocked by the user or chat.*#{error_message}/)
        expect(Rails.logger).not_to receive(:error)

        channel.notify(alert)
      end

      it 'logs an error for other standard errors (e.g., network issues)' do
        # Simulate the API raising a generic StandardError.
        error_message = 'network timeout'
        allow(bot_api).to receive(:send_message).and_raise(
          StandardError,
          error_message
        )

        expect(Rails.logger).to receive(:error).with(/Telegram notification failed.*#{error_message}/)
        expect(Rails.logger).not_to receive(:warn).with(/Bot was blocked/)

        channel.notify(alert)
      end
    end
  end
end