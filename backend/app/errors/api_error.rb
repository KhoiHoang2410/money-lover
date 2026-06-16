module ApiError
  class Base < StandardError; end

  class Unauthorized < Base
    def initialize(message = "Authentication is required.")
      super
    end
  end

  class Validation < Base
    attr_reader :details

    def initialize(message = "Validation failed.", details: nil)
      @details = details
      super(message)
    end
  end
end
