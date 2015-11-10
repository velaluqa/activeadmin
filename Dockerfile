FROM ruby:2.0
MAINTAINER aandersen@velalu.qa

ENV APP_HOME /app

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs

# Install RMagick
# RUN apt-get install -y libmagickwand-dev imagemagick

# Install Nokogiri
# RUN apt-get install -y zlib1g-dev

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
ADD . /app

ENTRYPOINT ['bundle', 'exec']
