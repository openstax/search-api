#!/bin/bash

# Script to run on the deployed server when the code has been
# updated (or on first deployment)

ruby_version=`cat .ruby-version`
echo Installing Ruby $ruby_version
source /home/ubuntu/rbenv-init && rbenv install -s $ruby_version

echo Installing bundler
# Get specific version of bundler used in the Gemfile.lock
BUNDLER_VERSION=`grep -A 2 "BUNDLED WITH" Gemfile.lock | tail -1`
gem install --conservative bundler -v $BUNDLER_VERSION

echo Installing gems
bundle install --without development test

echo Updating crontab
# Note that this update's the user crontab which lives in /var/spool and isn't
# saved in an AWS AMI.  However, since our AWS launch configurations call this
# script, the crontab will be set up again when the AMI is launched in an instance.
whenever --set "job_template=sudo -H -i -u ubuntu bash -c '. ~/rbenv-init; :job' \
               &cron_log=$PWD/log/whenever.log" \
         --update-crontab

echo Done!
