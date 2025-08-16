module Api
  module V1
    class AlertsController < ApplicationController
      before_action :set_alert, only: %i[show update destroy]

      def index
        @alerts = Alert.all
        render json: @alerts
      end

      def show
        render json: @alert
      end

      def create
        @alert = Alert.new(alert_params)

        if @alert.save
          render json: @alert, status: :created
        else
          render json: @alert.errors, status: :unprocessable_entity
        end
      end

      def update
        if @alert.update(alert_params)
          render json: @alert
        else
          render json: @alert.errors, status: :unprocessable_entity
        end
      end

      def destroy
        @alert.destroy!
        head :no_content
      end

      private

      def set_alert
        @alert = Alert.find(params[:id])
      end

      def alert_params
        params.require(:alert).permit(
          :from_currency,
          :to_currency,
          :threshold_price,
          :direction,
          :status,
          notification_channel_ids: [] # Allows associating channels by ID
        )
      end
    end
  end
end