FROM ubuntu:17.10
MAINTAINER aandersen@velalu.qa

# Install distribution dependencies
RUN apt-get update -qq && \
    apt-get install -y \
    make \
    graphviz \
    locales \
    openjdk-8-jre-headless \
    git \
    emacs25

# Set the locale
RUN echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ADD elisp/onbuild.el onbuild.el
RUN emacs -Q --batch --load onbuild.el
RUN rm onbuild.el

VOLUME /workspace
WORKDIR /workspace

CMD find -name \*.org -exec emacs --batch --load elisp/init.el {} -f org-html-export-to-html \; && tar czf htmls.tgz *.html
