# Backend Rewards Redemption

A Rails 8 API service for managing a points-based rewards system. It supports users, products, purchases, payments, and redemptions, and broadcasts real-time updates via Action Cable. Stripe payment initiation and webhook handling endpoints are included for integration.

## Features

- Users with points balances and VIP grades
- Products with inventories and redeemable prices (in cents)
- Purchases and Payments with discount math and totals (in cents)
- Redemptions using points with VIP-based discounts
- Real-time updates via Action Cable broadcast channels
- Stripe payment initiation endpoint and webhook receiver
- JSON-only API with standard RESTful resources

## Tech Stack

- Ruby 3.2.2, Rails 8
- SQLite3 (development, test)
- Action Cable (async in dev, Solid Cable in prod)
- Solid Cache / Solid Queue / Solid Cable
- RSpec, FactoryBot, Faker
- RuboCop (omakase rules), Brakeman
- Docker image for production; Kamal deploy-ready; Thruster app runner

## Getting Started

### Prerequisites

- Ruby 3.2.2 (see `.ruby-version`)
- Bundler
- SQLite 3

Optional for integrations:
- Stripe API key and webhook secret if testing Stripe flow

### Setup

```bash
# Install gems
bundle install

# Setup database (creates and migrates)
bin/rails db:prepare

# Optional: seed sample data (users, products, payments, purchases)
bin/rails db:seed

# Run the server (http://localhost:3000)
bin/rails server
```

Action Cable WebSocket URL: `ws://localhost:3000/cable`

### Environment Variables (optional)

Create a `.env` file if needed for local development (loaded via `dotenv-rails`):

```env
# Stripe
STRIPE_API_KEY=sk_test_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
```

The app can run without these if you are not exercising Stripe-related endpoints.


### Real-time Broadcast Channels

The app broadcasts to these Action Cable streams (subscribe via WebSocket):

- `product_{product.id}` — product inventory/price updates
- `user_{user.id}` — user updates (e.g., point balance)
- `redemption_user_{user.id}` — new redemption events for a user

## Data & Money Fields

- Money values are stored as integer cents, e.g. `redeem_price`, `*_cents` fields.
- Helpers like `Product#redeem_price_dollar` and `User#point_balance_dollar` expose decimal values.

## Development

### Run Tests

```bash
bundle exec rspec
```

### Lint & Security

```bash
# RuboCop style checks
bin/rubocop

# Brakeman security scan
bin/brakeman --no-pager
```

### Seeding Data

The seeds create users, products, and a sample set of payments and purchases using Faker.

```bash
bin/rails db:seed
```

## Docker (Production Image)

Build and run (requires `RAILS_MASTER_KEY`):

```bash
docker build -t backend_rewards_redemption .
docker run -d -p 80:80 \
  -e RAILS_MASTER_KEY=<value from config/master.key> \
  --name backend_rewards_redemption backend_rewards_redemption
```

The Dockerfile is optimized for production (multi-stage build, non-root user). For local dev, run Rails directly as shown above.

## Continuous Integration

GitHub Actions workflow runs:
- Security scan (Brakeman)
- Lint (RuboCop)
- Tests (RSpec)

See `.github/workflows/ci.yml`.

## Deployment

