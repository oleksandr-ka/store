# frozen_string_literal: true

require_relative 'product_catalog'
require_relative 'product_loader'
require_relative 'discount_calculator'
require_relative 'discount_rules/base_rule'
require_relative 'discount_rules/buy_one_get_one_rule'
require_relative 'discount_rules/bulk_discount_rule'

# Main checkout system
# Accepts discount rules and provides scan/total interface
# Dependencies are injected explicitly (Dependency Injection pattern)
class Checkout
  attr_reader :rules, :catalog

  # Initialize checkout with discount rules and product catalog
  # @param rules [Array<DiscountRule>] discount rules to apply
  # @param catalog [ProductCatalog] product catalog (required dependency)
  def initialize(*rules, catalog:)
    @rules = rules.freeze
    @catalog = catalog
    @items = []
  end

  # Scan an item and add it to the cart
  # @param item_code [String] the product code (e.g., 'FR', 'SR')
  def scan(item_code)
    # Validate product exists
    @catalog.find(item_code)
    @items << item_code.dup.freeze
    self
  end

  # Calculate total price with discounts applied
  # @return [BigDecimal] the total price (rounded to 2 decimal places)
  def total
    calculator = DiscountCalculator.new(@items, @rules, @catalog)
    calculator.calculate
  end

  # Get detailed breakdown of prices and discounts
  # @return [Hash] detailed calculation breakdown
  def details
    calculator = DiscountCalculator.new(@items, @rules, @catalog)
    calculator.calculate_with_details
  end

  # Clear all items from cart
  def clear
    @items = []
  end

  def items
    @items.dup.freeze
  end

  # Get count of items in cart
  def item_count
    @items.size
  end
end
