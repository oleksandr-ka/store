# frozen_string_literal: true

require 'bigdecimal'
require_relative 'base_rule'

module DiscountRules
  # Buy One Get One Free discount rule
  # Example: Buy 2 Fruit Teas, pay for 1
  # Uses BigDecimal for precise financial calculations
  class BuyOneGetOneFreeRule < BaseRule
    attr_reader :product_code

    def initialize(product_code)
      @product_code = product_code.dup.freeze
    end

    def applicable?(product_code, quantity)
      product_code == @product_code && quantity >= 2
    end

    def apply(product_code, quantity, unit_price)
      return unit_price * quantity unless applicable?(product_code, quantity)

      # Pay for half (rounded up) of the items
      paid_items = (quantity + 1) / 2
      unit_price * paid_items
    end

    def description
      "#{@product_code}: Buy one, get one free"
    end
  end
end
