-- ================================================
-- LTI (Ledger-To-Invest) App Database Index Schema
-- PostgreSQL Implementation
-- ================================================
--
-- ================================================
-- INDEXES FOR PERFORMANCE
-- ================================================
-- Ledger indexes
CREATE INDEX IF NOT EXISTS idx_ledgers_user_id ON ledgers(user_id);

CREATE INDEX IF NOT EXISTS idx_accounts_ledger_id ON accounts(ledger_id);

CREATE INDEX IF NOT EXISTS idx_assets_ledger_id ON assets(ledger_id);

CREATE INDEX IF NOT EXISTS idx_category_groups_ledger_id ON category_groups(ledger_id);

CREATE INDEX IF NOT EXISTS idx_categories_category_group_id ON categories(category_group_id);

CREATE INDEX IF NOT EXISTS idx_payees_ledger_id ON payees(ledger_id);

-- Transaction indexes
CREATE INDEX IF NOT EXISTS idx_transactions_account_id_cleared_date ON transactions(account_id, cleared, date);

CREATE INDEX IF NOT EXISTS idx_category_transactions_category_id ON category_transactions(category_id);

CREATE INDEX IF NOT EXISTS idx_payee_transactions_payee_id ON payee_transactions(payee_id);

CREATE INDEX IF NOT EXISTS idx_asset_transactions_asset_id ON asset_transactions(asset_id);

-- Budget indexes
CREATE INDEX IF NOT EXISTS idx_budgets_ledger_id ON budgets(ledger_id);

CREATE INDEX IF NOT EXISTS idx_category_budgets_category_id ON category_budgets(category_id);

-- ================================================
-- INDEXES FOR TRIGGERS
-- ================================================
CREATE INDEX IF NOT EXISTS idx_account_types_id_can_invest_false ON account_types(id)
  WHERE can_invest = FALSE;

CREATE INDEX IF NOT EXISTS idx_accounts_account_type_id_is_asset_account_true ON accounts(account_type_id)
  WHERE is_asset_account = TRUE;

CREATE INDEX IF NOT EXISTS idx_goal_types_id_has_date_true ON goal_types(id)
  WHERE has_date = TRUE;

CREATE INDEX IF NOT EXISTS idx_goals_goal_type_id_goal_month_null ON goals(goal_type_id)
  WHERE goal_month IS NULL;