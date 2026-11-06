
# Use the Ruby version supported by Redmine 4.2.11
FROM ruby:2.7.8-bullseye

# Application and Bundler configuration
ENV RAILS_ENV=production \
    BUNDLE_WITHOUT=development:test \
    BUNDLE_PATH=/usr/local/bundle


# Configure Debian Bullseye archived security repository.
# The original security repository contains package URLs returning 404.
RUN sed -i \
    's|^deb http://deb.debian.org/debian-security|deb [check-valid-until=no] https://archive.debian.org/debian-security|' \
    /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        libpq-dev \
        libxml2-dev \
        libxslt1-dev \
        libyaml-dev \
        zlib1g-dev \
        libffi-dev \
        nodejs \
        git \
        imagemagick \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*


# Install a Bundler version compatible with Ruby 2.7
RUN gem install bundler -v 2.4.22 --no-document

# Create a non-root application user
RUN groupadd --system redmine && \
    useradd --system --gid redmine \
    --home-dir /usr/src/redmine redmine

# Set application working directory
WORKDIR /usr/src/redmine

# Copy the existing Redmine source
COPY redmine/ /usr/src/redmine/

COPY deployment/module-1/Gemfile.lock /usr/src/redmine/Gemfile.lock


# Copy deployment-specific configuration
COPY deployment/module-1/database.yml \
     /usr/src/redmine/config/database.yml

COPY deployment/module-1/Gemfile.local \
     /usr/src/redmine/Gemfile.local


# Install Ruby dependencies
RUN bundle _2.4.22_ install --jobs 4 --retry 3

# Generate Redmine's secret token
RUN bundle _2.4.22_ exec rake generate_secret_token

# Prepare required directories and permissions
RUN mkdir -p files log tmp public/plugin_assets && \
    chown -R redmine:redmine /usr/src/redmine /usr/local/bundle


# Run the application without root privileges
USER redmine

EXPOSE 3000

# Start Redmine using Puma
CMD ["bundle", "exec", "puma", "-b", "tcp://0.0.0.0:3000", "-e", "production"]
