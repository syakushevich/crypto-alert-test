# spec/models/notification_channel_spec.rb
require 'rails_helper'

RSpec.describe NotificationChannel, type: :model do
  describe 'validations' do
    it 'is invalid without a type' do
      # We have to manually set the type to nil because Rails sets it automatically
      # for STI (Single Table Inheritance)
      channel = NotificationChannel.new
      channel.type = nil
      expect(channel).not_to be_valid
      expect(channel.errors[:type]).to include("can't be blank")
    end
  end

  describe 'associations' do
    it { should have_and_belong_to_many(:alerts) }
  end

  describe '#notify' do
    it 'raises a NotImplementedError' do
      # Create an instance of the base class to test the abstract method
      channel = NotificationChannel.new
      alert = build_stubbed(:alert)

      expect { channel.notify(alert) }.to raise_error(
        NotImplementedError,
        "NotificationChannel has not implemented method 'notify'"
      )
    end
  end

  describe 'serialization' do
    it 'serializes the config attribute as JSON' do
      config_hash = { 'key' => 'value', 'number' => 123 }
      channel = LogChannel.create!(config: config_hash)
      channel.reload

      # The config should be returned as a hash, not a string
      expect(channel.config).to eq(config_hash)
    end
  end
end