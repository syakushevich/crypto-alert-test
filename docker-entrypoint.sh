#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /rails/tmp/pids/server.pid

# Check if we should run migrations and seeds
if [ "$RUN_MIGRATIONS" = "true" ]; then
  echo "Running database migrations..."
  bundle exec rails db:migrate
  echo "Database migrations complete."

  # --- Add this section to run seeds ---
  echo "Running database seeds..."
  bundle exec rails db:seed
  echo "Database seeds complete."
  # --- End added section ---
fi

# Execute the main command passed to the container
exec "$@"