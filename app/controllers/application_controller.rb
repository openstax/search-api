require 'elasticsearch'

class ApplicationController < ActionController::API

  def es_client
    endpoint = Rails.application.secrets.elasticsearch[:endpoint]
    protocol = endpoint.starts_with?("localhost") ? "http" : "https"

    Thread.current[:es_client] ||= Elasticsearch::Client.new(
      url: "#{protocol}://#{endpoint}",
      log: true
    )
  end

end
