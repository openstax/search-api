class Api::V0::StatsController < Api::V0::BaseController

  swagger_path '/stats' do
    operation :get do
      key :summary, 'Get stats'
      key :description, 'Get stats'
      key :operationId, 'stats'
      response 200 do
        key :description, 'Success.  Returns the stats.'
        schema do
          key :'$ref', :StatsResult
        end
      end
      extend Api::V0::Swagger::ErrorResponses::UnprocessableEntityError
      extend Api::V0::Swagger::ErrorResponses::ServerError
    end
  end

  def stats
    started_at = Time.now

    stats_results = Stats.new.call

    response = Api::V0::Bindings::StatResults.new.build_from_hash(stats_results.with_indifferent_access)

    response.overall_took_ms = ((Time.now - started_at)*1000).round

    render json: response, status: :ok
  end
end
