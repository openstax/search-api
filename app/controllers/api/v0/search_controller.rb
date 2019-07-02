class Api::V0::SearchController < Api::V0::BaseController

  EXCEPTIONS_422 = [
    Books::SearchStrategies::S1::UnknownSearchStrategy,
    Books::SearchStrategies::S1::IncompatibleStrategies
  ].freeze

  EXCEPTIONS_422.each do |exception_class|
    rescue_from_unless_local exception_class do |exception|
      render json: binding_error(status_code: 422, messages: [exception.message]), status: 422
    end
  end

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
        key :name, :books
        key :in, :query
        key :description, 'List of comma-separate UUID@version for the books to search'
        key :required, true
        key :type, :array
        items do
          key :type, :string
        end
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
      extend Api::V0::Swagger::ErrorResponses::UnprocessableEntityError
      extend Api::V0::Swagger::ErrorResponses::ServerError
    end
  end

  def search
    started_at = Time.now

    search_strategy_instance = Books::SearchStrategies::S1::Factory.build(
      book_version_ids: params.require(:books).split(','),
      index_strategy: params.require(:index_strategy),
      search_strategy: params.require(:search_strategy),
      options: params # passthrough for other options the search strategy may need
    )

    raw_results = search_strategy_instance.search(query_string: params[:q])

    response = Api::V0::Bindings::SearchResult.new.build_from_hash(raw_results.with_indifferent_access)

    response.overall_took = ((Time.now - started_at)*1000).round

    render json: response, status: :ok
  end

end
