FROM ruby:2.6.5-stretch
MAINTAINER aandersen@velalu.qa

ENV APP_HOME /app

# Install distribution dependencies
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
     apt-get update -qq && \
     apt-get install -y \
     build-essential \
     build-essential \
     cmake \
     dcmtk \
     graphviz \
     imagemagick \
     libmagickwand-dev \
     libpq-dev \
     locales \
     nodejs \
     pandoc \
     postgresql-client \
     texlive-base \
     texlive-fonts-recommended \
     texlive-xetex \
     zlib1g-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && npm install -g yarn
RUN gem install bundler -N -v '< 2'

# Set the locale
RUN echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME

# Install application dependencies. This is done separately to
# leverage the Docker cache when building.
ADD Gemfile Gemfile.lock $APP_HOME/
RUN bundle install --jobs 20 --retry 5

COPY package.json package.json
COPY yarn.lock yarn.lock
COPY .npmrc .npmrc
RUN npm config set registry=https://registry.npmjs.com/
RUN mkdir -p /node_modules && ln -s ../node_modules node_modules
RUN yarn install --frozen-lockfile

# Allow other containers to use the app root (e.g. nginx container).
VOLUME /app

# Add the application code.
COPY . /app

ENTRYPOINT ["lib/support/docker-entrypoint.sh"]

EXPOSE 3000

CMD ["bin/rails", "s", "-b", "0.0.0.0"]
