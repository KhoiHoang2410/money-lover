require "roar/decorator"
require "roar/json"

# Public shape of a resolved rate (RateService::ResolvedEntry). `value` is the
# exact decimal as a string — never a JSON number — so no precision is lost on
# the wire (ADR-0015). `source`/`fetched_at` carry the global's provenance and
# are null for an override that has no global counterpart.
class RateEntryRepresenter < Roar::Decorator
  include Roar::JSON

  property :key
  property :value, exec_context: :decorator
  property :source
  property :fetched_at, exec_context: :decorator
  property :stale
  property :overridden

  def value
    Rate.canonical_value(represented.value)
  end

  def fetched_at
    represented.fetched_at&.utc&.iso8601
  end
end
