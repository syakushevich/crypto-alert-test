# spec/jobs/price_fetcher_job_spec.rb
require 'rails_helper'

RSpec.describe PriceFetcherJob, type: :job do
  include ActiveJob::TestHelper

  let(:job) { PriceFetcherJob.new }

  it 'queues on the low_priority queue' do
    expect(job.queue_name).to eq('low_priority')
  end

  describe '#perform' do
    before do
      Alert.destroy_all
      allow(PriceFetcherService).to receive(:call)
    end

    context 'when active alerts exist' do
      before do
        create(:alert, from_currency: 'BTC', to_currency: 'USDT', status: 'active')
        create(:alert, from_currency: 'BTC', to_currency: 'USDT', status: 'active')
        create(:alert, from_currency: 'ETH', to_currency: 'USDT', status: 'active')

        # This alert should be ignored by the job
        create(:alert, from_currency: 'BTC', to_currency: 'USDT', status: 'paused')
      end

      it 'fetches unique symbols of active alerts' do
        job.perform
        # The query should result in ['BTCUSDT', 'ETHUSDT']
        # We use `match_array` because the order of symbols is not guaranteed.
        expect(PriceFetcherService).to have_received(:call).with(
          match_array(%w[BTCUSDT ETHUSDT])
        )
      end
    end

    context 'when no active alerts exist' do
      before do
        Alert.destroy_all
      end

      it 'calls the service with an empty array' do
        job.perform
        expect(PriceFetcherService).to have_received(:call).with([])
      end
    end
  end
end