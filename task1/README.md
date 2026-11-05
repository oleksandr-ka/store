# Grocery Checkout

A Ruby checkout that accepts product codes and applies discounts independently to each product group.

| Code | Product | Unit price | Offer |
| --- | --- | ---: | --- |
| FR | Fruit Tea | $3.11 | Buy one, get one free for each pair |
| SR | Strawberries | $5.00 | Buy 3 or more and pay $4.50 each, or the catalog price if it is lower |
| CF | Coffee | $11.23 | — |
| AJ | Apple Juice | $7.25 | — |

## Architecture

The main extension point is a pricing strategy for one product group. `Checkout` receives rule objects at construction, and `DiscountCalculator` selects and applies them. A new offer that depends on one product's quantity and price fits the existing interface.

1. `Checkout#scan` validates the product code against the catalog and stores an immutable copy of the code.
2. For `total` or `details`, the calculator groups the scans by product code and looks up each unit price.
3. For each group, the first applicable rule in constructor order supplies the final line amount. A group with no applicable rule uses its catalog price times its quantity. Both offers can apply to the same checkout because they price different groups.
4. The calculator rounds the line amounts and sums them. Both public methods use the same pricing logic.

The checkout keeps scans in order. Each calculation takes up to `O(N + U × R)` for the built-in rules, where `N` is the number of scans, `U` is the number of distinct products, and `R` is the number of rules. Storing counts directly would avoid regrouping and reduce cart storage to `O(U)`, at the cost of losing scan order.

### Strawberry offer semantics

The brief sets a target unit price of $4.50 at three or more units. If the catalog price rises from $5.00 to $6.00, a fixed $0.50 discount would produce $5.50 per unit. The implemented offer still charges $4.50. When the catalog price is already below $4.50, the rule keeps that lower price so the offer cannot increase the charge.

### Alternatives and trade-offs

| Approach | Benefit | Cost and fit |
| --- | --- | --- |
| Put both offers directly in the calculator | Small implementation with a single place to read the pricing logic | Each new offer changes the calculator. This would be reasonable for a fixed set of offers. |
| Pass rule objects to the checkout (current design) | The caller chooses the active offers, and each rule can be tested independently | The calculator needs a rule contract and a policy for overlaps. The current contract is limited to one product group at a time. |
| Chain pricing decorators | Each step can transform the result of the previous one, which fits sequential discounts | The chain needs explicit ordering and composition rules. The two offers in the brief operate independently on different products. |
| Configure offers as data | Marketing could change supported parameters, such as thresholds and prices, without editing Ruby | A registry and validation layer would be needed. New kinds of offers would still require code. |
| Evaluate rules against the whole basket | Supports bundles, spend thresholds, and discounts across products | The checkout must define how offers share items, stack, and affect the receipt. The current requirements do not call for those policies. |

### Catalog and money

- **Catalog injection.** Requiring `catalog:` adds one argument at the call site and keeps catalog loading outside the checkout. Tests can supply a small catalog in memory. `ProductLoader` reads and validates the bundled [JSON catalog](data/products.json), and `ProductCatalog` provides lookup by code. The demo and examples assemble offers in Ruby. A convenience factory could provide the standard catalog if callers frequently need the same setup.
- **Money representation.** Integer cents would work for all prices and offers in the task. The percentage example can produce fractions of a cent, so it still needs a rounding policy. `BigDecimal` lets rules express decimal rates directly and leaves rounding to the calculator. Each product line is rounded half up to cents, then the rounded final amounts are summed. This keeps the total consistent with the receipt.

### When the design would change

- **Two offers apply to the same product.** Today, constructor order determines which rule wins. If the business requires the best price, the calculator could evaluate all applicable rules for that group and select the lowest final amount. Stacking would require a separate policy about which offers can combine and in what order.
- **An offer depends on multiple products.** For an offer such as “buy tea and coffee together,” a basket-level rule could receive all product quantities and prices. Its result would also need to say which receipt lines receive the discount. That requirement would justify changing the current rule contract.

## Run locally

Use Ruby 3.3 or newer and Bundler. The lockfile was generated with Ruby 3.3.3 and Bundler 2.5.11. Run these commands from the repository root:

```sh
cd task1
bundle install
bundle exec rspec
bundle exec ruby bin/examples
bundle exec ruby bin/interactive
```

In the interactive demo, enter one product code per line. Entering `FR FR SR SR SR` on separate lines and then entering `details` shows both discounts and a total of **$16.61**. Use `list` to see products, `rules` to see the offers, and `quit` to exit.

## Use the Ruby interface

Run this example from `task1`:

```ruby
require_relative 'lib/checkout'

catalog = ProductLoader.default
tea_offer = DiscountRules::BuyOneGetOneFreeRule.new('FR')
strawberry_offer = DiscountRules::BulkDiscountRule.new('SR', 3, unit_price: '4.50')

checkout = Checkout.new(tea_offer, strawberry_offer, catalog: catalog)
%w[FR SR FR FR CF].each { |code| checkout.scan(code) }

checkout.total   # => BigDecimal('22.45')
checkout.details # => { items: [...], total: BigDecimal('22.45') }
```

`scan` validates the code against the catalog and raises `ProductCatalog::ProductNotFoundError` for unknown products. `details` includes each product, quantity, original and final line amounts, savings, and the selected rule's description. An empty checkout totals zero.

| Scanned items | Expected total |
| --- | ---: |
| FR, SR, FR, FR, CF | $22.45 |
| FR, FR | $3.11 |
| SR, SR, FR, SR | $16.61 |

## Add a discount

Supply a rule that implements `applicable?(code, quantity)`, `apply(code, quantity, unit_price)`, and `description`. The calculator passes a `BigDecimal` unit price. The rule returns the **final amount for the entire product group** as a `BigDecimal`.

For example, add this after the setup above to offer 10% off when buying two or more coffees:

```ruby
class CoffeeDiscount
  def applicable?(code, quantity)
    code == 'CF' && quantity >= 2
  end

  def apply(_code, quantity, unit_price)
    unit_price * quantity * BigDecimal('0.90')
  end

  def description
    'Buy 2 or more coffees and get 10% off'
  end
end

checkout = Checkout.new(tea_offer, strawberry_offer, CoffeeDiscount.new, catalog: catalog)
checkout.scan('CF').scan('CF')
checkout.total # => BigDecimal('20.21')
```

## Verification

The RSpec suite covers the three examples from the brief, the thresholds for both offers, and a checkout where both offers apply. Regression cases also exercise catalog validation, receipt rounding, cart state, and CLI input.

**Test coverage:** 63 examples, 0 failures, ~94% line coverage

---

## Documentation

- **[docs/QUICKSTART.md](docs/QUICKSTART.md)** - Installation, verification, basic usage
- **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** - Design decisions, patterns, extension points
