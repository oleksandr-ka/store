# Architecture

## Design Overview

The system uses the **Strategy Pattern** for discount rules with dependency injection for the product catalog.

### Core Structure

```
Checkout → DiscountCalculator → [Rule, Rule, ...]
              ↓
         ProductCatalog ← ProductLoader
```

### Key Classes

- **Checkout** - Main interface (`scan`, `total`, `details`)
- **DiscountCalculator** - Groups items, applies rules, calculates totals
- **DiscountRules::BaseRule** - Abstract base for discount strategies
  - `applicable?(code, quantity)` - Check if rule applies
  - `apply(code, quantity, unit_price)` - Return final price for this product group
  - `description` - Human-readable description
  - Note: Inheritance from BaseRule is not required; any object implementing this interface works
- **ProductCatalog** - Product repository (lookup by code)
- **ProductLoader** - Factory for loading products from JSON/array/etc

## Design Decisions

### Strategy Pattern

Rules are independent objects passed to checkout at construction. This allows:
- Adding new rules without modifying existing code (Open/Closed Principle)
- Testing each rule in isolation
- Different checkouts with different rule sets
- Runtime rule composition

**Alternative considered:** Hardcoded rules in calculator. Simpler but requires code changes for new rules.

### Dependency Injection

Catalog is explicitly passed to checkout:
```ruby
catalog = ProductLoader.default
rules = [bogof_rule, bulk_rule]
checkout = Checkout.new(*rules, catalog: catalog)  # Note: *rules unpacks array
```

Benefits:
- **Single Responsibility**: Checkout doesn't choose or load catalog — that's not its job
- Tests can inject mock catalogs
- Different catalogs for dev/test/prod
- Clear dependencies (explicit, not hidden)

**Alternative considered:** `catalog: nil` with fallback to `ProductLoader.default`. Violates SRP (checkout becomes responsible for catalog selection) and hides dependency.

### Data-Driven Products

Products defined in `data/products.json`, loaded by `ProductLoader`.

Benefits:
- Add products without code changes
- Different catalogs per environment
- Easy testing with `ProductLoader.from_array(...)`

**Alternative considered:** Hardcoded products in `ProductCatalog.default`. Violates Single Responsibility (catalog both manages and defines products).

### Money Representation

All prices use `BigDecimal` for exact decimal arithmetic. Float has precision errors (`0.1 + 0.2 ≠ 0.3`).

## Design Contract Details

### Why Rules Operate on Product Groups

Each rule receives **one product group** (code, quantity, unit_price) and returns the **final line amount**:

```ruby
def apply(product_code, quantity, unit_price)
  # Returns BigDecimal - final amount for this entire product group
end
```

**Benefits of this design:**
- **Single rounding policy**: Calculator rounds each line once, keeps total consistent with receipt
- **Unified interface**: Same contract handles both "free item" (BOGOF) and "fixed price" (bulk discount)
- **Simple composition**: Calculator can apply any rule to any product group without special cases

**Trade-off:**
- **No cross-product visibility**: Rule cannot see other products in basket
- **Cannot self-allocate**: For basket-wide discount, rule cannot decide how to split discount across receipt lines

This explains why Strategy Pattern fits: each rule is truly independent, operating only on its assigned product group.

### Rule Priority: "First Match Wins"

When multiple rules apply to the same product, **constructor order determines priority**:

**Conceptual illustration** (simplified class names for clarity):

```ruby
# Hypothetical scenario: Two overlapping rules for strawberries
# bulk_450: targets $4.50 per item at 3+
# percent_20: 20% off (= $4.00 per item when base price is $5.00)

# Order 1: Bulk rule checked first → applies → $13.50
checkout1 = Checkout.new(bulk_450, percent_20, catalog: catalog)
checkout1.scan('SR').scan('SR').scan('SR')
checkout1.total  # => $13.50 (3 × $4.50)

# Order 2: Percent rule checked first → applies → $12.00
checkout2 = Checkout.new(percent_20, bulk_450, catalog: catalog)
checkout2.scan('SR').scan('SR').scan('SR')
checkout2.total  # => $12.00 (3 × $4.00)

# Result: Same rules, different order → different prices
```

**In production:** Constructor order becomes business policy. This is explicit rather than automatic "best price" selection, because:
- Some businesses want specific rule priority (e.g., member discount before general sale)
- "Best price" is a separate business decision requiring its own implementation
- Explicit ordering is predictable and testable

See `DiscountCalculator#lines` (line 27): `@rules.find { |r| r.applicable? }` stops at first match.

## Current Limitations

### Rule Conflicts

As described above, first applicable rule wins (constructor order = priority policy). Current requirements have non-overlapping rules (BOGOF for FR, bulk for SR), so this is not an issue. If overlapping rules are needed:
- **Priority system**: Assign numeric priority to each rule, evaluate highest first
- **"Best price" policy**: Try all applicable rules, select lowest final amount
- **Stackable rules**: Define composition policy (which rules can combine, in what order)

### Cross-Product Rules

Current rules operate on single product groups. Bundle offers ("buy tea + coffee together") would require basket-level rules.

### Performance

`O(N + U × R)` per calculation where N = scans, U = unique products, R = rules.  
Space: `O(N)` to store scan order. Could optimize to `O(U)` counts, but loses order.

## Extension Points

### Add New Rule

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
      "#{@product_code}: #{@min_qty}+ items, #{@discount * 100}% off"
    end
  end
end

# Use it
new_rule = DiscountRules::PercentOff.new('CF', 2, '10')
checkout = Checkout.new(bogof, bulk, new_rule, catalog: catalog)
```

No changes to existing code required.

### Add Product Source

```ruby
class ProductLoader
  def self.from_database(connection)
    catalog = ProductCatalog.new
    connection.execute("SELECT * FROM products").each do |row|
      catalog.add_product(Product.new(
        code: row['code'],
        name: row['name'],
        price: BigDecimal(row['price'])
      ))
    end
    catalog
  end
end
```

## Strawberry Offer Semantics

The requirement states "Buy 3+, pay $4.50 each". Implementation uses $4.50 as a price ceiling (cap):

```ruby
effective_price = [unit_price, target_price].min
```

The `min` operation sets an **upper bound** (ceiling), not a floor:
- If catalog price rises to $6, customer pays maximum $4.50 (ceiling protects customer)
- If catalog price drops to $4, customer pays $4 (doesn't artificially increase to $4.50)

This "price ceiling" approach ensures customers always get the better price.
