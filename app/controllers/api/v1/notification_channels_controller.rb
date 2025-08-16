module Api
  module V1
    class NotificationChannelsController < ApplicationController
      before_action :set_channel, only: %i[show update destroy]

      def index
        @channels = NotificationChannel.all
        render json: @channels
      end

      def show
        render json: @channel
      end

      def create
        @channel = channel_params[:type].constantize.new(channel_params)

        if @channel.save
          render json: @channel, status: :created
        else
          render json: @channel.errors, status: :unprocessable_entity
        end
      end

      def update
        if @channel.update(channel_params)
          render json: @channel
        else
          render json: @channel.errors, status: :unprocessable_entity
        end
      end

      def destroy
        @channel.destroy!
        head :no_content
      end

      private

      def set_channel
        @channel = NotificationChannel.find(params[:id])
      end

      def channel_params
        params.require(:notification_channel).permit(
          :type,
          :is_enabled,
          config: {}
        )
      end
    end
  end
end