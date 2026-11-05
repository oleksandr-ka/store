# Quick Start

## Installation

```bash
cd task1
bundle install
```

## Verification

```bash
# Run tests (63 examples, ~94% coverage)
bundle exec rspec

# Run requirement examples
bundle exec ruby bin/examples
# Should see 3x ✅ PASS

# Try interactive demo
bundle exec ruby bin/interactive
```

## Basic Usage

```ruby
require_relative 'lib/checkout'

# Load catalog and define rules
catalog = ProductLoader.default
bogof = DiscountRules::BuyOneGetOneFreeRule.new('FR')
bulk = DiscountRules::BulkDiscountRule.new('SR', 3, unit_price: '4.50')

# Create checkout
checkout = Checkout.new(bogof, bulk, catalog: catalog)

# Scan items
checkout.scan('FR').scan('SR').scan('FR')

# Get total
checkout.total  # => BigDecimal('8.11')
# FR x2 with BOGOF = $3.11, SR x1 = $5.00 (no discount, need 3+)

# Or detailed breakdown
checkout.details
# => { total: BigDecimal('8.11'), items: [...] }
```

## Project Structure

```
task1/
├── lib/
│   ├── checkout.rb
│   ├── discount_calculator.rb
│   ├── discount_rules/
│   │   ├── base_rule.rb
│   │   ├── buy_one_get_one_rule.rb
│   │   └── bulk_discount_rule.rb
│   ├── product.rb
│   ├── product_catalog.rb
│   └── product_loader.rb
├── spec/                    # RSpec tests
├── data/products.json       # Product data
└── bin/
    ├── examples             # Requirement examples
    └── interactive          # Interactive demo
```

## Interactive Demo Commands

```
fr, sr, cf, aj   - Scan products
list (l)         - Show products
rules (r)        - Show active rules
cart (c)         - Show cart
total (t)        - Show total
details (d)      - Detailed breakdown
clear            - Clear cart
quit (q)         - Exit
```

## Adding a Discount Rule

Create a class implementing the `DiscountRule` interface:

```ruby
module DiscountRules
  class PercentOff < BaseRule
    def initialize(product_code, min_qty, percent)
      @product_code = product_code
      @min_qty = min_qty
      @discount = BigDecimal(percent.to_s) / 100
    end

    def applicable?(code, quantity)
      code == @product_code && quantity >= @min_qty
    end

    def apply(code, quantity, unit_price)
      return quantity * unit_price unless applicable?(code, quantity)
      quantity * unit_price * (1 - @discount)
    end

    def description
      "#{@product_code}: #{@min_qty}+ items, #{(@discount * 100).to_i}% off"
    end
  end
end

# Use it
rule = DiscountRules::PercentOff.new('CF', 2, '10')
checkout = Checkout.new(bogof, bulk, rule, catalog: catalog)
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for details.
