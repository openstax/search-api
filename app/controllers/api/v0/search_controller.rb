class Api::V0::SearchController < ApplicationController

  def search
    query = {
      "size": 25,
      "query": {
        "multi_match": {
          "query": params['q']
          # "fields": ["fields.title^4", "fields.plot^2", "fields.actors", "fields.directors"]
        }
      },
      "_source": ["id"],
       "highlight": {
          "fields": {
            "content": {}
          }
        }
    }

    response = OpenSearch::ElasticsearchClient.instance.search body: query.to_json
    render json: response
  end

  def temp_build_index
    physics_json_url = "https://archive.cnx.org/contents/405335a3-7cff-4df2-a9ad-29062a4af261@7.1.json"


    uri = URI(physics_json_url)
    response = Net::HTTP.get(uri)
    physics_json = JSON.parse(response)

    page_ids = physics_json['tree']['contents'].flat_map{|chapter| chapter['contents'].present? ? chapter['contents'].flat_map{|page| page['id']} : nil}.compact

    page_ids.each do |page_id|
      page_uri = URI("https://archive.cnx.org/contents/#{page_id}.json")
      page_response = Net::HTTP.get(page_uri)
      begin
        page_hash = JSON.parse(page_response)
      rescue JSON::ParserError
        next
      end
      OpenSearch::ElasticsearchClient.instance.index  index: 'pages', type: 'page', id: page_id, body: page_hash
    end

  end

end
