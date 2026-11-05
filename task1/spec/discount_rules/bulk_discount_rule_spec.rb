# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DiscountRules::BulkDiscountRule do
  let(:rule) { described_class.new('SR', 3, unit_price: '4.50') }
  let(:unit_price) { BigDecimal('5.00') }

  describe '#applicable?' do
    it 'returns false for quantity below minimum' do
      expect(rule.applicable?('SR', 1)).to be false
      expect(rule.applicable?('SR', 2)).to be false
    end

    it 'returns true for quantity at minimum' do
      expect(rule.applicable?('SR', 3)).to be true
    end

    it 'returns true for quantity above minimum' do
      expect(rule.applicable?('SR', 4)).to be true
      expect(rule.applicable?('SR', 10)).to be true
    end

    it 'returns false for different product' do
      expect(rule.applicable?('FR', 3)).to be false
    end
  end

  describe '#apply' do
    it 'returns full price when quantity below minimum' do
      expect(rule.apply('SR', 1, unit_price)).to eq(BigDecimal('5.00'))
      expect(rule.apply('SR', 2, unit_price)).to eq(BigDecimal('10.00'))
    end

    it 'returns discounted price when quantity at minimum' do
      # 3 items: $4.50 * 3 = $13.50
      expect(rule.apply('SR', 3, unit_price)).to eq(BigDecimal('13.50'))
    end

    it 'returns discounted price when quantity above minimum' do
      # 4 items: $4.50 * 4 = $18.00
      expect(rule.apply('SR', 4, unit_price)).to eq(BigDecimal('18.00'))

      # 5 items: $4.50 * 5 = $22.50
      expect(rule.apply('SR', 5, unit_price)).to eq(BigDecimal('22.50'))
    end

    it 'returns full price for different product' do
      expect(rule.apply('FR', 3, BigDecimal('3.11'))).to eq(BigDecimal('9.33'))
    end

    it 'works correctly if base price changes' do
      # If base price changes from $5.00 to $6.00, offer price remains $4.50
      new_price = BigDecimal('6.00')
      # 3 items: $4.50 * 3 = $13.50
      expect(rule.apply('SR', 3, new_price)).to eq(BigDecimal('13.50'))
    end
  end

  describe '#description' do
    it 'returns human-readable description' do
      expect(rule.description).to eq('SR: Buy 3+ for up to $4.50 each')
    end
  end
end
