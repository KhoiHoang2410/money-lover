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

  # The request conflicts with the resource's current state — e.g. deleting a
  # source that transactions still reference (issue 13 delete integrity).
  class Conflict < Base
    def initialize(message = "The request conflicts with the current state.")
      super
    end
  end
end
