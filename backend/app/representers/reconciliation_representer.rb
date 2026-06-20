require "roar/decorator"
require "roar/json"

# Public shape of a Reconciliation (issue 17). The created Adjustments are
# rendered as full Transactions (TransactionRepresenter) so the action is a
# self-describing audit record; `unchanged_source_ids` lists the sources that
# needed no Adjustment. Money stays integer minor units throughout (ADR-0015).
class ReconciliationRepresenter < Roar::Decorator
  include Roar::JSON

  collection :adjustments, decorator: TransactionRepresenter
  property :unchanged_source_ids
end
