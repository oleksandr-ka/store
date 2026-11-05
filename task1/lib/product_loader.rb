# frozen_string_literal: true

require 'json'
require 'bigdecimal'
require_relative 'product'
require_relative 'product_catalog'

# Loads products from external data sources (JSON, YAML, database, etc.)
# Separates data configuration from business logic
class ProductLoader
  class LoadError < StandardError; end

  # Load products from JSON file
  # @param file_path [String] path to JSON file
  # @return [ProductCatalog] catalog populated with products
  def self.from_json(file_path)
    data = JSON.parse(File.read(file_path))
    unless data.is_a?(Hash) && data['products'].is_a?(Array)
      raise LoadError, 'Expected a products array'
    end

    build_catalog(data['products'], %w[code name price])
  rescue Errno::ENOENT
    raise LoadError, "File not found: #{file_path}"
  rescue SystemCallError => e
    raise LoadError, "Cannot read catalog: #{e.message}"
  rescue JSON::ParserError => e
    raise LoadError, "Invalid JSON: #{e.message}"
  end

  # Load default grocery store catalog
  # @return [ProductCatalog] catalog with default products
  def self.default
    file_path = File.join(__dir__, '..', 'data', 'products.json')
    from_json(file_path)
  end

  # Load products from array of hashes (useful for testing)
  # @param products_data [Array<Hash>] array of product hashes
  # @return [ProductCatalog] catalog populated with products
  def self.from_array(products_data)
    build_catalog(products_data, %i[code name price])
  end

  private_class_method def self.build_catalog(rows, fields)
    catalog = ProductCatalog.new
    rows.each_with_index do |row, index|
      context = "Product at index #{index}"
      raise LoadError, "#{context}: expected an object" unless row.is_a?(Hash)

      missing = fields.select { |field| row[field].nil? }
      raise LoadError, "#{context}: Missing required field(s): #{missing.join(', ')}" unless missing.empty?

      code, name, raw_price = row.values_at(*fields)
      unless [code, name].all? { |value| value.is_a?(String) && !value.strip.empty? }
        raise LoadError, "#{context}: code and name must be nonempty strings"
      end
      raise LoadError, "#{context}: duplicate code #{code}" if catalog.exists?(code)

      price = BigDecimal(raw_price.to_s, exception: false)
      unless price && price.finite? && price >= 0 && price == price.round(2)
        raise LoadError, "#{context}: price must be nonnegative and expressed in whole cents"
      end

      catalog.add_product(Product.new(code: code, name: name, price: price))
    end
    catalog
  end
end
