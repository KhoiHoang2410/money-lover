require "rails_helper"
require "json"

# BalanceEngine (issue 07): current balance = opening + Σ signed balance-affecting
# transactions, per source (CONTEXT.md "Current balance"). The heart of the spec is
# the **golden-vector** check: every case in the shared `golden/fixtures/balances.json`
# (issue 03 / ADR-0015) must reproduce byte-identically, proving the Ruby engine is a
# faithful port of the Swift `Core` BalanceEngine — a verification, not a re-derivation.
RSpec.describe BalanceEngine do
  GOLDEN_BALANCES = File.expand_path("../../../golden/fixtures/balances.json", __dir__).freeze

  def money(node)
    MoneyMapping.load(minor_units: node.fetch("minor_units"), currency: node.fetch("currency"))
  end

  def build_source(node)
    BalanceEngine::Source.build(
      id: node.fetch("id"),
      kind: node.fetch("kind"),
      currency: node.fetch("currency"),
      opening_balance: money(node.fetch("opening_balance"))
    )
  end

  def build_transaction(node)
    BalanceEngine::Transaction.build(
      kind: node.fetch("kind"),
      amount: money(node.fetch("amount")),
      source_id: node["source_id"],
      destination_id: node["destination_id"],
      destination_amount: (money(node["destination_amount"]) if node["destination_amount"]),
      direction: node["direction"]
    )
  end

  # Dispatches a fixture case to the engine method named by its `method` field.
  def run_case(kase)
    inputs = kase.fetch("inputs")
    case kase.fetch("method")
    when "current"
      described_class.current(
        opening: money(inputs.fetch("opening")),
        deltas: inputs.fetch("deltas").map { |d| money(d) }
      )
    when "balance"
      described_class.balance(
        source: build_source(inputs.fetch("source")),
        transactions: inputs.fetch("transactions").map { |t| build_transaction(t) }
      )
    else
      raise "unknown fixture method: #{kase['method'].inspect}"
    end
  end

  describe "golden fixtures parity (byte-identical with Swift Core)" do
    doc = JSON.parse(File.read(GOLDEN_BALANCES))

    it "covers the balances engine fixture" do
      expect(doc["engine"]).to eq("balances")
      expect(doc["cases"]).not_to be_empty
    end

    doc.fetch("cases").each do |kase|
      it "reproduces '#{kase['name']}'" do
        expected = kase.fetch("expected_outputs")

        if expected.key?("error")
          # Currency-mismatch is the only error the fixtures assert; the engine
          # must raise rather than silently coerce (ADR-0015).
          expect(expected.fetch("error")).to eq("currency_mismatch")
          expect { run_case(kase) }.to raise_error(MoneyError::CurrencyMismatch)
        else
          result = run_case(kase)
          want = money(expected.fetch("balance"))
          # Assert on the underlying primitives so the failure message is the
          # exact minor_units/currency, matching the fixture byte-for-byte.
          expect(result.minor_units).to eq(want.minor_units)
          expect(result.currency).to eq(want.currency)
          expect(result).to eq(want)
        end
      end
    end
  end

  describe "the balance invariant (current = opening + Σ deltas)" do
    it "holds for every balance-method fixture case" do
      JSON.parse(File.read(GOLDEN_BALANCES)).fetch("cases").each do |kase|
        next unless kase["method"] == "balance"

        source = build_source(kase.dig("inputs", "source"))
        txns = kase.dig("inputs", "transactions").map { |t| build_transaction(t) }
        deltas = txns.filter_map { |t| described_class.delta_for(source, t) }

        recomposed = described_class.current(opening: source.opening_balance, deltas: deltas)
        expect(described_class.balance(source: source, transactions: txns)).to eq(recomposed)
      end
    end
  end

  describe ".current" do
    it "returns the opening when there are no deltas" do
      opening = Money.from_major(80_000_000, :VND)
      expect(described_class.current(opening: opening, deltas: [])).to eq(opening)
    end

    it "sums signed deltas onto the opening" do
      result = described_class.current(
        opening: Money.new(minor_units: 80_000_000, currency: :VND),
        deltas: [
          Money.new(minor_units: -40_000, currency: :VND),
          Money.new(minor_units: 10_000_000, currency: :VND)
        ]
      )
      expect(result).to eq(Money.new(minor_units: 89_960_000, currency: :VND))
    end

    it "raises on a currency-mismatched delta instead of coercing" do
      expect do
        described_class.current(
          opening: Money.zero(:VND),
          deltas: [ Money.new(minor_units: 100, currency: :USD) ]
        )
      end.to raise_error(MoneyError::CurrencyMismatch)
    end
  end

  describe ".balance edge cases" do
    let(:account) do
      BalanceEngine::Source.build(
        id: "acc", kind: :account, currency: :VND,
        opening_balance: Money.new(minor_units: 80_000_000, currency: :VND)
      )
    end

    let(:credit_card) do
      BalanceEngine::Source.build(
        id: "card", kind: :credit_card, currency: :VND,
        opening_balance: Money.new(minor_units: -18_300_000, currency: :VND)
      )
    end

    it "increases a Credit card's Liability (more negative) on an expense" do
      txn = BalanceEngine::Transaction.build(
        kind: :expense, amount: Money.new(minor_units: 700_000, currency: :VND), source_id: "card"
      )
      result = described_class.balance(source: credit_card, transactions: [ txn ])
      expect(result).to eq(Money.new(minor_units: -19_000_000, currency: :VND))
      expect(result).to be_negative
    end

    it "credits the destination with the destination amount on a cross-currency transfer" do
      # Wise SGD → VPBank VND: source side debits SGD, the VND Account is credited
      # the *arriving* VND amount, never the source-currency figure (CONTEXT.md Transfer).
      txn = BalanceEngine::Transaction.build(
        kind: :transfer,
        amount: Money.new(minor_units: 10_000, currency: :SGD),       # 100.00 SGD out
        destination_amount: Money.new(minor_units: 1_800_000, currency: :VND), # arrives as VND
        source_id: "wise_sgd",
        destination_id: "acc"
      )
      result = described_class.balance(source: account, transactions: [ txn ])
      expect(result).to eq(Money.new(minor_units: 81_800_000, currency: :VND))
    end

    it "debits the source side of a same-currency transfer by its amount" do
      txn = BalanceEngine::Transaction.build(
        kind: :transfer, amount: Money.new(minor_units: 5_000_000, currency: :VND),
        source_id: "acc", destination_id: "card"
      )
      expect(described_class.balance(source: account, transactions: [ txn ]))
        .to eq(Money.new(minor_units: 75_000_000, currency: :VND))
    end

    it "applies the signed reconcile delta of an Adjustment" do
      txn = BalanceEngine::Transaction.build(
        kind: :adjustment, amount: Money.new(minor_units: -25_000, currency: :VND), source_id: "acc"
      )
      expect(described_class.balance(source: account, transactions: [ txn ]))
        .to eq(Money.new(minor_units: 79_975_000, currency: :VND))
    end

    it "debits the Account money leg on an Invest buy and credits it on a sell" do
      buy = BalanceEngine::Transaction.build(
        kind: :invest, amount: Money.new(minor_units: 3_000_000, currency: :VND),
        source_id: "acc", direction: :buy
      )
      sell = BalanceEngine::Transaction.build(
        kind: :invest, amount: Money.new(minor_units: 1_000_000, currency: :VND),
        source_id: "acc", direction: :sell
      )
      expect(described_class.balance(source: account, transactions: [ buy, sell ]))
        .to eq(Money.new(minor_units: 78_000_000, currency: :VND))
    end

    it "ignores transactions that touch a different source" do
      txn = BalanceEngine::Transaction.build(
        kind: :expense, amount: Money.new(minor_units: 1, currency: :VND), source_id: "card"
      )
      expect(described_class.balance(source: account, transactions: [ txn ]))
        .to eq(account.opening_balance)
    end

    it "raises on an unknown transaction kind" do
      txn = BalanceEngine::Transaction.build(
        kind: :teleport, amount: Money.zero(:VND), source_id: "acc"
      )
      expect { described_class.balance(source: account, transactions: [ txn ]) }
        .to raise_error(ArgumentError, /unknown transaction kind/)
    end
  end
end
