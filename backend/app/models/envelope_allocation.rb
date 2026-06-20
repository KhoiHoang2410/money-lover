# One Envelope's Allocation snapshot for a single month (CONTEXT.md "Allocation"
# / "Allocation template"). Per-month history is what makes the month-end Reserve
# sweep derivable on read (PRD § envelopes), so applying a template for a month
# upserts one of these per Envelope. Tenant-scoped via Tenanted (ADR-0014); money
# is integer minor units + a currency code (ADR-0015).
class EnvelopeAllocation < ApplicationRecord
  include Tenanted

  belongs_to :envelope, inverse_of: :allocations

  validates :month, presence: true
  validates :currency, presence: true
  validates :allocation_minor_units, presence: true
  validates :envelope_id, uniqueness: { scope: :month }

  # The snapshot Allocation as a `Money`.
  def allocation
    MoneyMapping.load(minor_units: allocation_minor_units, currency: currency)
  end
end
