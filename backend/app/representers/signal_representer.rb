require "roar/decorator"
require "roar/json"

# Public shape of a single Signal (issue 20): the stable `id`, its `kind` and
# `severity` as strings, and the deterministic plain-text `title`/`detail` the
# clients render directly (the Recommendation phrasing layer is deferred —
# ADR-0004 paused). Decorates a SignalEngine::Signal value object.
class SignalRepresenter < Roar::Decorator
  include Roar::JSON

  property :id
  property :kind, exec_context: :decorator
  property :severity, exec_context: :decorator
  property :title
  property :detail

  def kind = represented.kind.to_s
  def severity = represented.severity.to_s
end
