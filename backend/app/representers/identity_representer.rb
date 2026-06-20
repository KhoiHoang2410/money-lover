require "roar/decorator"
require "roar/json"

# Public shape of an Identity. Deliberately omits password_digest — credential
# material never crosses the API boundary.
class IdentityRepresenter < Roar::Decorator
  include Roar::JSON

  property :id
  property :provider
  property :external_id
end
