I chose to do polling, every 10 seconds. I assume that we don't need to increase complexity and maintenance for around a 10-second quicker alert; if that were not the case, I would choose WebSockets.

For the app itself, it consists of two cron jobs, both accessing Redis storage. I chose Sidekiq because it's well-supported and will probably be around as long as Rails itself. SQLite3 was chosen for the same reasons; a simple database is sufficient for such a task.

As far as domain logic, `PriceFetcherJob` fetches currency rates in parallel, so all requests won't wait for one long request. We also use `PriceProvider`, which is basically responsible for from which API we get rates. If we want to change our provider, we can just call `PriceProvider.set_provider` and change it without an app restart.

`AlertCheckerJob` checks for a crossing threshold. We load all the alerts and notification channels in one request to avoid N+1 queries. We calculate if the threshold was crossed sequentially, since it's all in memory, and parallel execution would be overkill.

For managing notification channels, we can add a new STI model, with the interface defined in `NotificationChannel`. If the interface already exists, we can just create a join instance between alerts and the notification channel, and the channel is active.

For the tests, I wrote RSpec tests for `AlertCheckerService` and `PriceFetcherService`, as that's where most of the business logic is stored.