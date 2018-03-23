FROM ruby:2.3.4
MAINTAINER aandersen@velalu.qa

ENV APP_HOME /app

# Install distribution dependencies
RUN apt-get update -qq && \
    apt-get install -y \
    build-essential \
    libpq-dev \
    nodejs \
    libmagickwand-dev \
    imagemagick \
    zlib1g-dev \
    locales \
    cmake \
    postgresql-client \
    graphviz \
    dcmtk
RUN gem install bundler

RUN mkdir -p /tmp/phantomjs && \
    curl -L https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2 | tar -xj --strip-components=1 -C /tmp/phantomjs && \
    mv /tmp/phantomjs/bin/phantomjs /usr/local/bin && \
    chmod +x /usr/local/bin/phantomjs && \
    rm -rf /tmp/phantomjs

# Set the locale
RUN echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Install application dependencies. This is done separately to
# leverage the Docker cache when building.
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME
ADD Gemfile Gemfile.lock $APP_HOME/
RUN bundle install --jobs 20 --retry 5

# Allow other containers to use the app root (e.g. nginx container).
VOLUME /app

# Add the application code.
COPY . /app
