# frozen_string_literal: true

require 'bigdecimal'
require_relative 'base_rule'

module DiscountRules
  # Offers a fixed unit price once the minimum quantity is reached.
  class BulkDiscountRule < BaseRule
    attr_reader :product_code, :minimum_quantity, :unit_price

    def initialize(product_code, minimum_quantity, unit_price:)
      unless minimum_quantity.is_a?(Integer) && minimum_quantity.positive?
        raise ArgumentError, 'Minimum quantity must be a positive integer'
      end

      @product_code = product_code.dup.freeze
      @minimum_quantity = minimum_quantity
      @unit_price = BigDecimal(unit_price.to_s)
      unless @unit_price.finite? && @unit_price >= 0 && @unit_price == @unit_price.round(2)
        raise ArgumentError, 'Offer price must be nonnegative and expressed in whole cents'
      end
    end

    def applicable?(product_code, quantity)
      product_code == @product_code && quantity >= @minimum_quantity
    end

    def apply(product_code, quantity, unit_price)
      price = applicable?(product_code, quantity) ? [unit_price, @unit_price].min : unit_price
      price * quantity
    end

    def description
      "#{@product_code}: Buy #{@minimum_quantity}+ for up to $#{'%.2f' % @unit_price} each"
    end
  end
end
