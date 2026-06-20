# Read model for a Reconciliation (issue 17): the auditable result of one
# Reconcile action — the Adjustment transactions it created plus the ids of the
# sources that were already on the money (no Adjustment needed). Wraps each
# created Transaction in a TransactionPresenter so the representer renders them
# in the same shape as the Transactions API.
class ReconciliationPresenter
  attr_reader :unchanged_source_ids

  def initialize(adjustments:, unchanged_source_ids:)
    @adjustments = adjustments
    @unchanged_source_ids = unchanged_source_ids
  end

  def adjustments
    @adjustments.map { |txn| TransactionPresenter.new(txn) }
  end
end
