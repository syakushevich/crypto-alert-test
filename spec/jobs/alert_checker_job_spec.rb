# spec/jobs/alert_checker_job_spec.rb
require 'rails_helper'

RSpec.describe AlertCheckerJob, type: :job do
  include ActiveJob::TestHelper

  let(:job) { AlertCheckerJob.new }

  it 'queues on the default queue' do
    expect(job.queue_name).to eq('default')
  end

  describe '#perform' do
    before do
      Alert.destroy_all
      allow(AlertCheckerService).to receive(:check_all)
    end

    context 'when active alerts exist' do
      let!(:btc_alert) do
        create(:alert, from_currency: 'BTC', to_currency: 'USDT', status: 'active')
      end
      let!(:eth_alert) do
        create(:alert, from_currency: 'ETH', to_currency: 'USDT', status: 'active')
      end
      let!(:paused_alert) do
        create(:alert, from_currency: 'BTC', to_currency: 'USDT', status: 'paused')
      end

      it 'calls the AlertCheckerService with grouped active alerts' do
        expected_data = {
          'BTCUSDT' => [btc_alert],
          'ETHUSDT' => [eth_alert]
        }

        job.perform

        # Verify that the service is called with the correctly structured hash.
        expect(AlertCheckerService).to have_received(:check_all).with(expected_data)
      end
    end

    context 'when no active alerts exist' do
      before do
        Alert.destroy_all
      end

      it 'does not call the AlertCheckerService' do
        create(:alert, status: 'paused')

        job.perform

        # The guard clause `return if active_alerts.empty?` should prevent this call.
        expect(AlertCheckerService).not_to have_received(:check_all)
      end
    end
  end
end