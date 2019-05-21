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
      parameter do
        key :name, :search_strategy
        key :in, :query
        key :description, 'name of the search strategy to use when searching'
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
    search_strategy_instance = Search::BookVersions::SearchStrategies::Factory.build(
      book_version_id: params[:book],
      index_strategy: params[:index_strategy],
      search_strategy: params[:search_strategy],
      options: params # passthrough for other options the search strategy may need
    )

    raw_results = search_strategy_instance.search(params[:q])

    response = Api::V0::Bindings::SearchResult.new(raw_results: raw_results)

    render json: response, status: :ok
  end

end
