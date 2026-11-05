# frozen_string_literal: true

require 'bigdecimal'

# Represents a product in the store
# Uses BigDecimal for price to ensure accurate financial calculations
class Product
  attr_reader :code, :name, :price

  def initialize(code:, name:, price:)
    @code = code.dup.freeze
    @name = name.dup.freeze
    @price = price.is_a?(BigDecimal) ? price : BigDecimal(price.to_s)
  end

  def ==(other)
    other.is_a?(Product) && code == other.code
  end

  def to_s
    "#{name} (#{code}): $#{'%.2f' % price}"
  end
end
