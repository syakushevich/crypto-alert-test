class NotificationChannel < ApplicationRecord
  # Associations
  has_and_belongs_to_many :alerts

  # Logic
  serialize :config, coder: JSON

  # Validations
  validates :type, presence: true

  # This is an abstract method that all subclasses must implement.
  # It defines the contract for your "Plugin" pattern.
  def notify(alert)
    raise NotImplementedError, "#{self.class.name} has not implemented method 'notify'"
  end
end
