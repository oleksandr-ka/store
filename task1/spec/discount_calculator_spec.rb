# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DiscountCalculator do
  let(:catalog) { ProductLoader.default }
  let(:bogof_rule) { DiscountRules::BuyOneGetOneFreeRule.new('FR') }
  let(:bulk_rule) { DiscountRules::BulkDiscountRule.new('SR', 3, unit_price: '4.50') }

  describe '#calculate' do
    it 'calculates total without any rules' do
      calculator = DiscountCalculator.new(['FR', 'SR'], [], catalog)
      expect(calculator.calculate).to eq(BigDecimal('8.11')) # 3.11 + 5.00
    end

    it 'calculates total with BOGOF rule' do
      calculator = DiscountCalculator.new(['FR', 'FR'], [bogof_rule], catalog)
      expect(calculator.calculate).to eq(BigDecimal('3.11'))
    end

    it 'calculates total with bulk discount rule' do
      calculator = DiscountCalculator.new(['SR', 'SR', 'SR'], [bulk_rule], catalog)
      expect(calculator.calculate).to eq(BigDecimal('13.50'))
    end

    it 'calculates total with multiple rules' do
      items = ['FR', 'FR', 'SR', 'SR', 'SR']
      calculator = DiscountCalculator.new(items, [bogof_rule, bulk_rule], catalog)
      expect(calculator.calculate).to eq(BigDecimal('16.61')) # 3.11 + 13.50
    end

    it 'rounds result to 2 decimal places' do
      items = ['CF'] # 11.23
      calculator = DiscountCalculator.new(items, [], catalog)
      expect(calculator.calculate).to eq(BigDecimal('11.23'))
    end
  end

  describe '#calculate_with_details' do
    it 'returns detailed breakdown' do
      items = ['FR', 'FR', 'SR', 'SR', 'SR']
      calculator = DiscountCalculator.new(items, [bogof_rule, bulk_rule], catalog)
      result = calculator.calculate_with_details

      expect(result[:total]).to eq(BigDecimal('16.61'))
      expect(result[:items]).to be_an(Array)
      expect(result[:items].size).to eq(2)

      fr_item = result[:items].find { |i| i[:product].code == 'FR' }
      expect(fr_item).to include(
        quantity: 2,
        base_price: BigDecimal('6.22'),
        final_price: BigDecimal('3.11'),
        discount: BigDecimal('3.11')
      )

      sr_item = result[:items].find { |i| i[:product].code == 'SR' }
      expect(sr_item).to include(
        quantity: 3,
        base_price: BigDecimal('15.00'),
        final_price: BigDecimal('13.50'),
        discount: BigDecimal('1.50')
      )
    end

    it 'includes rule description when rule applied' do
      items = ['FR', 'FR']
      calculator = DiscountCalculator.new(items, [bogof_rule], catalog)
      result = calculator.calculate_with_details

      fr_item = result[:items].find { |i| i[:product].code == 'FR' }
      expect(fr_item[:rule_applied]).to eq('FR: Buy one, get one free')
    end

    it 'has nil rule_applied when no rule applies' do
      items = ['FR']
      calculator = DiscountCalculator.new(items, [bogof_rule], catalog)
      result = calculator.calculate_with_details

      fr_item = result[:items].find { |i| i[:product].code == 'FR' }
      expect(fr_item[:rule_applied]).to be_nil
    end
  end
end
