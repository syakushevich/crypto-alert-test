# app/jobs/alert_checker_job.rb
class AlertCheckerJob < ApplicationJob
  queue_as :default

  def perform
    active_alerts = Alert.where(status: 'active').includes(:notification_channels).group_by(&:symbol)
    return if active_alerts.empty?

    AlertCheckerService.check_all(active_alerts)
  end
end
