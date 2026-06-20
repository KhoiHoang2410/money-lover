# Read model for a Transaction: wraps the persisted record and exposes its money
# fields as `Money` value objects for the representer. Keeps the AR edge and the
# serialized shape apart — the controller builds one of these per row and hands
# it to TransactionRepresenter.
class TransactionPresenter
  attr_reader :transaction

  def initialize(transaction)
    @transaction = transaction
  end

  def id = transaction.id
  def kind = transaction.kind
  def source_id = transaction.source_id
  def destination_id = transaction.destination_id
  def amount = transaction.amount
  def destination_amount = transaction.destination_amount
  def fee = transaction.fee
  def manual_rate = transaction.manual_rate
  def trade_quantity = transaction.trade_quantity
  def trade_direction = transaction.trade_direction
  def envelope_id = transaction.envelope_id
  def goal_id = transaction.goal_id
  def note = transaction.note
  def occurred_on = transaction.occurred_on
  def backfill? = transaction.backfill
end
