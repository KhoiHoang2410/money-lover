require "json"

# Integrity check for the shared, language-neutral golden fixtures extracted from
# the Swift `Core` test suite (issue 03 / ADR-0015). These fixtures are the parity
# oracle for the Ruby money engines (issues 07-12): each engine must reproduce the
# `expected_outputs` byte-for-byte. This spec guards the fixtures themselves so they
# cannot silently drift into a malformed or float-money shape.
RSpec.describe "Golden fixtures integrity" do
  GOLDEN_DIR = File.expand_path("../../../golden/fixtures", __dir__).freeze
  EXPECTED_ENGINES = %w[
    balances
    holding_quantity
    valuation
    net_worth
    budgets
    goal_tracking
    reconcile
    fx_fees
  ].freeze

  KNOWN_CURRENCIES = %w[VND USD SGD].freeze

  # Recursively yields every Money-shaped node ({ "minor_units" => ..., "currency" => ... })
  # found anywhere in the parsed JSON, with a dotted path for diagnostics.
  def each_money(node, path = "$", &block)
    case node
    when Hash
      block.call(path, node) if node.key?("minor_units")
      node.each { |k, v| each_money(v, "#{path}.#{k}", &block) }
    when Array
      node.each_with_index { |v, i| each_money(v, "#{path}[#{i}]", &block) }
    end
  end

  fixture_files = Dir.glob(File.join(GOLDEN_DIR, "*.json")).sort

  it "has exactly one fixture file per engine area" do
    engines = fixture_files.map { |f| File.basename(f, ".json") }.sort
    expect(engines).to eq(EXPECTED_ENGINES.sort)
  end

  it "finds at least one fixture file" do
    expect(fixture_files).not_to be_empty
  end

  fixture_files.each do |path|
    name = File.basename(path)

    describe name do
      let(:doc) { JSON.parse(File.read(path)) }

      it "is valid JSON with the required top-level schema" do
        expect(doc).to be_a(Hash)
        expect(doc["engine"]).to be_a(String).and(satisfy { |s| !s.empty? })
        expect(doc["engine"]).to eq(File.basename(path, ".json"))
        expect(doc["description"]).to be_a(String).and(satisfy { |s| !s.empty? })

        tests = doc["source_swift_tests"]
        expect(tests).to be_a(Array).and(satisfy { |a| !a.empty? })
        expect(tests).to all(be_a(String))

        expect(doc["cases"]).to be_a(Array).and(satisfy { |a| !a.empty? })
      end

      it "has well-formed cases (name, inputs, expected_outputs)" do
        names = doc["cases"].map { |c| c["name"] }
        expect(names).to all(be_a(String).and(satisfy { |s| !s.empty? }))
        expect(names).to eq(names.uniq), "case names must be unique"

        doc["cases"].each do |c|
          expect(c["inputs"]).to be_a(Hash), "#{c['name']}: inputs must be an object"
          expect(c["expected_outputs"]).to be_a(Hash),
                                            "#{c['name']}: expected_outputs must be an object"
          expect(c["method"]).to be_a(String).or(be_nil)
        end
      end

      it "encodes every Money value as an integer minor_units with a known currency" do
        seen = 0
        each_money(doc) do |money_path, money|
          seen += 1
          minor = money["minor_units"]
          expect(minor).to be_a(Integer),
                           "#{money_path}.minor_units must be an Integer, got #{minor.inspect}"
          # Guard against float-backed money slipping through as a whole number.
          expect(minor).not_to be_a(Float), "#{money_path}.minor_units must not be a float"

          currency = money["currency"]
          expect(currency).to be_a(String), "#{money_path}.currency must be a String"
          expect(KNOWN_CURRENCIES).to include(currency),
                                      "#{money_path}.currency #{currency.inspect} is not a known currency"
        end
        expect(seen).to be > 0, "fixture should contain at least one Money value"
      end
    end
  end
end
