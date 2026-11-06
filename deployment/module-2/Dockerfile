
FROM ruby:3.4-bookworm

ENV RAILS_ENV=production \
    BUNDLE_WITHOUT=development:test \
    BUNDLE_PATH=/usr/local/bundle \
    RAILS_LOG_TO_STDOUT=1

# Install required system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    libxml2-dev \
    libxslt1-dev \
    libyaml-dev \
    zlib1g-dev \
    libffi-dev \
    git \
    imagemagick \
    ca-certificates \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Create application user
RUN groupadd --system redmine && \
    useradd --system --gid redmine \
    --home-dir /usr/src/redmine redmine

WORKDIR /usr/src/redmine

# Copy Redmine 7.0.3 source
COPY redmine-7.0/ /usr/src/redmine/

# Copy PostgreSQL configuration
COPY deployment/module-2/database.yml \
     /usr/src/redmine/config/database.yml

# Install production application server
COPY deployment/module-2/Gemfile.local \
     /usr/src/redmine/Gemfile.local

COPY deployment/module-2/Gemfile.lock /usr/src/redmine/Gemfile.lock


# Install dependencies
# Do not generate Rails secrets during image build.
RUN bundle install --jobs 4 --retry 3 && \
    mkdir -p files log tmp public/plugin_assets public/assets && \
    chown -R redmine:redmine /usr/src/redmine /usr/local/bundle

USER redmine

EXPOSE 3000

CMD ["bundle", "exec", "puma", "-b", "tcp://0.0.0.0:3000", "-e", "production"]
