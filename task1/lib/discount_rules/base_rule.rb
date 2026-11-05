# frozen_string_literal: true

module DiscountRules
  # Base class for all discount rules
  # Implements Strategy Pattern - each rule is an independent strategy
  # that can be applied to calculate discounts
  class BaseRule
    # Checks if this rule applies to the given product and quantity
    # @param product_code [String] the product code
    # @param quantity [Integer] the quantity of items
    # @return [Boolean] true if rule applies
    def applicable?(product_code, quantity)
      raise NotImplementedError, "#{self.class} must implement #applicable?"
    end

    # Calculates the final price after applying the discount
    # @param product_code [String] the product code
    # @param quantity [Integer] the quantity of items
    # @param unit_price [BigDecimal] the unit price of the product
    # @return [BigDecimal] the final price after discount
    def apply(product_code, quantity, unit_price)
      raise NotImplementedError, "#{self.class} must implement #apply"
    end

    # Returns a human-readable description of the rule
    # @return [String] rule description
    def description
      raise NotImplementedError, "#{self.class} must implement #description"
    end
  end
end
