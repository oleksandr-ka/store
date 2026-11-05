# frozen_string_literal: true

require_relative 'product'

# Manages the product catalog
# Responsibility: Store and retrieve products
# Does NOT know about specific products (see ProductLoader for data loading)
class ProductCatalog
  class ProductNotFoundError < StandardError; end

  def initialize
    @products = {}
  end

  # Add a product to the catalog
  # @param product [Product] the product to add
  def add_product(product)
    @products[product.code] = product
  end

  # Find a product by code
  # @param code [String] the product code
  # @return [Product] the product
  # @raise [ProductNotFoundError] if product not found
  def find(code)
    @products[code] || raise(ProductNotFoundError, "Product '#{code}' not found")
  end

  # Get all products
  # @return [Array<Product>] all products in catalog
  def all
    @products.values
  end

  # Check if product exists
  # @param code [String] the product code
  # @return [Boolean] true if product exists
  def exists?(code)
    @products.key?(code)
  end

  # Get number of products in catalog
  # @return [Integer] count of products
  def count
    @products.size
  end
end
