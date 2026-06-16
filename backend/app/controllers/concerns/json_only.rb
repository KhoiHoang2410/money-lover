module JsonOnly
  extend ActiveSupport::Concern

  JSON_MEDIA_TYPE = "application/json".freeze

  included do
    before_action :ensure_json_request
  end

  private

  def ensure_json_request
    if request_has_body? && request.media_type != JSON_MEDIA_TYPE
      return render_error(
        status: :unsupported_media_type,
        code: "unsupported_media_type",
        message: "Request body must be #{JSON_MEDIA_TYPE}."
      )
    end

    return if accepts_json?

    render_error(
      status: :not_acceptable,
      code: "not_acceptable",
      message: "This API only produces #{JSON_MEDIA_TYPE}."
    )
  end

  def request_has_body?
    request.content_length.to_i.positive? || request.media_type.present?
  end

  def accepts_json?
    accept = request.headers["Accept"].to_s
    accept.blank? || accept.include?(JSON_MEDIA_TYPE) || accept.include?("*/*")
  end
end
