# frozen_string_literal: true

require 'bigdecimal'

class DiscountCalculator
  def initialize(items, rules, catalog)
    @items = items
    @rules = rules
    @catalog = catalog
  end

  def calculate
    lines.sum(BigDecimal('0')) { |line| line[:final_price] }
  end

  def calculate_with_details
    items = lines
    items.each { |line| line[:rule_applied] = line.delete(:rule)&.description }
    { items: items, total: items.sum(BigDecimal('0')) { |line| line[:final_price] } }
  end

  private

  def lines
    @items.tally.map do |code, quantity|
      product = @catalog.find(code)
      rule = @rules.find { |candidate| candidate.applicable?(code, quantity) }
      base_price = round_money(product.price * quantity)
      final_price = rule ? round_money(rule.apply(code, quantity, product.price)) : base_price

      {
        product: product,
        quantity: quantity,
        base_price: base_price,
        final_price: final_price,
        discount: base_price - final_price,
        rule: rule
      }
    end
  end

  def round_money(amount)
    amount.round(2, BigDecimal::ROUND_HALF_UP)
  end
end
