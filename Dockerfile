FROM ruby:2.2
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
    dcmtk

# Set the locale
RUN echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Configure the velaluqa repository keys to allow the use of private
# repositories for the application dependencies.
RUN mkdir /root/.ssh
ADD ./vendor/docker/id_rsa.deployment /root/.ssh/id_rsa
ADD ./vendor/docker/id_rsa.deployment.pub /root/.ssh/id_rsa.pub
RUN ssh-keyscan -p 53639 git.velalu.qa > /root/.ssh/known_hosts
RUN chown -R root:root /root/.ssh
RUN chmod -R 600 /root/.ssh

# Install application dependencies. This is done separately to
# leverage the Docker cache when building.
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME
ADD Gemfile Gemfile.lock $APP_HOME/
RUN gem install bundler && \
    bundle install --jobs 20 --retry 5

# Add the application code.
COPY . /app
