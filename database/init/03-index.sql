-- ================================================
-- LTI (Ledger-To-Invest) App Database Index Schema
-- PostgreSQL Implementation
-- ================================================
--
-- ================================================
-- INDEXES FOR PERFORMANCE
-- ================================================
-- Currency exchange rate indexes
CREATE INDEX IF NOT EXISTS idx_currencies_code ON currencies (code);

-- User and Budget indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);

CREATE INDEX IF NOT EXISTS idx_users_username ON users (username);

CREATE INDEX IF NOT EXISTS idx_ledgers_user_id_tag ON ledgers (user_id, tag);

-- Account indexes
CREATE INDEX IF NOT EXISTS idx_accounts_ledger_id_tag ON accounts (ledger_id, tag);

CREATE INDEX IF NOT EXISTS idx_accounts_ledger_id_type ON accounts (ledger_id, account_type_id);

CREATE INDEX IF NOT EXISTS idx_accounts_ledger_id_investment ON accounts (ledger_id, is_asset_account)
WHERE
    is_asset_account = TRUE;

-- Asset and pricing indexes
CREATE INDEX IF NOT EXISTS idx_assets_ledger_id_tag ON assets (ledger_id, tag);

CREATE INDEX IF NOT EXISTS idx_assets_ledger_id_symbol ON assets (ledger_id, symbol);

-- Category and payee indexes
CREATE INDEX IF NOT EXISTS idx_category_groups_ledger_id_tag ON category_groups (ledger_id, tag);

CREATE INDEX IF NOT EXISTS idx_categories_group_id_tag ON categories (category_group_id, tag);

CREATE INDEX IF NOT EXISTS idx_payees_ledger_id_tag ON payees (ledger_id, tag);

-- Transaction indexes
CREATE INDEX IF NOT EXISTS idx_transactions_account_date ON transactions (account_id, date);

CREATE INDEX IF NOT EXISTS idx_transactions_account_cleared_date ON transactions (account_id, cleared, date);

CREATE INDEX IF NOT EXISTS idx_payee_transactions_account_payee_date ON payee_transactions (payee_id);

CREATE INDEX IF NOT EXISTS idx_category_transactions_account_category_date ON category_transactions (category_id);

-- Asset transaction indexes
CREATE INDEX IF NOT EXISTS idx_asset_transactions_asset_id ON asset_transactions (asset_id);

-- Budget tracking indexes
CREATE INDEX IF NOT EXISTS idx_budgets_budget_month ON budgets (ledger_id, budget_month);

-- ================================================
-- INDEXES FOR TRIGGERS
-- ================================================