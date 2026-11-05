# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Checkout do
  let(:catalog) { ProductLoader.default }
  let(:bogof_rule) { DiscountRules::BuyOneGetOneFreeRule.new('FR') }
  let(:bulk_rule) { DiscountRules::BulkDiscountRule.new('SR', 3, unit_price: '4.50') }

  describe '#initialize' do
    it 'accepts multiple discount rules' do
      checkout = Checkout.new(bogof_rule, bulk_rule, catalog: catalog)
      expect(checkout.rules).to eq([bogof_rule, bulk_rule])
    end

    it 'accepts a catalog as required dependency' do
      custom_catalog = ProductCatalog.new
      checkout = Checkout.new(catalog: custom_catalog)
      expect(checkout.catalog).to eq(custom_catalog)
    end

    it 'requires catalog parameter (explicit dependency)' do
      expect {
        Checkout.new(bogof_rule)
      }.to raise_error(ArgumentError, /missing keyword.*catalog/)
    end
  end

  describe '#scan' do
    let(:checkout) { Checkout.new(catalog: catalog) }

    it 'adds item to cart' do
      checkout.scan('FR')
      expect(checkout.items).to eq(['FR'])
    end

    it 'adds multiple items to cart' do
      checkout.scan('FR')
      checkout.scan('SR')
      checkout.scan('CF')
      expect(checkout.items).to eq(['FR', 'SR', 'CF'])
    end

    it 'raises error for invalid product code' do
      expect { checkout.scan('XX') }.to raise_error(ProductCatalog::ProductNotFoundError)
    end
  end

  describe '#total' do
    context 'without any discount rules' do
      let(:checkout) { Checkout.new(catalog: catalog) }

      it 'calculates total without discounts' do
        checkout.scan('FR') # 3.11
        checkout.scan('SR') # 5.00
        checkout.scan('CF') # 11.23
        expect(checkout.total).to eq(BigDecimal('19.34'))
      end
    end

    context 'with buy-one-get-one-free rule' do
      let(:checkout) { Checkout.new(bogof_rule, catalog: catalog) }

      it 'applies BOGOF discount for 2 items' do
        checkout.scan('FR') # 3.11
        checkout.scan('FR') # free
        expect(checkout.total).to eq(BigDecimal('3.11'))
      end

      it 'applies BOGOF discount for 3 items' do
        checkout.scan('FR') # 3.11
        checkout.scan('FR') # free
        checkout.scan('FR') # 3.11
        expect(checkout.total).to eq(BigDecimal('6.22'))
      end

      it 'applies BOGOF discount for 4 items' do
        checkout.scan('FR') # 3.11
        checkout.scan('FR') # free
        checkout.scan('FR') # 3.11
        checkout.scan('FR') # free
        expect(checkout.total).to eq(BigDecimal('6.22'))
      end
    end

    context 'with bulk discount rule' do
      let(:checkout) { Checkout.new(bulk_rule, catalog: catalog) }

      it 'does not apply bulk discount for 2 items' do
        checkout.scan('SR') # 5.00
        checkout.scan('SR') # 5.00
        expect(checkout.total).to eq(BigDecimal('10.00'))
      end

      it 'applies bulk discount for 3 items' do
        checkout.scan('SR') # 4.50
        checkout.scan('SR') # 4.50
        checkout.scan('SR') # 4.50
        expect(checkout.total).to eq(BigDecimal('13.50'))
      end

      it 'applies bulk discount for 4 items' do
        checkout.scan('SR') # 4.50 each
        checkout.scan('SR')
        checkout.scan('SR')
        checkout.scan('SR')
        expect(checkout.total).to eq(BigDecimal('18.00'))
      end
    end

    context 'with multiple discount rules' do
      let(:checkout) { Checkout.new(bogof_rule, bulk_rule, catalog: catalog) }

      # Example 1: FR, SR, FR, FR, CF
      # FR: 3 items → 2 paid (BOGOF) = 6.22
      # SR: 1 item = 5.00
      # CF: 1 item = 11.23
      # Total: 22.45
      it 'example 1: FR, SR, FR, FR, CF' do
        checkout.scan('FR')
        checkout.scan('SR')
        checkout.scan('FR')
        checkout.scan('FR')
        checkout.scan('CF')
        expect(checkout.total).to eq(BigDecimal('22.45'))
      end

      # Example 2: FR, FR
      # FR: 2 items → 1 paid (BOGOF) = 3.11
      # Total: 3.11
      it 'example 2: FR, FR' do
        checkout.scan('FR')
        checkout.scan('FR')
        expect(checkout.total).to eq(BigDecimal('3.11'))
      end

      # Example 3: SR, SR, FR, SR
      # SR: 3 items → bulk discount = 13.50
      # FR: 1 item = 3.11
      # Total: 16.61
      it 'example 3: SR, SR, FR, SR' do
        checkout.scan('SR')
        checkout.scan('SR')
        checkout.scan('FR')
        checkout.scan('SR')
        expect(checkout.total).to eq(BigDecimal('16.61'))
      end

      it 'applies both rules when both applicable' do
        checkout.scan('FR') # BOGOF: 3.11
        checkout.scan('FR') # BOGOF: free
        checkout.scan('SR') # Bulk: 4.50
        checkout.scan('SR') # Bulk: 4.50
        checkout.scan('SR') # Bulk: 4.50
        expect(checkout.total).to eq(BigDecimal('16.61'))
      end
    end
  end

  describe '#details' do
    let(:checkout) { Checkout.new(bogof_rule, bulk_rule, catalog: catalog) }

    it 'returns detailed breakdown of calculation' do
      checkout.scan('FR')
      checkout.scan('FR')
      checkout.scan('SR')
      checkout.scan('SR')
      checkout.scan('SR')

      details = checkout.details

      expect(details[:total]).to eq(BigDecimal('16.61'))
      expect(details[:items].size).to eq(2)

      fr_item = details[:items].find { |i| i[:product].code == 'FR' }
      expect(fr_item[:quantity]).to eq(2)
      expect(fr_item[:base_price]).to eq(BigDecimal('6.22'))
      expect(fr_item[:final_price]).to eq(BigDecimal('3.11'))
      expect(fr_item[:discount]).to eq(BigDecimal('3.11'))

      sr_item = details[:items].find { |i| i[:product].code == 'SR' }
      expect(sr_item[:quantity]).to eq(3)
      expect(sr_item[:base_price]).to eq(BigDecimal('15.00'))
      expect(sr_item[:final_price]).to eq(BigDecimal('13.50'))
      expect(sr_item[:discount]).to eq(BigDecimal('1.50'))
    end
  end

  describe '#clear' do
    let(:checkout) { Checkout.new(catalog: catalog) }

    it 'clears all items from cart' do
      checkout.scan('FR')
      checkout.scan('SR')
      checkout.clear
      expect(checkout.items).to be_empty
    end
  end

  describe '#item_count' do
    let(:checkout) { Checkout.new(catalog: catalog) }

    it 'returns number of items in cart' do
      checkout.scan('FR')
      checkout.scan('SR')
      checkout.scan('FR')
      expect(checkout.item_count).to eq(3)
    end
  end
end
