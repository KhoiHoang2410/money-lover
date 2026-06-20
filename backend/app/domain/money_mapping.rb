# frozen_string_literal: true

# Edge mapping between persisted/serialized columns and the `Money` value
# object: a `bigint` minor-units column plus a currency string ↔ `Money`.
#
# Keeps the conversion in one place so representers and ActiveRecord models map
# money the same way (no Float ever crosses the edge — ADR-0015).
module MoneyMapping
  module_function

  # Serializes `money` to a primitive Hash (e.g. for a representer or a DB row):
  #   { minor_units: <Integer bigint>, currency: "<CODE>" }
  def dump(money)
    { minor_units: money.minor_units, currency: money.currency.to_s }
  end

  # Reconstructs a `Money` from a `bigint` minor-units value and a currency code.
  # `minor_units` is coerced with `Integer()` so a numeric String from the DB or
  # a JSON body is accepted, but a Float is rejected.
  def load(minor_units:, currency:)
    if minor_units.is_a?(Float)
      raise MoneyError::InexactValue, "minor_units must be an exact bigint, got Float #{minor_units.inspect}"
    end

    Money.new(minor_units: Integer(minor_units), currency: currency)
  end
end
