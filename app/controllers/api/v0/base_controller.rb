class Api::V0::BaseController < ApplicationController
  include Swagger::Blocks
  include OpenStax::Swagger::Bind

  rescue_from_unless_local StandardError do |exception|
    render json: binding_error(status_code: 500, messages: [exception.message]), status: 500
  end

  rescue_from_unless_local ActionController::ParameterMissing do |exception|
    render json: binding_error(status_code: 422, messages: [exception.message]), status: 422
  end

  protected

  def binding_error(status_code:, messages:)
    Api::V0::Bindings::Error.new(status_code: status_code, messages: messages)
  end
end
