# Dockerfile
FROM ruby:3.0.6

ENV RAILS_ENV="development"

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libsqlite3-dev \
    nodejs \
    yarn \
    redis-tools && \
    rm -rf /var/lib/apt/lists/*

# Removed the symlink line: RUN ln -sf /usr/sbin/cron /usr/local/bin/crond

WORKDIR /rails

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

# Entrypoint remains the same for initial setup
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]