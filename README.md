# OpenStax Open Search

[![Build Status](https://travis-ci.com/openstax/open-search.svg?branch=master)](https://travis-ci.com/openstax/open-search)

A search app supporting OpenStax's unified reading experience.

## Dependencies

This app proxies Elasticsearch and is intended to be deployed to AWS, where it uses DynamoDB and SQS.  It indexes OpenStax book and exercise content.

## Setup

```
$> bundle install
```

TBD instructions for installing and configuring Elasticsearch.

## Tests

Run the tests with `rspec` or `rake`.

## Contributing

See [CONTRIBUTING.md](https://github.com/openstax/open-search/CONTRIBUTING.md)

