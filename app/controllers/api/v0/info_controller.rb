class Api::V0::InfoController < Api::V0::BaseController

  swagger_path '/info' do
    operation :get do
      key :summary, 'Get info on indexes'
      key :description, 'Get info on indexes'
      key :operationId, 'info'
      response 200 do
        key :description, 'Success.  Returns the index info.'
        schema do
          key :'$ref', :InfoResults
        end
      end
      extend Api::V0::Swagger::ErrorResponses::UnprocessableEntityError
      extend Api::V0::Swagger::ErrorResponses::ServerError
    end
  end

  def info
    started_at = Time.now

    info_results = IndexInfo.new.call

    response = Api::V0::Bindings::InfoResults.new.build_from_hash(info_results.with_indifferent_access)

    response.overall_took_ms = ((Time.now - started_at)*1000).round

    render json: response, status: :ok
  end
end
