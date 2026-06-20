# frozen_string_literal: true

# Composes the per-source `Valuator` (issue 08) into the two derived net-worth
# totals (CONTEXT.md "Net worth"):
#
#   - **Asset** = Σ value of every non-liability source (Accounts + Holdings) plus
#     every Goal balance, each valued in the base currency (VND) via resolved rates.
#   - **Debt**  = Σ value of every Liability source (Credit cards), kept negative.
#   - **net**   = Asset + Debt (Debt is non-positive, so net = Asset − |Debt|).
#
# Both Asset and Debt are *derived numbers, not entities* (CONTEXT.md). A Goal is a
# funded Asset (ADR-0007): its balance is the accumulated Contributions, so it is
# added to the Asset total directly. This makes the conservation invariants fall out
# of the arithmetic:
#
#   - A Contribution moves money from an Account (↓) into a Goal (↑) by the same
#     amount — one Asset becomes another, net is unchanged.
#   - An Invest trade moves money between an Account (↓) and a Holding (↑) at the
#     trade price — again one Asset becomes another, net is unchanged.
#
# Pure Ruby — no Rails, no DB, no Float (ADR-0015). The classification key is the
# *sign of the valued amount*, not the source kind, so a foreign Account that
# happens to be overdrawn still lands in Debt and a paid-off card contributes ₫0.
# This is the Ruby side of the `golden/fixtures/net_worth.json` parity oracle.
module NetWorthEngine
  # One valuation input: a money/holding source and its current balance. Mirrors a
  # `BalanceEngine::Source` plus the optional `Holding` facts the Valuator needs.
  #
  #   - `kind`     — :account, :credit_card, or :holding.
  #   - `currency` — the source's native currency.
  #   - `balance`  — the source's current `Money` (₫0 for a Holding, which prices
  #     off quantity, not a money balance).
  #   - `holding`  — the `Holding` facts when `kind` is :holding, else nil.
  Entry = Data.define(:kind, :currency, :balance, :holding) do
    def self.build(kind:, currency:, balance:, holding: nil)
      new(
        kind: kind.to_sym,
        currency: Currency.normalize(currency),
        balance: balance,
        holding: holding
      )
    end
  end

  # The three derived totals, all in VND.
  Result = Data.define(:asset, :debt, :net)

  module_function

  # @param entries       [Array<NetWorthEngine::Entry>] every money/holding source
  # @param goal_balances [Array<Money>] each Goal's accumulated balance
  # @param rates         [Rates] resolved conversion rates
  # @return [NetWorthEngine::Result] asset / debt / net, each a VND `Money`
  def compute(entries:, rates:, goal_balances: [])
    source_values = entries.map do |entry|
      Valuator.value_in_vnd(
        kind: entry.kind,
        currency: entry.currency,
        balance: entry.balance,
        rates: rates,
        holding: entry.holding
      )
    end

    goal_values = goal_balances.map { |balance| to_vnd(balance, rates) }

    asset = Money.sum(
      [ *source_values.reject(&:negative?), *goal_values ],
      currency: :VND
    )
    debt = Money.sum(source_values.select(&:negative?), currency: :VND)

    Result.new(asset: asset, debt: debt, net: asset + debt)
  end

  # Values a Goal balance in VND. Goals are VND-only today (CONTEXT.md
  # "Contribution"), so this is the identity for them; converting via the resolved
  # FX rate keeps the engine total-correct if that ever widens.
  def to_vnd(balance, rates)
    return balance if balance.currency == :VND

    balance.convert(to: :VND, rate: rates.fx_rate(balance.currency))
  end
end
