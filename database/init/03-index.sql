-- ================================================
-- LTI (Ledger-To-Invest) App Database Index Schema
-- PostgreSQL Implementation
-- ================================================
--
-- ================================================
-- INDEXES FOR VALIDATION FUNCTIONS PERFORMANCE
-- ================================================
CREATE INDEX IF NOT EXISTS idx_account_types_id_can_invest
  ON account_types(id)
  WHERE can_invest = FALSE;

CREATE INDEX IF NOT EXISTS idx_account_types_id_off_budget
  ON account_types(id)
  WHERE on_budget_account = FALSE;

CREATE INDEX IF NOT EXISTS idx_account_types_id_on_budget
  ON account_types(id)
  WHERE on_budget_account = TRUE;

CREATE INDEX IF NOT EXISTS idx_accounts_account_type_id_id_is_asset_account
  ON accounts(account_type_id, id)
  WHERE is_asset_account = TRUE;

CREATE INDEX IF NOT EXISTS idx_accounts_account_type_id_id
  ON accounts(account_type_id, id);

CREATE INDEX IF NOT EXISTS idx_goal_types_id_has_date
  ON goal_types(id)
  WHERE has_date = TRUE;

CREATE INDEX IF NOT EXISTS idx_goals_goal_type_id_category_id_null_goal_month
  ON goals(goal_type_id, category_id)
  WHERE goal_month IS NULL;

CREATE INDEX IF NOT EXISTS idx_categories_category_group_id_id
  ON categories(category_group_id, id);

CREATE INDEX IF NOT EXISTS idx_transactions_account_id_id
  ON transactions(account_id, id);

CREATE INDEX IF NOT EXISTS idx_transactions_account_id_id_cleared
  ON transactions(account_id, id)
  WHERE cleared = TRUE;

CREATE INDEX IF NOT EXISTS idx_category_transactions_category_id_transaction_id
  ON category_transactions(category_id, transaction_id);

CREATE INDEX IF NOT EXISTS idx_payee_transactions_payee_id_transaction_id
  ON payee_transactions(payee_id, transaction_id);

CREATE INDEX IF NOT EXISTS idx_transfers_to_transaction_id_from_transaction_id
  ON transfers(to_transaction_id, from_transaction_id);

CREATE INDEX IF NOT EXISTS idx_asset_transactions_asset_id_transaction_id
  ON asset_transactions(asset_id, transaction_id);

CREATE INDEX IF NOT EXISTS idx_category_budgets_category_id_budget_id
  ON category_budgets(category_id, budget_id);

-- ================================================
-- INDEXES FOR API PERFORMANCE
-- ================================================
CREATE INDEX IF NOT EXISTS idx_ledgers_user_id
  ON ledgers(user_id);

CREATE INDEX IF NOT EXISTS idx_accounts_ledger_id
  ON accounts(ledger_id);

CREATE INDEX IF NOT EXISTS idx_assets_ledger_id
  ON assets(ledger_id);

CREATE INDEX IF NOT EXISTS idx_category_groups_ledger_id
  ON category_groups(ledger_id);

CREATE INDEX IF NOT EXISTS idx_payees_ledger_id
  ON payees(ledger_id);

CREATE INDEX IF NOT EXISTS idx_transactions_account_id_order
  ON transactions(account_id, date, amount, id);

CREATE INDEX IF NOT EXISTS idx_budgets_ledger_id
  ON budgets(ledger_id);