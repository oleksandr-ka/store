# frozen_string_literal: true

require 'spec_helper'
require 'open3'
require 'tempfile'

RSpec.describe 'Checkout regressions' do
  it 'keeps the strawberry offer at $4.50 when the catalog price changes' do
    catalog = ProductLoader.from_array([{ code: 'SR', name: 'Strawberries', price: '6.00' }])
    rule = DiscountRules::BulkDiscountRule.new('SR', 3, unit_price: '4.50')
    checkout = Checkout.new(rule, catalog: catalog)
    3.times { checkout.scan('SR') }
    expect(checkout.total).to eq(BigDecimal('13.50'))
  end

  it 'keeps scanned codes and the cart independent of caller mutations' do
    checkout = Checkout.new(catalog: ProductLoader.default)
    code = +'FR'
    expect(checkout.scan(code)).to equal(checkout)
    code.replace('CF')
    expect { checkout.items << 'XX' }.to raise_error(FrozenError)
    expect(checkout.total).to eq(BigDecimal('3.11'))
  end

  it 'sums the rounded amounts shown on the receipt' do
    rule = Class.new do
      def applicable?(_code, _quantity) = true
      def apply(_code, _quantity, _price) = BigDecimal('0.005')
      def description = 'Test offer'
    end.new
    checkout = Checkout.new(rule, catalog: ProductLoader.default)
    %w[FR CF].each { |code| checkout.scan(code) }
    details = checkout.details
    expect(details[:total]).to eq(BigDecimal('0.02'))
    expect(checkout.total).to eq(details[:items].sum { |item| item[:final_price] })
  end

  ['{}', '{"products":[{"code":"X","name":"X","price":"oops"}]}',
   '{"products":[{"code":"X","name":"X","price":"-1"}]}'].each do |json|
    it "rejects invalid catalog data: #{json}" do
      Tempfile.create do |file|
        file.write(json)
        file.flush
        expect { ProductLoader.from_json(file.path) }.to raise_error(ProductLoader::LoadError)
      end
    end
  end

  it 'accepts surrounding whitespace and exits successfully at EOF' do
    output, status = Open3.capture2e(
      RbConfig.ruby, File.expand_path('../bin/interactive', __dir__), stdin_data: " fr \n total \n"
    )
    expect(status).to be_success
    expect(output).to include('Total: $3.11')
  end
end
