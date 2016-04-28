FROM ubuntu:14.04
MAINTAINER aandersen@velalu.qa

# Install distribution dependencies
RUN apt-get update -qq && \
    apt-get install -y \
    graphviz \
    locales \
    openjdk-7-jre-headless \
    git \
    emacs

# Set the locale
RUN echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ADD elisp/onbuild.el onbuild.el
RUN emacs -q --batch --load onbuild.el
RUN rm onbuild.el

VOLUME /workspace
WORKDIR /workspace
