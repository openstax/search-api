class Api::V0::SearchController < Api::V0::BaseController

  swagger_path '/search' do
    operation :get do
      key :summary, 'Run a search query'
      key :description, 'Run a search query'
      key :operationId, 'search'
      parameter do
        key :name, :q
        key :in, :query
        key :description, 'text of the search query'
        key :required, true
        key :type, :string
      end
      parameter do
        key :name, :book
        key :in, :query
        key :description, 'UUID@version of the book to search'
        key :required, true
        key :type, :string
      end
      parameter do
        key :name, :index_strategy
        key :in, :query
        key :description, 'name of the index strategy to use when searching'
        key :required, true
        key :type, :string
      end
      key :tags, [
        'Search'
      ]
      response 200 do
        key :description, 'Success.  Returns the search results.'
        schema do
          key :'$ref', :SearchResult
        end
      end
      extend Api::V0::Swagger::ErrorResponses::ServerError
    end
  end

  def search
    # TODO generalize
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

end
