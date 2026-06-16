module ErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError, with: :render_internal_error
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActionController::ParameterMissing, with: :render_parameter_missing
    rescue_from ApiError::Unauthorized, with: :render_unauthorized
    rescue_from ApiError::Validation, with: :render_validation
  end

  private

  def render_error(status:, code:, message:, details: nil)
    error = { code: code, message: message }
    error[:details] = details if details
    render json: { error: error }, status: status
  end

  def render_internal_error(exception)
    Rails.logger.error("#{exception.class}: #{exception.message}")
    Rails.logger.error(exception.backtrace.join("\n")) if exception.backtrace
    render_error(status: :internal_server_error, code: "internal_server_error",
                 message: "Something went wrong.")
  end

  def render_not_found(_exception)
    render_error(status: :not_found, code: "not_found",
                 message: "Resource not found.")
  end

  def render_parameter_missing(exception)
    render_error(status: :unprocessable_entity, code: "parameter_missing",
                 message: exception.message)
  end

  def render_unauthorized(exception)
    render_error(status: :unauthorized, code: "unauthorized",
                 message: exception.message)
  end

  def render_validation(exception)
    render_error(status: :unprocessable_entity, code: "validation_failed",
                 message: exception.message, details: exception.details)
  end
end
