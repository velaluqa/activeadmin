FROM ruby:2.7.7-buster
MAINTAINER aandersen@velalu.qa

ARG RAILS_MASTER_KEY=""
ENV APP_HOME /app

# Install distribution dependencies
RUN  curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
     apt-get update -qq && \
     apt-get install -y \
     build-essential \
     cmake \
     dcmtk \
     libgdcm-tools \
     graphviz \
     imagemagick \
     libmagickwand-dev \
     libpq-dev \
     chromium \
     libatk-bridge2.0-0 gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils wget \
     locales \
     nodejs \
     pandoc \
     argyll \
     ghostscript \
     postgresql-client \
     texlive-base \
     texlive-luatex \
     texlive-fonts-recommended \
     texlive-xetex \
     zlib1g-dev \
     xutils-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && npm install -g yarn
RUN gem install bundler -N -v '< 2'

RUN mkdir -p /dicom3tools_install && \
    cd /dicom3tools_install && \
    wget https://www.dclunie.com/dicom3tools/workinprogress/dicom3tools_1.00.snapshot.20220618093127.tar.bz2 && \
    tar xvjf dicom3tools_1.00.snapshot.20220618093127.tar.bz2 && \
    cd /dicom3tools_install/dicom3tools_1.00.snapshot.20220618093127 && \
    ./Configure && \
    imake -I./config && \
    make World && \
    make install && \
    make clean && \
    cd / && \
    rm -rf /dicom3tools_install

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

# Add the application code.
COPY . /app

RUN pwd
RUN ls -al /app/public

ARG RAILS_ENV
ENV RAILS_ENV $RAILS_ENV

RUN if [ "$RAILS_ENV" != "development" ]; then if [ -z $RAILS_MASTER_KEY ]; then unset RAILS_MASTER_KEY; fi; RAILS_ENV=production bundle exec rails assets:precompile; fi
RUN ls -al /app/public
# RUN ls -al /app/public/packs
# RUN cat /app/public/packs/manifest.json

ENTRYPOINT ["lib/support/docker-entrypoint.sh"]

EXPOSE 3000

# Allow other containers to use the app root (e.g. nginx container).
VOLUME /app

CMD ["bin/rails", "s", "-b", "0.0.0.0"]
