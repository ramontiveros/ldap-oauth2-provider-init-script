# base image
FROM debian:buster
MAINTAINER luke.schleicher@curatess.com

# Update packages
RUN apt-get update

# Install tools
RUN apt-get install -y autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev libsqlite3-dev redis-server cron wget git git-core ruby

# Install Ruby
RUN wget https://cache.ruby-lang.org/pub/ruby/2.5/ruby-2.5.0.tar.gz
RUN tar -zxvf ruby-2.5.0.tar.gz
WORKDIR ruby-2.5.0
RUN autoconf
RUN ./configure
RUN make
RUN make install

# Reset working dir to root
WORKDIR /

# Install gems
RUN gem install bundler -v 2.3.27
RUN gem install foreman

# Prepare SSL Cert Folder
ARG SSLDOMAIN
RUN mkdir -p /etc/letsencrypt/$SSLDOMAIN

# Clone app github repo
WORKDIR /var/www
RUN git clone https://github.com/ramontiveros/ldap-oauth2-provider.git
WORKDIR ldap-oauth2-provider
RUN touch log/sidekiq.log

# Configure Rails
RUN sed -i.bu "s/placeholderdomain/$SSLDOMAIN/g" config/puma.rb
RUN rm -f tmp/pids/server.pid
RUN git pull
#RUN git fetch
#RUN git checkout 1dcb977
RUN bundle install

# Set up cron job
RUN whenever --update-crontab
RUN update-rc.d cron.service enable
