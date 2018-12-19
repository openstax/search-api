#!/bin/bash

sha_or_branch=${1:-master}

echo "Checking out $sha_or_branch"
git checkout $sha_or_branch

if [ $? -ne 0 ]; then
  echo "$sha_or_branch is not available, fetching"
  git fetch
  git checkout $sha_or_branch

  if [ $? -ne 0 ]; then
    echo "error: Could not checkout $sha_or_branch"
    exit 1
  fi
fi

ruby_version=`cat .ruby-version`
echo Installing Ruby $ruby_version
source /home/ubuntu/rbenv-init && rbenv install -s $ruby_version

echo Installing bundler
gem install --conservative bundler

echo Installing gems
bundle install

echo Done!
