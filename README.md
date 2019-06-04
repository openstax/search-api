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

## Swagger, Clients, and Bindings

The Open Search API is documented in the code using Swagger.  Swagger JSON can be accessed at `/api/v0/swagger`.

### Autogenerating bindings

Within the baseline, we use Swagger-generated Ruby code to serve as bindings for request and response data.  Calling
`rake openstax_swagger:generate_model_bindings[X]` will create version X request and response model bindings in `app/bindings/api/vX`.
See the documentation at https://github.com/openstax/swagger-rails for more information.

### Autogenerating clients

A rake script is provided to generate client libraries.  Call
`rake openstax_swagger:generate_client[X,lang]` to generate the major version X client for the given language, e.g.
`rake openstax_swagger:generate_client[0,ruby]` will generate the Ruby client for the latest version 0 API.  This
will generate code in the baseline, so if you don't want it committed move it elsewhere.

### Generating files with the Swagger JSON

Run `rake write_swagger_json` to write Swagger JSON files to `tmp/swagger` for each major API version.

## Tests

Run the tests with `rspec` or `rake`.

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md)

