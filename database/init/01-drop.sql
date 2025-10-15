-- ===============================================
-- LTI (Ledger-To-Invest) App Drop Database Schema
-- PostgreSQL Implementation
-- ===============================================
DROP TABLE IF EXISTS category_budgets;

DROP TABLE IF EXISTS budgets;

DROP TABLE IF EXISTS asset_transactions;

DROP TABLE IF EXISTS transfers;

DROP TABLE IF EXISTS category_transactions;

DROP TABLE IF EXISTS payee_transactions;

DROP TABLE IF EXISTS transactions;

DROP TABLE IF EXISTS payees;

DROP TABLE IF EXISTS goals;

DROP TABLE IF EXISTS goal_types;

DROP TABLE IF EXISTS categories;

DROP TABLE IF EXISTS category_groups;

DROP TABLE IF EXISTS asset_prices;

DROP TABLE IF EXISTS assets;

DROP TABLE IF EXISTS asset_types;

DROP TABLE IF EXISTS accounts;

DROP TABLE IF EXISTS account_types;

DROP TABLE IF EXISTS ledgers;

DROP TABLE IF EXISTS users;

DROP TABLE IF EXISTS currency_exchange_rates;

DROP TABLE IF EXISTS currencies;

DROP TABLE IF EXISTS date_formats;

DROP FUNCTION IF EXISTS check_category_budgets_ledger;

DROP FUNCTION IF EXISTS check_transactions_cleared;

DROP FUNCTION IF EXISTS check_asset_transactions_ledger;

DROP FUNCTION IF EXISTS check_asset_transactions_amount;

DROP FUNCTION IF EXISTS check_asset_transactions_account_asset;

DROP FUNCTION IF EXISTS check_transfers_asset_transaction;

DROP FUNCTION IF EXISTS check_transfers_ledger;

DROP FUNCTION IF EXISTS check_transfers_category;

DROP FUNCTION IF EXISTS check_transfers_amounts;

DROP FUNCTION IF EXISTS check_transfers_between_accounts;

DROP FUNCTION IF EXISTS check_transfers_without_payee;

DROP FUNCTION IF EXISTS check_payee_transactions_ledger;

DROP FUNCTION IF EXISTS check_category_transactions_ledger;

DROP FUNCTION IF EXISTS check_category_transactions_amount;

DROP FUNCTION IF EXISTS check_category_transactions_on_budget_account;

DROP FUNCTION IF EXISTS check_goal_month_goal_type_has_date;

DROP FUNCTION IF EXISTS check_account_asset_account_type_can_invest;

DROP FUNCTION IF EXISTS update_updated_at_column;

