FROM ruby:2.3.7-stretch
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
    dcmtk \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
RUN gem install bundler -N -v '< 2'

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

ENTRYPOINT ["lib/support/docker-entrypoint.sh"]

EXPOSE 3000

CMD ["bin/rails", "s", "-b", "0.0.0.0"]
