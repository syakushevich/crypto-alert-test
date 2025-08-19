# spec/services/notification_service_spec.rb
require 'rails_helper'

RSpec.describe NotificationService do
  describe '.dispatch' do
    let(:alert) { create(:alert) }

    let(:channel1) { instance_double(LogChannel, type: 'LogChannel') }
    let(:channel2) { instance_double(TelegramChannel, type: 'TelegramChannel') }
    let(:disabled_channel) do
      instance_double(LogChannel, type: 'LogChannel (disabled)')
    end

    before do
      # Stub the logger to check for log messages
      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:error)

      # Associate the channels with the alert
      # We stub the association to return our doubles
      allow(alert).to receive_message_chain(
        :notification_channels,
        :where
      ).with(is_enabled: true).and_return([channel1, channel2])

      # Allow the `notify` method to be called on our doubles
      allow(channel1).to receive(:notify)
      allow(channel2).to receive(:notify)
    end

    it 'logs the dispatch attempt' do
      NotificationService.dispatch(alert)
      expect(Rails.logger).to have_received(:info).with(
        "[NotificationService] Dispatching notifications for Alert ID:#{alert.id}"
      )
    end

    it 'calls #notify on each enabled channel' do
      NotificationService.dispatch(alert)
      expect(channel1).to have_received(:notify).with(alert)
      expect(channel2).to have_received(:notify).with(alert)
    end

    it 'does not call #notify on disabled channels' do
      expect(disabled_channel).not_to receive(:notify)
      NotificationService.dispatch(alert)
    end

    context 'when a channel fails to notify' do
      before do
        allow(channel1).to receive(:notify).and_raise(
          StandardError,
          'Fake channel error'
        )
      end

      it 'logs the error for the failing channel' do
        NotificationService.dispatch(alert)
        expect(Rails.logger).to have_received(:error).with(
          "[NotificationService] Failed to send notification via LogChannel for Alert ID:#{alert.id}. Error: Fake channel error"
        )
      end

      it 'continues to notify the remaining channels' do
        NotificationService.dispatch(alert)
        expect(channel2).to have_received(:notify).with(alert)
      end
    end
  end
end