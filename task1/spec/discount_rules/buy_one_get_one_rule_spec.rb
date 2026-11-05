# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DiscountRules::BuyOneGetOneFreeRule do
  let(:rule) { described_class.new('FR') }
  let(:unit_price) { BigDecimal('3.11') }

  describe '#applicable?' do
    it 'returns false for 1 item' do
      expect(rule.applicable?('FR', 1)).to be false
    end

    it 'returns true for 2 items' do
      expect(rule.applicable?('FR', 2)).to be true
    end

    it 'returns true for 3+ items' do
      expect(rule.applicable?('FR', 3)).to be true
      expect(rule.applicable?('FR', 10)).to be true
    end

    it 'returns false for different product' do
      expect(rule.applicable?('SR', 2)).to be false
    end
  end

  describe '#apply' do
    it 'returns full price for 1 item' do
      expect(rule.apply('FR', 1, unit_price)).to eq(BigDecimal('3.11'))
    end

    it 'returns half price for 2 items' do
      expect(rule.apply('FR', 2, unit_price)).to eq(BigDecimal('3.11'))
    end

    it 'returns 2x price for 3 items (pay for 2, get 1 free)' do
      expect(rule.apply('FR', 3, unit_price)).to eq(BigDecimal('6.22'))
    end

    it 'returns 2x price for 4 items (pay for 2, get 2 free)' do
      expect(rule.apply('FR', 4, unit_price)).to eq(BigDecimal('6.22'))
    end

    it 'returns 3x price for 5 items (pay for 3, get 2 free)' do
      expect(rule.apply('FR', 5, unit_price)).to eq(BigDecimal('9.33'))
    end

    it 'returns full price for different product' do
      expect(rule.apply('SR', 2, BigDecimal('5.00'))).to eq(BigDecimal('10.00'))
    end
  end

  describe '#description' do
    it 'returns human-readable description' do
      expect(rule.description).to eq('FR: Buy one, get one free')
    end
  end
end
