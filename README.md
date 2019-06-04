# OpenStax Open Search

[![Build Status](https://travis-ci.com/openstax/open-search.svg?branch=master)](https://travis-ci.com/openstax/open-search)

A search app supporting OpenStax's unified reading experience.

## Dependencies

This app proxies Elasticsearch and is intended to be deployed to AWS, where it uses DynamoDB and SQS.  It indexes OpenStax book and exercise content.


## Configuration

Settable ENV vars:
* FORCE_ENABLE_SENTRY if you want to allow messages to be sent to Sentry. 
Automatically set to on for production. 
* INDEXING_HTTP_LOGGING if you want to see logging for http calls (defaults to off)
* VCR_OPTS_RECORD set to all for record every time, once, or none. 


## Setup

```
$> bundle install
```

TBD instructions for installing and configuring Elasticsearch.

## Tests

Run the tests with `rspec` or `rake`.

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md)

