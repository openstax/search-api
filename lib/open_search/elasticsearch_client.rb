require 'elasticsearch'

class OpenSearch::ElasticsearchClient

  delegate_missing_to :@internal_client

  def self.instance
    Thread.current[:es_client] ||= begin
      secrets = Rails.application.secrets.elasticsearch

      new(
        url: "#{secrets[:protocol]}://#{secrets[:endpoint]}",
        sign_aws_requests: Rails.env.production?
      )
    end
  end

  def initialize(url:, sign_aws_requests: false)
    @internal_client = Elasticsearch::Client.new(elasticsearch_client_options(url)) do |f|
      if sign_aws_requests
        # Borrowed from https://github.com/elastic/elasticsearch-ruby/issues/232#issuecomment-168479765
        # and modified for the new version of the middleware

        require 'typhoeus'
        require 'typhoeus/adapters/faraday'
        require 'faraday_middleware'
        require 'faraday_middleware/aws_sigv4'

        f.request :aws_sigv4,
                  credentials: aws_credentials,
                  service: 'es',
                  region: aws_elasticsearch_region(url)
        f.adapter :typhoeus
      else
        require 'typhoeus'
        require 'typhoeus/adapters/faraday'

        f.adapter :typhoeus
      end
    end
  end

  protected

  # setting the faraday timeout to 15 seconds here.  it times out very often
  # if using the default of 1.5 seconds.
  def elasticsearch_client_options(url)
    {
      url: url,
      log: false,
      transport_options: {
        request: { timeout: 15 }
      }
    }
  end

  def aws_credentials
    # Use credentials from the environment first; if those aren't present, fallback
    # to instance credentials

    if ENV['AWS_ACCESS_KEY_ID'] && ENV['AWS_SECRET_ACCESS_KEY']
      Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'], ENV['AWS_SESSION_TOKEN'])
    else
      Aws::InstanceProfileCredentials.new.credentials
    end
  end

  def aws_elasticsearch_region(endpoint_url)
    # AWS ES endpoint URLs are of the form blah.region.es.amazonaws.com
    # so just extract the region using a regex
    endpoint_url.match(/\.([^\.]*)\.es\.amazonaws\.com$/)[1]
  end
end
