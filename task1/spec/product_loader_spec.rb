# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe ProductLoader do
  describe '.from_json' do
    it 'loads products from valid JSON file' do
      json_data = {
        products: [
          { code: 'TEST1', name: 'Test Product 1', price: '1.11' },
          { code: 'TEST2', name: 'Test Product 2', price: '2.22' }
        ]
      }.to_json

      file = Tempfile.new(['products', '.json'])
      file.write(json_data)
      file.close

      catalog = ProductLoader.from_json(file.path)

      expect(catalog).to be_a(ProductCatalog)
      expect(catalog.count).to eq(2)
      expect(catalog.find('TEST1').name).to eq('Test Product 1')
      expect(catalog.find('TEST1').price).to eq(BigDecimal('1.11'))
      expect(catalog.find('TEST2').name).to eq('Test Product 2')

      file.unlink
    end

    it 'raises error for non-existent file' do
      expect {
        ProductLoader.from_json('/non/existent/file.json')
      }.to raise_error(ProductLoader::LoadError, /File not found/)
    end

    it 'raises error for invalid JSON' do
      file = Tempfile.new(['invalid', '.json'])
      file.write('{ invalid json }')
      file.close

      expect {
        ProductLoader.from_json(file.path)
      }.to raise_error(ProductLoader::LoadError, /Invalid JSON/)

      file.unlink
    end

    it 'raises error for missing required fields' do
      json_data = {
        products: [
          { code: 'TEST1', name: 'Test Product 1' }  # Missing price
        ]
      }.to_json

      file = Tempfile.new(['incomplete', '.json'])
      file.write(json_data)
      file.close

      expect {
        ProductLoader.from_json(file.path)
      }.to raise_error(ProductLoader::LoadError, /Missing required field/)

      file.unlink
    end
  end

  describe '.default' do
    it 'loads default product catalog from data/products.json' do
      catalog = ProductLoader.default

      expect(catalog).to be_a(ProductCatalog)
      expect(catalog.count).to eq(4)

      # Verify all default products are loaded
      expect(catalog.find('FR').name).to eq('Fruit Tea')
      expect(catalog.find('FR').price).to eq(BigDecimal('3.11'))

      expect(catalog.find('SR').name).to eq('Strawberries')
      expect(catalog.find('SR').price).to eq(BigDecimal('5.00'))

      expect(catalog.find('CF').name).to eq('Coffee')
      expect(catalog.find('CF').price).to eq(BigDecimal('11.23'))

      expect(catalog.find('AJ').name).to eq('Apple Juice')
      expect(catalog.find('AJ').price).to eq(BigDecimal('7.25'))
    end
  end

  describe '.from_array' do
    it 'loads products from array of hashes' do
      products_data = [
        { code: 'TEST1', name: 'Test Product 1', price: BigDecimal('1.11') },
        { code: 'TEST2', name: 'Test Product 2', price: BigDecimal('2.22') }
      ]

      catalog = ProductLoader.from_array(products_data)

      expect(catalog).to be_a(ProductCatalog)
      expect(catalog.count).to eq(2)
      expect(catalog.find('TEST1').name).to eq('Test Product 1')
      expect(catalog.find('TEST1').price).to eq(BigDecimal('1.11'))
    end

    it 'works with empty array' do
      catalog = ProductLoader.from_array([])

      expect(catalog).to be_a(ProductCatalog)
      expect(catalog.count).to eq(0)
    end
  end
end
