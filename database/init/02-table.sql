-- ================================================
-- LTI (Ledger-To-Invest) App Database Table Schema
-- PostgreSQL Implementation
-- ================================================
--
-- ================================================
-- USER MANAGEMENT
-- ================================================
CREATE TABLE IF NOT EXISTS date_formats(
  id serial PRIMARY KEY,
  tag varchar(50) UNIQUE NOT NULL,
  detail text NOT NULL,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS currencies(
  id serial PRIMARY KEY,
  code varchar(3) UNIQUE NOT NULL,
  detail text NOT NULL,
  symbol varchar(3) NOT NULL,
  on_left boolean NOT NULL,
  breaking_space boolean NOT NULL,
  fractional_separator varchar(1) NOT NULL,
  thousand_separator varchar(1) NOT NULL,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS currency_exchange_rates(
  from_currency_id integer NOT NULL,
  to_currency_id integer NOT NULL,
  date date NOT NULL,
  rate numeric(18, 6) NOT NULL,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (from_currency_id, to_currency_id, date),
  FOREIGN KEY (from_currency_id) REFERENCES currencies(id),
  FOREIGN KEY (to_currency_id) REFERENCES currencies(id),
  CONSTRAINT check_different_currencies CHECK (from_currency_id <> to_currency_id)
);

CREATE TABLE IF NOT EXISTS users(
  id serial PRIMARY KEY,
  username varchar(255) UNIQUE NOT NULL,
  password_hash text NOT NULL,
  first_name varchar(255) NOT NULL,
  last_name varchar(255) NOT NULL,
  email varchar(255) UNIQUE NOT NULL,
  email_active boolean NOT NULL DEFAULT FALSE,
  is_active boolean NOT NULL DEFAULT TRUE,
  has_privileges boolean NOT NULL DEFAULT FALSE,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ================================================
-- LEDGER STRUCTURE
-- ================================================
CREATE TABLE IF NOT EXISTS ledgers(
  id serial PRIMARY KEY,
  user_id integer NOT NULL,
  tag varchar(255) NOT NULL,
  date_format_id integer NOT NULL,
  currency_id integer NOT NULL,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (date_format_id) REFERENCES date_formats(id),
  FOREIGN KEY (currency_id) REFERENCES currencies(id),
  UNIQUE (user_id, tag)
);

-- ================================================
-- ACCOUNT MANAGEMENT
-- ================================================
CREATE TABLE IF NOT EXISTS account_types(
  id serial PRIMARY KEY,
  tag varchar(50) UNIQUE NOT NULL,
  detail text NOT NULL,
  on_budget_account boolean NOT NULL DEFAULT TRUE,
  can_invest boolean NOT NULL DEFAULT FALSE,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT check_can_invest CHECK (NOT (can_invest AND on_budget_account))
);

CREATE TABLE IF NOT EXISTS accounts(
  id serial PRIMARY KEY,
  ledger_id integer NOT NULL,
  tag varchar(50) NOT NULL,
  account_type_id integer NOT NULL,
  currency_id integer NOT NULL,
  is_asset_account boolean NOT NULL DEFAULT FALSE,
  is_closed boolean NOT NULL DEFAULT FALSE,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (ledger_id) REFERENCES ledgers(id) ON DELETE CASCADE,
  FOREIGN KEY (account_type_id) REFERENCES account_types(id),
  FOREIGN KEY (currency_id) REFERENCES currencies(id),
  UNIQUE (ledger_id, tag)
);

-- ================================================
-- INVESTMENT TRACKING
-- ================================================
CREATE TABLE IF NOT EXISTS asset_types(
  id serial PRIMARY KEY,
  tag varchar(50) UNIQUE NOT NULL,
  detail text NOT NULL,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS assets(
  id serial PRIMARY KEY,
  ledger_id integer NOT NULL,
  symbol varchar(20) NOT NULL,
  tag varchar(255) NOT NULL,
  asset_type_id integer NOT NULL,
  currency_id integer NOT NULL,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (ledger_id) REFERENCES ledgers(id) ON DELETE CASCADE,
  FOREIGN KEY (asset_type_id) REFERENCES asset_types(id),
  FOREIGN KEY (currency_id) REFERENCES currencies(id),
  UNIQUE (ledger_id, symbol),
  UNIQUE (ledger_id, tag)
);

CREATE TABLE IF NOT EXISTS asset_prices(
  asset_id integer NOT NULL,
  date date NOT NULL,
  price numeric(18, 6) NOT NULL,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (asset_id, date),
  FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE
);

-- ================================================
-- CATEGORY MANAGEMENT
-- ================================================
CREATE TABLE IF NOT EXISTS category_groups(
  id serial PRIMARY KEY,
  ledger_id integer NOT NULL,
  tag varchar(255) NOT NULL,
  sort_order integer NOT NULL,
  is_system boolean NOT NULL DEFAULT FALSE,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (ledger_id) REFERENCES ledgers(id) ON DELETE CASCADE,
  UNIQUE (ledger_id, tag),
  UNIQUE (ledger_id, sort_order)
);

CREATE TABLE IF NOT EXISTS categories(
  id serial PRIMARY KEY,
  category_group_id integer NOT NULL,
  tag varchar(255) NOT NULL,
  sort_order integer NOT NULL,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (category_group_id) REFERENCES category_groups(id) ON DELETE CASCADE,
  UNIQUE (category_group_id, tag),
  UNIQUE (category_group_id, sort_order)
);

-- ================================================
-- GOALS
-- ================================================
CREATE TABLE IF NOT EXISTS goal_types(
  id serial PRIMARY KEY,
  tag varchar(50) UNIQUE NOT NULL,
  detail text NOT NULL,
  has_date boolean NOT NULL,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS goals(
  category_id integer PRIMARY KEY,
  goal_type_id integer NOT NULL,
  goal_amount numeric(18, 2) NOT NULL,
  goal_month date,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE,
  FOREIGN KEY (goal_type_id) REFERENCES goal_types(id),
  CONSTRAINT check_goal_date_first_of_month CHECK (goal_month IS NULL OR EXTRACT(DAY FROM goal_month) = 1),
  CONSTRAINT check_goal_amount_positive CHECK (goal_amount > 0)
);

-- ================================================
-- PAYEES
-- ================================================
CREATE TABLE IF NOT EXISTS payees(
  id serial PRIMARY KEY,
  ledger_id integer NOT NULL,
  tag varchar(255) NOT NULL,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (ledger_id) REFERENCES ledgers(id) ON DELETE CASCADE,
  UNIQUE (ledger_id, tag)
);

-- ================================================
-- TRANSACTIONS
-- ================================================
CREATE TABLE IF NOT EXISTS transactions(
  id serial PRIMARY KEY,
  account_id integer NOT NULL,
  date date NOT NULL,
  amount numeric(18, 2) NOT NULL,
  memo text,
  cleared boolean NOT NULL DEFAULT FALSE,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE,
  CONSTRAINT check_transactions_amount_zero CHECK (amount <> 0)
);

CREATE TABLE IF NOT EXISTS payee_transactions(
  transaction_id integer PRIMARY KEY,
  payee_id integer NOT NULL,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE,
  FOREIGN KEY (payee_id) REFERENCES payees(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS category_transactions(
  transaction_id integer NOT NULL,
  category_id integer NOT NULL,
  amount numeric(18, 2) NOT NULL,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (transaction_id, category_id),
  FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE,
  FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE,
  CONSTRAINT check_category_transactions_amount_zero CHECK (amount <> 0)
);

-- ================================================
-- TRANSFERS
-- ================================================
CREATE TABLE IF NOT EXISTS transfers(
  from_transaction_id integer UNIQUE NOT NULL,
  to_transaction_id integer UNIQUE NOT NULL,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (from_transaction_id, to_transaction_id),
  FOREIGN KEY (from_transaction_id) REFERENCES transactions(id) ON DELETE CASCADE,
  FOREIGN KEY (to_transaction_id) REFERENCES transactions(id) ON DELETE CASCADE,
  CONSTRAINT check_different_transactions CHECK (from_transaction_id <> to_transaction_id)
);

-- ================================================
-- ASSET TRANSACTIONS
-- ================================================
CREATE TABLE IF NOT EXISTS asset_transactions(
  transaction_id integer NOT NULL,
  asset_id integer NOT NULL,
  quantity numeric(18, 8) NOT NULL,
  price_per_unit numeric(18, 6) NOT NULL,
  exchange_rate numeric(18, 6) NOT NULL DEFAULT 1,
  fee numeric(18, 2) NOT NULL DEFAULT 0,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (transaction_id, asset_id),
  FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE,
  FOREIGN KEY (asset_id) REFERENCES assets(id)
);

-- ================================================
-- BUDGET TRACKING
-- ================================================
CREATE TABLE IF NOT EXISTS budgets(
  id serial PRIMARY KEY,
  ledger_id integer NOT NULL,
  budget_month date NOT NULL,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (ledger_id) REFERENCES ledgers(id) ON DELETE CASCADE,
  UNIQUE (ledger_id, budget_month),
  CONSTRAINT check_month_first_day CHECK (EXTRACT(DAY FROM budget_month) = 1)
);

CREATE TABLE IF NOT EXISTS category_budgets(
  budget_id integer NOT NULL,
  category_id integer NOT NULL,
  budgeted_amount numeric(19, 2) NOT NULL DEFAULT 0,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (budget_id, category_id),
  FOREIGN KEY (budget_id) REFERENCES budgets(id) ON DELETE CASCADE,
  FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
);

