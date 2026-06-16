require "roar/decorator"
require "roar/json"

class StatusRepresenter < Roar::Decorator
  include Roar::JSON

  property :status
end
