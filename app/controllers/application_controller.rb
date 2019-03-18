require 'elasticsearch'

class ApplicationController < ActionController::API

  def es_client
    ElasticsearchClient.instance
  end

end
