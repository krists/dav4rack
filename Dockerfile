FROM ruby:2.6

ENV BUNDLE_JOBS=2 BUNDLE_RETRY=3

RUN mkdir /dav4rack

ARG INSTALL_BUNDLER_VERSION=2.0.2

RUN gem install bundler --version=${INSTALL_BUNDLER_VERSION}

ENV BUNDLER_VERSION=${INSTALL_BUNDLER_VERSION}

WORKDIR /dav4rack