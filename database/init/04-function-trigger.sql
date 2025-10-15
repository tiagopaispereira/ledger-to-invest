-- ===============================================================
-- LTI (Ledger-To-Invest) App Database Function and Trigger Schema
-- PostgreSQL Implementation
-- ===============================================================
--
-- ===============================================================
-- Function and triggers to update the updated_at timestamp
-- ===============================================================
-- Update function to update the updated_at in every table
CREATE OR REPLACE FUNCTION update_updated_at_column()
  RETURNS TRIGGER
  AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

-- Trigger for date_formats table
CREATE TRIGGER update_date_formats_updated_at
  BEFORE UPDATE
  ON date_formats
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for currencies table
CREATE TRIGGER update_currencies_updated_at
  BEFORE UPDATE
  ON currencies
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for currency_exchange_rates table
CREATE TRIGGER update_currency_exchange_rates_updated_at
  BEFORE UPDATE
  ON currency_exchange_rates
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for users table
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE
  ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for ledgers table
CREATE TRIGGER update_ledgers_updated_at
  BEFORE UPDATE
  ON ledgers
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for account_types table
CREATE TRIGGER update_account_types_updated_at
  BEFORE UPDATE
  ON account_types
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for accounts table
CREATE TRIGGER update_accounts_updated_at
  BEFORE UPDATE
  ON accounts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for asset_types table
CREATE TRIGGER update_asset_types_updated_at
  BEFORE UPDATE
  ON asset_types
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for assets table
CREATE TRIGGER update_assets_updated_at
  BEFORE UPDATE
  ON assets
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for asset_prices table
CREATE TRIGGER update_asset_prices_updated_at
  BEFORE UPDATE
  ON asset_prices
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for category_groups table
CREATE TRIGGER update_category_groups_updated_at
  BEFORE UPDATE
  ON category_groups
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for categories table
CREATE TRIGGER update_categories_updated_at
  BEFORE UPDATE
  ON categories
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for goal_types table
CREATE TRIGGER update_goal_types_updated_at
  BEFORE UPDATE
  ON goal_types
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for goals table
CREATE TRIGGER update_goals_updated_at
  BEFORE UPDATE
  ON goals
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for payees table
CREATE TRIGGER update_payees_updated_at
  BEFORE UPDATE
  ON payees
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for transactions table
CREATE TRIGGER update_transactions_updated_at
  BEFORE UPDATE
  ON transactions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for payee_transactions table
CREATE TRIGGER update_payee_transactions_updated_at
  BEFORE UPDATE
  ON payee_transactions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for category_transactions table
CREATE TRIGGER update_category_transactions_updated_at
  BEFORE UPDATE
  ON category_transactions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for transfers table
CREATE TRIGGER update_transfers_updated_at
  BEFORE UPDATE
  ON transfers
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for asset_transactions table
CREATE TRIGGER update_asset_transactions_updated_at
  BEFORE UPDATE
  ON asset_transactions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for budgets table
CREATE TRIGGER update_budgets_updated_at
  BEFORE UPDATE
  ON budgets
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for category_budgets table
CREATE TRIGGER update_category_budgets_updated_at
  BEFORE UPDATE
  ON category_budgets
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ===============================================================
-- Function and triggers to check if the asset account uses an 
-- account type that does allow investments
-- ===============================================================
-- Trigger function for asset account validation
CREATE OR REPLACE FUNCTION check_account_asset_account_type_can_invest()
  RETURNS TRIGGER
  AS $$
DECLARE
  v_account_id integer;
  v_account_type_id integer;
BEGIN
  CASE
    -- Handle accounts table operations
    WHEN TG_TABLE_NAME = 'accounts'
      AND TG_OP IN ('INSERT', 'UPDATE') THEN
      
      -- Check if account type is not an investment account but is_asset_account = TRUE
      IF NEW.is_asset_account = TRUE
        AND EXISTS (
          SELECT 1
          FROM account_types
          WHERE id = NEW.account_type_id
            AND can_invest = FALSE
        ) THEN

        v_account_id := NEW.id;
        v_account_type_id := NEW.account_type_id;
      END IF;
    
    -- Handle account_types table operations (can_invest change)
    WHEN TG_TABLE_NAME = 'account_types'
      AND TG_OP = 'UPDATE' THEN
      
      -- Check if account type is a non-investment account
      IF NEW.can_invest = FALSE THEN

        -- Find first account with is_asset_account = TRUE for this account type
        SELECT id, account_type_id
        INTO v_account_id, v_account_type_id
        FROM accounts
        WHERE account_type_id = NEW.id
          AND is_asset_account = TRUE
        LIMIT 1;
        
      END IF;
    
    -- Edge case to prevent unexpected behavior
    ELSE
      RAISE EXCEPTION 'Trigger function called inappropriately on table % with operation %', TG_TABLE_NAME, TG_OP;
  END CASE;
  
  -- Raise exception if constraint violation found
  IF v_account_id IS NOT NULL THEN

    RAISE EXCEPTION 'Asset account cannot use account type that does not allow investments'
      USING
        DETAIL = format(
          'Account ID %s cannot be an asset account because account type ID %s has can_invest = FALSE', 
          v_account_id, 
          v_account_type_id
        ),
        ERRCODE = 'check_violation',
        HINT = 'Only account types with can_invest = TRUE can be used for asset accounts';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for INSERT accounts table
CREATE TRIGGER trg_accounts_asset_investment_check_insert
  BEFORE INSERT
  ON accounts
  FOR EACH ROW
  WHEN (NEW.is_asset_account = TRUE)
  EXECUTE FUNCTION check_account_asset_account_type_can_invest();

-- Trigger for UPDATE accounts table
CREATE TRIGGER trg_accounts_asset_investment_check_update
  BEFORE UPDATE OF is_asset_account, account_type_id 
  ON accounts
  FOR EACH ROW
  WHEN (NEW.is_asset_account = TRUE
    AND (OLD.is_asset_account = FALSE OR OLD.account_type_id IS DISTINCT FROM NEW.account_type_id))
  EXECUTE FUNCTION check_account_asset_account_type_can_invest();

-- Trigger for UPDATE account_types table
CREATE TRIGGER trg_account_types_investment_check_update
  BEFORE UPDATE OF can_invest 
  ON account_types
  FOR EACH ROW
  WHEN (OLD.can_invest = TRUE AND NEW.can_invest = FALSE)
  EXECUTE FUNCTION check_account_asset_account_type_can_invest();

-- ===============================================================
-- Function and triggers to check if goal have a target month when
-- using goal type that requires dates
-- ===============================================================
-- Trigger function for goal month validation
CREATE OR REPLACE FUNCTION check_goal_month_goal_type_has_date()
  RETURNS TRIGGER
  AS $$
DECLARE
  v_category_id integer;
  v_goal_type_id integer;
BEGIN
  CASE
    -- Handle goals table operations
    WHEN TG_TABLE_NAME = 'goals'
      AND TG_OP IN ('INSERT', 'UPDATE') THEN
      
      -- Check if goal type requires a date but goal_month is NULL
      IF NEW.goal_month IS NULL
        AND EXISTS (
          SELECT 1
          FROM goal_types
          WHERE id = NEW.goal_type_id
            AND has_date = TRUE
        ) THEN

        v_category_id := NEW.category_id;
        v_goal_type_id := NEW.goal_type_id;
      END IF;
    
    -- Handle goal_types table operations (has_date change)
    WHEN TG_TABLE_NAME = 'goal_types'
      AND TG_OP = 'UPDATE' THEN
      
      -- Check if updated goal type requires a date
      IF NEW.has_date = TRUE THEN

        -- Find first goal with NULL goal_month for this goal type
        SELECT category_id, goal_type_id
        INTO v_category_id, v_goal_type_id
        FROM goals
        WHERE goal_type_id = NEW.id
          AND goal_month IS NULL
        LIMIT 1;
      
      END IF;
    
    -- Edge case to prevent unexpected behavior
    ELSE
      RAISE EXCEPTION 'Trigger function called inappropriately on table % with operation %', TG_TABLE_NAME, TG_OP;
  END CASE;
  
  -- Raise exception if constraint violation found
  IF v_category_id IS NOT NULL THEN

    RAISE EXCEPTION 'Goal must have a target month when using goal type that requires dates'
      USING
        DETAIL = format(
          'Goal for category ID %s must have a goal_month because goal type ID %s has has_date = TRUE', 
          v_category_id, 
          v_goal_type_id
        ),
        ERRCODE = 'check_violation',
        HINT = 'Either set a goal_month or use a goal type with has_date = FALSE';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for INSERT goals table
CREATE TRIGGER trg_goals_month_has_date_check_insert
  BEFORE INSERT
  ON goals
  FOR EACH ROW
  WHEN (NEW.goal_month IS NULL)
  EXECUTE FUNCTION check_goal_month_goal_type_has_date();

-- Trigger for UPDATE goals table
CREATE TRIGGER trg_goals_month_has_date_check_update
  BEFORE UPDATE OF goal_month, goal_type_id 
  ON goals
  FOR EACH ROW
  WHEN (NEW.goal_month IS NULL
    AND (OLD.goal_month IS NOT NULL OR OLD.goal_type_id IS DISTINCT FROM NEW.goal_type_id))
  EXECUTE FUNCTION check_goal_month_goal_type_has_date();

-- Trigger for UPDATE goal_types table
CREATE TRIGGER trg_goal_types_has_date_check_update
  BEFORE UPDATE OF has_date 
  ON goal_types
  FOR EACH ROW
  WHEN (OLD.has_date = FALSE AND NEW.has_date = TRUE)
  EXECUTE FUNCTION check_goal_month_goal_type_has_date();

-- ===============================================================
-- Function and triggers to check categorized transactions only 
-- on budget accounts
-- ===============================================================
-- Trigger function for category transactions validation
CREATE OR REPLACE FUNCTION check_category_transactions_on_budget_account()
  RETURNS TRIGGER
  AS $$
DECLARE
  v_transaction_id integer;
  v_account_id integer;
BEGIN
  CASE
    -- Handle category_transactions table operations
    WHEN TG_TABLE_NAME = 'category_transactions'
      AND TG_OP IN ('INSERT', 'UPDATE') THEN

      -- Check if transaction belongs to off-budget account
      SELECT t.id, t.account_id
      INTO v_transaction_id, v_account_id
      FROM transactions t
      INNER JOIN accounts a ON t.account_id = a.id
      INNER JOIN account_types at ON a.account_type_id = at.id
      WHERE t.id = NEW.transaction_id
        AND at.on_budget_account = FALSE
      LIMIT 1;

    -- Handle transactions table operations (account_id change)
    WHEN TG_TABLE_NAME = 'transactions'
      AND TG_OP = 'UPDATE' THEN

      -- Only check if this transaction has categories AND new account is off-budget
      IF EXISTS (
        SELECT 1
        FROM category_transactions
        WHERE transaction_id = NEW.id
      ) THEN

        IF EXISTS (
          SELECT 1
          FROM accounts a
          INNER JOIN account_types at ON a.account_type_id = at.id
          WHERE a.id = NEW.account_id
            AND at.on_budget_account = FALSE
        ) THEN

          v_transaction_id := NEW.id;
          v_account_id := NEW.account_id;
        END IF;
      END IF;
    
    -- Handle accounts table operations (account_type_id change)
    WHEN TG_TABLE_NAME = 'accounts'
      AND TG_OP = 'UPDATE' THEN

      -- Check if new account type is off-budget
      IF EXISTS (
        SELECT 1
        FROM account_types
        WHERE id = NEW.account_type_id
          AND on_budget_account = FALSE
      ) THEN

        -- Find first categorized transaction in this account
        SELECT t.id
        INTO v_transaction_id
        FROM transactions t
        INNER JOIN category_transactions ct ON t.id = ct.transaction_id
        WHERE t.account_id = NEW.id
        LIMIT 1;

        IF FOUND THEN

          v_account_id := NEW.id;
        END IF;
      END IF;
    
    -- Handle account_types table operations (on_budget_account change)
    WHEN TG_TABLE_NAME = 'account_types'
      AND TG_OP = 'UPDATE' THEN

      -- Check if account type is off-budget
      IF NEW.on_budget_account = FALSE THEN

        -- Find first categorized transaction in accounts of this type
        SELECT t.id, a.id
        INTO v_transaction_id, v_account_id
        FROM account_types at
        INNER JOIN accounts a ON at.id = a.account_type_id
        INNER JOIN transactions t ON a.id = t.account_id
        INNER JOIN category_transactions ct ON t.id = ct.transaction_id
        WHERE at.id = NEW.id
        LIMIT 1;
      END IF;
    
    -- Edge case to prevent unexpected behavior
    ELSE
      RAISE EXCEPTION 'Trigger function called inappropriately on table % with operation %', 
        TG_TABLE_NAME, TG_OP;
  END CASE;

  -- Raise exception if constraint violation found
  IF v_transaction_id IS NOT NULL THEN

    RAISE EXCEPTION 'Categorized transactions only allowed on budget accounts'
      USING
        DETAIL = format(
          'Transaction ID %s cannot be categorized because account ID %s has on_budget_account = FALSE', 
          v_transaction_id, 
          v_account_id
        ),
        ERRCODE = 'check_violation',
        HINT = 'Only transactions on account types with on_budget_account = TRUE can be categorized';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for INSERT category_transactions table
CREATE TRIGGER trg_category_transactions_on_budget_account_check_insert
  BEFORE INSERT
  ON category_transactions
  FOR EACH ROW
  EXECUTE FUNCTION check_category_transactions_on_budget_account();

-- Trigger for UPDATE category_transactions table
CREATE TRIGGER trg_category_transactions_on_budget_account_check_update
  BEFORE UPDATE OF transaction_id
  ON category_transactions
  FOR EACH ROW
  WHEN (OLD.transaction_id IS DISTINCT FROM NEW.transaction_id)
  EXECUTE FUNCTION check_category_transactions_on_budget_account();

-- Trigger for UPDATE transactions table
CREATE TRIGGER trg_transactions_budget_account_check_update
  BEFORE UPDATE OF account_id
  ON transactions
  FOR EACH ROW
  WHEN (OLD.account_id IS DISTINCT FROM NEW.account_id)
  EXECUTE FUNCTION check_category_transactions_on_budget_account();

-- Trigger for UPDATE accounts table
CREATE TRIGGER trg_accounts_budget_type_check_update
  BEFORE UPDATE OF account_type_id
  ON accounts
  FOR EACH ROW
  WHEN (OLD.account_type_id IS DISTINCT FROM NEW.account_type_id)
  EXECUTE FUNCTION check_category_transactions_on_budget_account();

-- Trigger for UPDATE account_types table
CREATE TRIGGER trg_account_types_budget_check_update
  BEFORE UPDATE OF on_budget_account
  ON account_types
  FOR EACH ROW
  WHEN (OLD.on_budget_account = TRUE AND NEW.on_budget_account = FALSE)
  EXECUTE FUNCTION check_category_transactions_on_budget_account();

-- ===============================================================
-- Function and triggers to check category transactions sum match
-- transaction amount
-- ===============================================================
-- Trigger function for category transactions amount validation
CREATE OR REPLACE FUNCTION check_category_transactions_amount()
  RETURNS TRIGGER
  AS $$
DECLARE
  v_transaction_id integer;
  v_transaction_amount numeric(18, 2);
  v_categories_transaction_sum numeric(18, 2);
BEGIN
  CASE
    -- Handle category_transactions table operations
    WHEN TG_TABLE_NAME = 'category_transactions' THEN

      -- Check if sum of categories for the transaction matches new category
      SELECT t.id, t.amount, ct.ct_sum
      INTO v_transaction_id, v_transaction_amount, v_categories_transaction_sum
      FROM (
        SELECT transaction_id, SUM(amount) AS ct_sum
        FROM category_transactions
        WHERE transaction_id IN (NEW.transaction_id, OLD.transaction_id)
        GROUP BY transaction_id
      ) ct
      INNER JOIN transactions t ON ct.transaction_id = t.id
      WHERE t.amount <> ct.ct_sum
      LIMIT 1;

    -- Handle transactions table operations (amount change)
    WHEN TG_TABLE_NAME = 'transactions'
      AND TG_OP = 'UPDATE' THEN

      -- Check if sum of categories for this transaction matches new amount
      SELECT transaction_id, SUM(amount)
      INTO v_transaction_id, v_categories_transaction_sum
      FROM category_transactions
      WHERE transaction_id = NEW.id
      GROUP BY transaction_id
      HAVING SUM(amount) <> NEW.amount
      LIMIT 1;

      IF FOUND THEN

        v_transaction_amount := NEW.amount;
      END IF;
    
    -- Edge case to prevent unexpected behavior
    ELSE
      RAISE EXCEPTION 'Trigger function called inappropriately on table % with operation %', 
        TG_TABLE_NAME, TG_OP;
  END CASE;

  -- Raise exception if constraint violation found
  IF v_transaction_id IS NOT NULL THEN

    RAISE EXCEPTION 'Category transactions sum does not match transaction amount'
      USING
        DETAIL = format(
          'Transaction ID %s has a categorized amount sum of %s not equal to the actual amount %s',
          v_transaction_id, 
          v_categories_transaction_sum,
          v_transaction_amount
        ),
        ERRCODE = 'check_violation',
        HINT = 'Ensure all category transactions for this transaction sum to the transaction amount';
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Constraint trigger for INSERT/DELETE category_transactions table
CREATE CONSTRAINT TRIGGER trg_category_transactions_amount_check_insert_delete
  AFTER INSERT OR DELETE
  ON category_transactions 
  DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  EXECUTE FUNCTION check_category_transactions_amount();

-- Constraint trigger for UPDATE category_transactions table
CREATE CONSTRAINT TRIGGER trg_category_transactions_amount_check_update
  AFTER UPDATE OF transaction_id, amount
  ON category_transactions 
  DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  WHEN (OLD.transaction_id IS DISTINCT FROM NEW.transaction_id
    OR OLD.amount IS DISTINCT FROM NEW.amount)
  EXECUTE FUNCTION check_category_transactions_amount();

-- Trigger for UPDATE transactions table
CREATE TRIGGER trg_transactions_category_amount_check_update
  BEFORE UPDATE OF amount
  ON transactions 
  FOR EACH ROW
  WHEN (OLD.amount IS DISTINCT FROM NEW.amount)
  EXECUTE FUNCTION check_category_transactions_amount();

-- ===============================================================
-- Function and triggers to check categorized transactions ledger
-- consistency
-- ===============================================================
-- Trigger function for category transactions ledger validation
CREATE OR REPLACE FUNCTION check_category_transactions_ledger()
  RETURNS TRIGGER
  AS $$
DECLARE
  v_transaction_id integer;
  v_category_id integer;
BEGIN
  CASE
    -- Handle category_transactions table operations
    WHEN TG_TABLE_NAME = 'category_transactions'
      AND TG_OP IN ('INSERT', 'UPDATE') THEN

      -- Check if transaction and category belong to different ledgers
      IF EXISTS (
        SELECT 1
        FROM transactions t
        INNER JOIN accounts a ON t.account_id = a.id
        INNER JOIN categories c ON c.id = NEW.category_id
        INNER JOIN category_groups cg ON c.category_group_id = cg.id
        WHERE t.id = NEW.transaction_id
          AND a.ledger_id <> cg.ledger_id
      ) THEN
        v_transaction_id := NEW.transaction_id;
        v_category_id := NEW.category_id;
      END IF;

    -- Handle transactions table operations (account_id change)
    WHEN TG_TABLE_NAME = 'transactions'
      AND TG_OP = 'UPDATE' THEN

      -- Find first category_transaction with ledger mismatch
      SELECT ct.transaction_id, ct.category_id
      INTO v_transaction_id, v_category_id
      FROM category_transactions ct
      INNER JOIN categories c ON ct.category_id = c.id
      INNER JOIN category_groups cg ON c.category_group_id = cg.id
      INNER JOIN accounts a ON a.id = NEW.account_id
      WHERE ct.transaction_id = NEW.id
        AND a.ledger_id <> cg.ledger_id
      LIMIT 1;
    
    -- Handle accounts table operations (ledger_id change)
    WHEN TG_TABLE_NAME = 'accounts'
      AND TG_OP = 'UPDATE' THEN

      -- Find first transaction with category from different ledger
      SELECT ct.transaction_id, ct.category_id
      INTO v_transaction_id, v_category_id
      FROM transactions t
      INNER JOIN category_transactions ct ON t.id = ct.transaction_id
      INNER JOIN categories c ON ct.category_id = c.id
      INNER JOIN category_groups cg ON c.category_group_id = cg.id
      WHERE t.account_id = NEW.id
        AND NEW.ledger_id <> cg.ledger_id
      LIMIT 1;
    
    -- Handle categories table operations (category_group_id change)
    WHEN TG_TABLE_NAME = 'categories'
      AND TG_OP = 'UPDATE' THEN

      -- Find first category_transaction with ledger mismatch
      SELECT ct.transaction_id, ct.category_id
      INTO v_transaction_id, v_category_id
      FROM category_transactions ct
      INNER JOIN transactions t ON ct.transaction_id = t.id
      INNER JOIN accounts a ON t.account_id = a.id
      INNER JOIN category_groups cg ON cg.id = NEW.category_group_id
      WHERE ct.category_id = NEW.id
        AND a.ledger_id <> cg.ledger_id
      LIMIT 1;

    -- Handle category_groups table operations (ledger_id change)
    WHEN TG_TABLE_NAME = 'category_groups'
      AND TG_OP = 'UPDATE' THEN

      -- Find first category_transaction with ledger mismatch
      SELECT ct.transaction_id, ct.category_id
      INTO v_transaction_id, v_category_id
      FROM categories c
      INNER JOIN category_transactions ct ON c.id = ct.category_id
      INNER JOIN transactions t ON ct.transaction_id = t.id
      INNER JOIN accounts a ON t.account_id = a.id
      WHERE c.category_group_id = NEW.id
        AND a.ledger_id <> NEW.ledger_id
      LIMIT 1;
    
    -- Edge case to prevent unexpected behavior
    ELSE
      RAISE EXCEPTION 'Trigger function called inappropriately on table % with operation %', 
        TG_TABLE_NAME, TG_OP;
  END CASE;

  -- Raise exception if constraint violation found
  IF v_transaction_id IS NOT NULL THEN

    RAISE EXCEPTION 'Category and transaction must belong to the same ledger'
      USING
        DETAIL = format(
          'Category ID %s and transaction ID %s belong to different ledgers', 
          v_category_id,
          v_transaction_id
        ),
        ERRCODE = 'check_violation',
        HINT = 'Categorized transactions can only use categories from the same ledger as the transaction account';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for INSERT category_transactions table
CREATE TRIGGER trg_category_transactions_ledger_check_insert
  BEFORE INSERT
  ON category_transactions
  FOR EACH ROW
  EXECUTE FUNCTION check_category_transactions_ledger();

-- Trigger for UPDATE category_transactions table
CREATE TRIGGER trg_category_transactions_ledger_check_update
  BEFORE UPDATE OF transaction_id, category_id
  ON category_transactions
  FOR EACH ROW
  WHEN (OLD.transaction_id IS DISTINCT FROM NEW.transaction_id
    OR OLD.category_id IS DISTINCT FROM NEW.category_id)
  EXECUTE FUNCTION check_category_transactions_ledger();

-- Trigger for UPDATE transactions table
CREATE TRIGGER trg_transactions_category_ledger_check_update
  BEFORE UPDATE OF account_id
  ON transactions
  FOR EACH ROW
  WHEN (OLD.account_id IS DISTINCT FROM NEW.account_id)
  EXECUTE FUNCTION check_category_transactions_ledger();

-- Trigger for UPDATE accounts table
CREATE TRIGGER trg_accounts_category_ledger_check_update
  BEFORE UPDATE OF ledger_id
  ON accounts
  FOR EACH ROW
  WHEN (OLD.ledger_id IS DISTINCT FROM NEW.ledger_id)
  EXECUTE FUNCTION check_category_transactions_ledger();

-- Trigger for UPDATE categories table
CREATE TRIGGER trg_categories_ledger_check_update
  BEFORE UPDATE OF category_group_id
  ON categories
  FOR EACH ROW
  WHEN (OLD.category_group_id IS DISTINCT FROM NEW.category_group_id)
  EXECUTE FUNCTION check_category_transactions_ledger();

-- Trigger for UPDATE category_groups table
CREATE TRIGGER trg_category_groups_ledger_check_update
  BEFORE UPDATE OF ledger_id
  ON category_groups
  FOR EACH ROW
  WHEN (OLD.ledger_id IS DISTINCT FROM NEW.ledger_id)
  EXECUTE FUNCTION check_category_transactions_ledger();

-- ===============================================================
-- Function and triggers to check payee transactions ledger
-- consistency
-- ===============================================================
-- Trigger function for payee transactions ledger validation
CREATE OR REPLACE FUNCTION check_payee_transactions_ledger()
  RETURNS TRIGGER
  AS $$
DECLARE
  v_transaction_id integer;
  v_payee_id integer;
BEGIN
  CASE
    -- Handle payee_transactions table operations
    WHEN TG_TABLE_NAME = 'payee_transactions'
      AND TG_OP IN ('INSERT', 'UPDATE') THEN

      -- Check if transaction and payee belong to different ledgers
      IF EXISTS (
        SELECT 1
        FROM transactions t
        INNER JOIN accounts a ON t.account_id = a.id
        INNER JOIN payees p ON p.id = NEW.payee_id
        WHERE t.id = NEW.transaction_id
          AND a.ledger_id <> p.ledger_id
      ) THEN
        v_transaction_id := NEW.transaction_id;
        v_payee_id := NEW.payee_id;
      END IF;

    -- Handle transactions table operations (account_id change)
    WHEN TG_TABLE_NAME = 'transactions'
      AND TG_OP = 'UPDATE' THEN

      -- Find first payee_transaction with ledger mismatch
      SELECT pt.transaction_id, pt.payee_id
      INTO v_transaction_id, v_payee_id
      FROM payee_transactions pt
      INNER JOIN payees p ON pt.payee_id = p.id
      INNER JOIN accounts a ON a.id = NEW.account_id
      WHERE pt.transaction_id = NEW.id
        AND a.ledger_id <> p.ledger_id
      LIMIT 1;
    
    -- Handle accounts table operations (ledger_id change)
    WHEN TG_TABLE_NAME = 'accounts'
      AND TG_OP = 'UPDATE' THEN

      -- Find first transaction with payee from different ledger
      SELECT pt.transaction_id, pt.payee_id
      INTO v_transaction_id, v_payee_id
      FROM transactions t
      INNER JOIN payee_transactions pt ON t.id = pt.transaction_id
      INNER JOIN payees p ON pt.payee_id = p.id
      WHERE t.account_id = NEW.id
        AND NEW.ledger_id <> p.ledger_id
      LIMIT 1;
    
    -- Handle payees table operations (ledger_id change)
    WHEN TG_TABLE_NAME = 'payees'
      AND TG_OP = 'UPDATE' THEN

      -- Find first payee_transaction with ledger mismatch
      SELECT pt.transaction_id, pt.payee_id
      INTO v_transaction_id, v_payee_id
      FROM payee_transactions pt
      INNER JOIN transactions t ON pt.transaction_id = t.id
      INNER JOIN accounts a ON t.account_id = a.id
      WHERE pt.payee_id = NEW.id
        AND a.ledger_id <> NEW.ledger_id
      LIMIT 1;
    
    -- Edge case to prevent unexpected behavior
    ELSE
      RAISE EXCEPTION 'Trigger function called inappropriately on table % with operation %', 
        TG_TABLE_NAME, TG_OP;
  END CASE;

  -- Raise exception if constraint violation found
  IF v_transaction_id IS NOT NULL THEN

    RAISE EXCEPTION 'Payee and transaction must belong to the same ledger'
      USING
        DETAIL = format(
          'Payee ID %s and transaction ID %s belong to different ledgers', 
          v_payee_id,
          v_transaction_id
        ),
        ERRCODE = 'check_violation',
        HINT = 'Payee transactions can only use payees from the same ledger as the transaction account';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for INSERT payee_transactions table
CREATE TRIGGER trg_payee_transactions_ledger_check_insert
  BEFORE INSERT
  ON payee_transactions
  FOR EACH ROW
  EXECUTE FUNCTION check_payee_transactions_ledger();

-- Trigger for UPDATE payee_transactions table
CREATE TRIGGER trg_payee_transactions_ledger_check_update
  BEFORE UPDATE OF transaction_id, payee_id
  ON payee_transactions
  FOR EACH ROW
  WHEN (OLD.transaction_id IS DISTINCT FROM NEW.transaction_id
    OR OLD.payee_id IS DISTINCT FROM NEW.payee_id)
  EXECUTE FUNCTION check_payee_transactions_ledger();

-- Trigger for UPDATE transactions table
CREATE TRIGGER trg_transactions_payee_ledger_check_update
  BEFORE UPDATE OF account_id
  ON transactions
  FOR EACH ROW
  WHEN (OLD.account_id IS DISTINCT FROM NEW.account_id)
  EXECUTE FUNCTION check_payee_transactions_ledger();

-- Trigger for UPDATE accounts table
CREATE TRIGGER trg_accounts_payee_ledger_check_update
  BEFORE UPDATE OF ledger_id
  ON accounts
  FOR EACH ROW
  WHEN (OLD.ledger_id IS DISTINCT FROM NEW.ledger_id)
  EXECUTE FUNCTION check_payee_transactions_ledger();

-- Trigger for UPDATE payees table
CREATE TRIGGER trg_payees_ledger_check_update
  BEFORE UPDATE OF ledger_id
  ON payees
  FOR EACH ROW
  WHEN (OLD.ledger_id IS DISTINCT FROM NEW.ledger_id)
  EXECUTE FUNCTION check_payee_transactions_ledger();

-- ===============================================================
-- Function and triggers to check transfer without payee
-- ===============================================================
-- Trigger function for transfers payee validation
CREATE OR REPLACE FUNCTION check_transfers_without_payee()
  RETURNS TRIGGER
  AS $$
DECLARE
  v_from_transaction_id integer;
  v_to_transaction_id integer;
BEGIN
  CASE
    -- Handle transfers table operations
    WHEN TG_TABLE_NAME = 'transfers'
      AND TG_OP IN ('INSERT', 'UPDATE') THEN

      -- Check if any transaction in this transfer has a payee
      IF EXISTS (
        SELECT 1
        FROM payee_transactions
        WHERE transaction_id IN (NEW.from_transaction_id, NEW.to_transaction_id)
      ) THEN
        v_from_transaction_id := NEW.from_transaction_id;
        v_to_transaction_id := NEW.to_transaction_id;
      END IF;
    
    -- Handle payee_transactions table operations
    WHEN TG_TABLE_NAME = 'payee_transactions'
      AND TG_OP IN ('INSERT', 'UPDATE') THEN

      -- Check if this transaction is part of a transfer
      SELECT from_transaction_id, to_transaction_id
      INTO v_from_transaction_id, v_to_transaction_id
      FROM transfers
      WHERE from_transaction_id = NEW.transaction_id
        OR to_transaction_id = NEW.transaction_id
      LIMIT 1;

    -- Edge case to prevent unexpected behavior
    ELSE
      RAISE EXCEPTION 'Trigger function called inappropriately on table % with operation %', 
        TG_TABLE_NAME, TG_OP;
  END CASE;

  -- Raise exception if constraint violation found
  IF v_from_transaction_id IS NOT NULL THEN

    RAISE EXCEPTION 'Transfer transactions cannot have an associated payee'
      USING
        DETAIL = format(
          'Transfer from transaction ID %s to transaction ID %s has a payee associated', 
          v_from_transaction_id,
          v_to_transaction_id
        ),
        ERRCODE = 'check_violation',
        HINT = 'Transactions in a transfer cannot have a payee';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for INSERT transfers table
CREATE TRIGGER trg_transfers_payee_check_insert
  BEFORE INSERT
  ON transfers
  FOR EACH ROW
  EXECUTE FUNCTION check_transfers_without_payee();

-- Trigger for UPDATE transfers table
CREATE TRIGGER trg_transfers_payee_check_update
  BEFORE UPDATE OF from_transaction_id, to_transaction_id
  ON transfers
  FOR EACH ROW
  WHEN (OLD.from_transaction_id IS DISTINCT FROM NEW.from_transaction_id
    OR OLD.to_transaction_id IS DISTINCT FROM NEW.to_transaction_id)
  EXECUTE FUNCTION check_transfers_without_payee();

-- Trigger for INSERT payee_transactions table
CREATE TRIGGER trg_payee_transactions_transfers_check_insert
  BEFORE INSERT
  ON payee_transactions
  FOR EACH ROW
  EXECUTE FUNCTION check_transfers_without_payee();

-- Trigger for UPDATE payee_transactions table
CREATE TRIGGER trg_payee_transactions_transfers_check_update
  BEFORE UPDATE OF transaction_id
  ON payee_transactions
  FOR EACH ROW
  WHEN (OLD.transaction_id IS DISTINCT FROM NEW.transaction_id)
  EXECUTE FUNCTION check_transfers_without_payee();

-- ===============================================================
-- Function and triggers to check transfer between different
-- accounts
-- ===============================================================
-- Trigger function for transfers different accounts validation
CREATE OR REPLACE FUNCTION check_transfers_between_accounts()
  RETURNS TRIGGER
  AS $$
DECLARE
  v_from_transaction_id integer;
  v_to_transaction_id integer;
BEGIN
  CASE
    -- Handle transfers table operations
    WHEN TG_TABLE_NAME = 'transfers'
      AND TG_OP IN ('INSERT', 'UPDATE') THEN

      -- Check if transfer is between same account
      IF EXISTS (
        SELECT 1
        FROM transactions ft
        INNER JOIN transactions tt ON tt.id = NEW.to_transaction_id
        WHERE ft.id = NEW.from_transaction_id
          AND ft.account_id = tt.account_id
      ) THEN
        v_from_transaction_id := NEW.from_transaction_id;
        v_to_transaction_id := NEW.to_transaction_id;
      END IF;
    
    -- Handle transactions table operations
    WHEN TG_TABLE_NAME = 'transactions'
      AND TG_OP = 'UPDATE' THEN

      -- Check if this transaction is the "from" side of a transfer
      SELECT t.from_transaction_id, t.to_transaction_id
      INTO v_from_transaction_id, v_to_transaction_id
      FROM transfers t
      INNER JOIN transactions tt ON t.to_transaction_id = tt.id
      WHERE t.from_transaction_id = NEW.id
        AND tt.account_id = NEW.account_id
      LIMIT 1;

      -- If not found, check if this transaction is the "to" side
      IF NOT FOUND THEN

        SELECT t.from_transaction_id, t.to_transaction_id
        INTO v_from_transaction_id, v_to_transaction_id
        FROM transfers t
        INNER JOIN transactions ft ON t.from_transaction_id = ft.id
        WHERE t.to_transaction_id = NEW.id
          AND ft.account_id = NEW.account_id
        LIMIT 1;

      END IF;

    -- Edge case to prevent unexpected behavior
    ELSE
      RAISE EXCEPTION 'Trigger function called inappropriately on table % with operation %', 
        TG_TABLE_NAME, TG_OP;
  END CASE;

  -- Raise exception if constraint violation found
  IF v_from_transaction_id IS NOT NULL THEN

    RAISE EXCEPTION 'Transfer transactions must be between different accounts'
      USING
        DETAIL = format(
          'Transfer from transaction ID %s to transaction ID %s involves the same account', 
          v_from_transaction_id,
          v_to_transaction_id
        ),
        ERRCODE = 'check_violation',
        HINT = 'Both transactions in a transfer must belong to different accounts';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for INSERT transfers table
CREATE TRIGGER trg_transfers_account_check_insert
  BEFORE INSERT
  ON transfers
  FOR EACH ROW
  EXECUTE FUNCTION check_transfers_between_accounts();

-- Trigger for UPDATE transfers table
CREATE TRIGGER trg_transfers_account_check_update
  BEFORE UPDATE OF from_transaction_id, to_transaction_id
  ON transfers
  FOR EACH ROW
  WHEN (OLD.from_transaction_id IS DISTINCT FROM NEW.from_transaction_id
    OR OLD.to_transaction_id IS DISTINCT FROM NEW.to_transaction_id)
  EXECUTE FUNCTION check_transfers_between_accounts();

-- Trigger for UPDATE transactions table
CREATE TRIGGER trg_transactions_account_transfer_check_update
  BEFORE UPDATE OF account_id
  ON transactions
  FOR EACH ROW
  WHEN (OLD.account_id IS DISTINCT FROM NEW.account_id)
  EXECUTE FUNCTION check_transfers_between_accounts();

-- ===============================================================
-- Function and triggers to check transfer amounts
-- ===============================================================
-- Trigger function for transfers amounts validation
CREATE OR REPLACE FUNCTION check_transfers_amounts()
  RETURNS TRIGGER
  AS $$
DECLARE
  v_from_transaction_id integer;
  v_to_transaction_id integer;
BEGIN
  CASE
    -- Handle transfers table operations
    WHEN TG_TABLE_NAME = 'transfers'
      AND TG_OP IN ('INSERT', 'UPDATE') THEN

      -- Check if transfer amounts are valid (from negative, to positive, sum to zero)
      IF EXISTS (
        SELECT 1
        FROM transactions ft
        INNER JOIN transactions tt ON tt.id = NEW.to_transaction_id
        WHERE ft.id = NEW.from_transaction_id
          AND (ft.amount + tt.amount <> 0 OR ft.amount > 0 OR tt.amount < 0)
      ) THEN
        v_from_transaction_id := NEW.from_transaction_id;
        v_to_transaction_id := NEW.to_transaction_id;
      END IF;
    
    -- Handle transactions table operations
    WHEN TG_TABLE_NAME = 'transactions'
      AND TG_OP = 'UPDATE' THEN

      -- Check if this transaction is part of a transfer with invalid amounts
      SELECT t.from_transaction_id, t.to_transaction_id
      INTO v_from_transaction_id, v_to_transaction_id
      FROM transfers t
      INNER JOIN transactions ft ON t.from_transaction_id = ft.id
      INNER JOIN transactions tt ON t.to_transaction_id = tt.id
      WHERE (t.from_transaction_id = NEW.id OR t.to_transaction_id = NEW.id)
        AND (ft.amount + tt.amount <> 0 OR ft.amount > 0 OR tt.amount < 0)
      LIMIT 1;

    -- Edge case to prevent unexpected behavior
    ELSE
      RAISE EXCEPTION 'Trigger function called inappropriately on table % with operation %', 
        TG_TABLE_NAME, TG_OP;
  END CASE;

  -- Raise exception if constraint violation found
  IF v_from_transaction_id IS NOT NULL THEN

    RAISE EXCEPTION 'Transfer transaction amounts must be equal and opposite'
      USING
        DETAIL = format(
          'Transfer from transaction ID %s to transaction ID %s has invalid amounts', 
          v_from_transaction_id,
          v_to_transaction_id
        ),
        ERRCODE = 'check_violation',
        HINT = 'The from transaction must be negative, the to transaction must be positive, and they must sum to zero';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for INSERT transfers table
CREATE TRIGGER trg_transfers_amounts_check_insert
  BEFORE INSERT
  ON transfers
  FOR EACH ROW
  EXECUTE FUNCTION check_transfers_amounts();

-- Trigger for UPDATE transfers table
CREATE TRIGGER trg_transfers_amounts_check_update
  BEFORE UPDATE OF from_transaction_id, to_transaction_id
  ON transfers
  FOR EACH ROW
  WHEN (OLD.from_transaction_id IS DISTINCT FROM NEW.from_transaction_id
    OR OLD.to_transaction_id IS DISTINCT FROM NEW.to_transaction_id)
  EXECUTE FUNCTION check_transfers_amounts();

-- Constraint trigger for UPDATE transactions table
CREATE CONSTRAINT TRIGGER trg_transactions_amounts_transfer_check_update
  AFTER UPDATE OF amount
  ON transactions
  DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  WHEN (OLD.amount IS DISTINCT FROM NEW.amount)
  EXECUTE FUNCTION check_transfers_amounts();

-- ===============================================================
-- Function and triggers to check transfer categorization
-- consistency
-- ===============================================================
-- Trigger function for transfers category validation
CREATE OR REPLACE FUNCTION check_transfers_category()
  RETURNS TRIGGER
  AS $$
DECLARE
  v_from_transaction_id integer;
  v_to_transaction_id integer;
BEGIN
  CASE
    -- Handle transfers table operations
    WHEN TG_TABLE_NAME = 'transfers'
      AND TG_OP IN ('INSERT', 'UPDATE') THEN

      -- Only validate if BOTH transactions have categories
      IF EXISTS (
        SELECT 1
        FROM category_transactions
        WHERE transaction_id = NEW.from_transaction_id
      ) AND EXISTS (
        SELECT 1
        FROM category_transactions
        WHERE transaction_id = NEW.to_transaction_id
      ) THEN

        -- Check if categories match
        IF EXISTS (
          SELECT 1
          FROM (
            SELECT category_id, amount
            FROM category_transactions
            WHERE transaction_id = NEW.from_transaction_id
            UNION ALL
            SELECT category_id, amount
            FROM category_transactions
            WHERE transaction_id = NEW.to_transaction_id
          ) ct_combined
          GROUP BY category_id
          HAVING SUM(amount) <> 0
        ) THEN

          v_from_transaction_id := NEW.from_transaction_id;
          v_to_transaction_id := NEW.to_transaction_id;
        END IF;
      END IF;

    -- Handle category_transactions table operations
    WHEN TG_TABLE_NAME = 'category_transactions' THEN

      -- Check all transfers involving
      SELECT t.from_transaction_id, t.to_transaction_id
      INTO v_from_transaction_id, v_to_transaction_id
      FROM (
        SELECT t.from_transaction_id, t.to_transaction_id
        FROM transfers t
        WHERE (t.from_transaction_id IN (NEW.transaction_id, OLD.transaction_id)
            OR t.to_transaction_id IN (NEW.transaction_id, OLD.transaction_id))
          -- Both sides must have categories
          AND EXISTS (
            SELECT 1
            FROM category_transactions
            WHERE transaction_id = t.from_transaction_id
          )
          AND EXISTS (
            SELECT 1
            FROM category_transactions
            WHERE transaction_id = t.to_transaction_id
          )
      ) t
      -- Check if categories match
      WHERE EXISTS (
        SELECT 1
        FROM (
          SELECT category_id, amount
          FROM category_transactions
          WHERE transaction_id = t.from_transaction_id
          UNION ALL
          SELECT category_id, amount
          FROM category_transactions
          WHERE transaction_id = t.to_transaction_id
        ) ct_combined
        GROUP BY category_id
        HAVING SUM(amount) <> 0
      )
      LIMIT 1;
    
    -- Edge case to prevent unexpected behavior
    ELSE
      RAISE EXCEPTION 'Trigger function called inappropriately on table % with operation %', 
        TG_TABLE_NAME, TG_OP;
  END CASE;

  -- Raise exception if constraint violation found
  IF v_from_transaction_id IS NOT NULL THEN

    RAISE EXCEPTION 'Transfer transactions must have matching category amounts'
      USING
        DETAIL = format(
          'Transfer from transaction ID %s to transaction ID %s has inconsistent categorization', 
          v_from_transaction_id,
          v_to_transaction_id
        ),
        ERRCODE = 'check_violation',
        HINT = 'When both transactions in a transfer are categorized, they must have the same categories with opposite amounts';
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Trigger for INSERT transfers table
CREATE TRIGGER trg_transfers_category_check_insert
  BEFORE INSERT
  ON transfers
  FOR EACH ROW
  EXECUTE FUNCTION check_transfers_category();

-- Trigger for UPDATE transfers table
CREATE TRIGGER trg_transfers_category_check_update
  BEFORE UPDATE OF from_transaction_id, to_transaction_id
  ON transfers
  FOR EACH ROW
  WHEN (OLD.from_transaction_id IS DISTINCT FROM NEW.from_transaction_id
    OR OLD.to_transaction_id IS DISTINCT FROM NEW.to_transaction_id)
  EXECUTE FUNCTION check_transfers_category();

-- Constraint trigger for INSERT/DELETE category_transactions table
CREATE CONSTRAINT TRIGGER trg_category_transactions_transfers_check_insert_delete
  AFTER INSERT OR DELETE
  ON category_transactions
  DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  EXECUTE FUNCTION check_transfers_category();

-- Constraint trigger for UPDATE category_transactions table
CREATE CONSTRAINT TRIGGER trg_category_transactions_transfers_check_update
  AFTER UPDATE OF transaction_id, category_id, amount
  ON category_transactions
  DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  WHEN (OLD.transaction_id IS DISTINCT FROM NEW.transaction_id
    OR OLD.category_id IS DISTINCT FROM NEW.category_id
    OR OLD.amount IS DISTINCT FROM NEW.amount)
  EXECUTE FUNCTION check_transfers_category();

-- ===============================================================
-- Function and triggers to check transfer ledger consistency
-- ===============================================================
-- Trigger function for transfers ledger validation
CREATE OR REPLACE FUNCTION check_transfers_ledger()
  RETURNS TRIGGER
  AS $$
DECLARE
  v_from_transaction_id integer;
  v_to_transaction_id integer;
BEGIN
  CASE
    -- Handle transfers table operations
    WHEN TG_TABLE_NAME = 'transfers'
      AND TG_OP IN ('INSERT', 'UPDATE') THEN

      -- Check if transactions belong to different ledgers
      IF EXISTS (
        SELECT 1
        FROM transactions ft
        INNER JOIN accounts fa ON ft.account_id = fa.id
        INNER JOIN transactions tt ON tt.id = NEW.to_transaction_id
        INNER JOIN accounts ta ON tt.account_id = ta.id
        WHERE ft.id = NEW.from_transaction_id
          AND fa.ledger_id <> ta.ledger_id
      ) THEN
        v_from_transaction_id := NEW.from_transaction_id;
        v_to_transaction_id := NEW.to_transaction_id;
      END IF;

    -- Handle transactions table operations (account_id change)
    WHEN TG_TABLE_NAME = 'transactions'
      AND TG_OP = 'UPDATE' THEN

      -- Check if this transaction is the "from" side of a transfer
      SELECT t.from_transaction_id, t.to_transaction_id
      INTO v_from_transaction_id, v_to_transaction_id
      FROM transfers t
      INNER JOIN transactions tt ON t.to_transaction_id = tt.id
      INNER JOIN accounts ta ON tt.account_id = ta.id
      INNER JOIN accounts fa ON fa.id = NEW.account_id
      WHERE t.from_transaction_id = NEW.id
        AND fa.ledger_id <> ta.ledger_id
      LIMIT 1;

      -- If not found, check if this transaction is the "to" side
      IF NOT FOUND THEN
        
        SELECT t.from_transaction_id, t.to_transaction_id
        INTO v_from_transaction_id, v_to_transaction_id
        FROM transfers t
        INNER JOIN transactions ft ON t.from_transaction_id = ft.id
        INNER JOIN accounts fa ON ft.account_id = fa.id
        INNER JOIN accounts ta ON ta.id = NEW.account_id
        WHERE t.to_transaction_id = NEW.id
          AND fa.ledger_id <> ta.ledger_id
        LIMIT 1;
      END IF;
    
    -- Handle accounts table operations (ledger_id change)
    WHEN TG_TABLE_NAME = 'accounts'
      AND TG_OP = 'UPDATE' THEN

      -- Check transfers where this account is on the "from" side
      SELECT t.from_transaction_id, t.to_transaction_id
      INTO v_from_transaction_id, v_to_transaction_id
      FROM transactions ft
      INNER JOIN transfers t ON ft.id = t.from_transaction_id
      INNER JOIN transactions tt ON t.to_transaction_id = tt.id
      INNER JOIN accounts ta ON tt.account_id = ta.id
      WHERE ft.account_id = NEW.id
        AND NEW.ledger_id <> ta.ledger_id
      LIMIT 1;

      -- If not found, check transfers where this account is on the "to" side
      IF NOT FOUND THEN

        SELECT t.from_transaction_id, t.to_transaction_id
        INTO v_from_transaction_id, v_to_transaction_id
        FROM transactions tt
        INNER JOIN transfers t ON tt.id = t.to_transaction_id
        INNER JOIN transactions ft ON t.from_transaction_id = ft.id
        INNER JOIN accounts fa ON ft.account_id = fa.id
        WHERE tt.account_id = NEW.id
          AND fa.ledger_id <> NEW.ledger_id
        LIMIT 1;

      END IF;
    
    -- Edge case to prevent unexpected behavior
    ELSE
      RAISE EXCEPTION 'Trigger function called inappropriately on table % with operation %', 
        TG_TABLE_NAME, TG_OP;
  END CASE;

  -- Raise exception if constraint violation found
  IF v_from_transaction_id IS NOT NULL THEN

    RAISE EXCEPTION 'Transfer transactions must belong to accounts in the same ledger'
      USING
        DETAIL = format(
          'Transfer from transaction ID %s to transaction ID %s involves accounts from different ledgers', 
          v_from_transaction_id,
          v_to_transaction_id
        ),
        ERRCODE = 'check_violation',
        HINT = 'Both transactions in a transfer must belong to accounts in the same ledger';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for INSERT transfers table
CREATE TRIGGER trg_transfers_ledger_check_insert
  BEFORE INSERT
  ON transfers
  FOR EACH ROW
  EXECUTE FUNCTION check_transfers_ledger();

-- Trigger for UPDATE transfers table
CREATE TRIGGER trg_transfers_ledger_check_update
  BEFORE UPDATE OF from_transaction_id, to_transaction_id
  ON transfers
  FOR EACH ROW
  WHEN (OLD.from_transaction_id IS DISTINCT FROM NEW.from_transaction_id
    OR OLD.to_transaction_id IS DISTINCT FROM NEW.to_transaction_id)
  EXECUTE FUNCTION check_transfers_ledger();

-- Trigger for UPDATE transactions table
CREATE TRIGGER trg_transactions_transfer_ledger_check_update
  BEFORE UPDATE OF account_id
  ON transactions
  FOR EACH ROW
  WHEN (OLD.account_id IS DISTINCT FROM NEW.account_id)
  EXECUTE FUNCTION check_transfers_ledger();

-- Trigger for UPDATE accounts table
CREATE TRIGGER trg_accounts_transfer_ledger_check_update
  BEFORE UPDATE OF ledger_id
  ON accounts
  FOR EACH ROW
  WHEN (OLD.ledger_id IS DISTINCT FROM NEW.ledger_id)
  EXECUTE FUNCTION check_transfers_ledger();

-- ===============================================================
-- Function and triggers to check asset transactions are not also
-- transfers transactions
-- ===============================================================
-- Trigger function for asset transaction transfers validation
CREATE OR REPLACE FUNCTION check_transfers_asset_transaction()
  RETURNS TRIGGER
  AS $$
DECLARE
  v_from_transaction_id integer;
  v_to_transaction_id integer;
BEGIN
  CASE
    -- Handle transfers table operations
    WHEN TG_TABLE_NAME = 'transfers'
      AND TG_OP IN ('INSERT', 'UPDATE') THEN
      
      -- Check if any transaction in this transfer has asset transactions
      IF EXISTS (
        SELECT 1
        FROM asset_transactions
        WHERE transaction_id IN (NEW.from_transaction_id, NEW.to_transaction_id)
      ) THEN
        v_from_transaction_id := NEW.from_transaction_id;
        v_to_transaction_id := NEW.to_transaction_id;
      END IF;
    
    -- Handle asset_transactions table operations
    WHEN TG_TABLE_NAME = 'asset_transactions'
      AND TG_OP IN ('INSERT', 'UPDATE') THEN

      -- Check if this transaction is part of a transfer
      SELECT from_transaction_id, to_transaction_id
      INTO v_from_transaction_id, v_to_transaction_id
      FROM transfers
      WHERE from_transaction_id = NEW.transaction_id
        OR to_transaction_id = NEW.transaction_id
      LIMIT 1;

    -- Edge case to prevent unexpected behavior
    ELSE
      RAISE EXCEPTION 'Trigger function called inappropriately on table % with operation %', 
        TG_TABLE_NAME, TG_OP;
  END CASE;

  -- Raise exception if constraint violation found
  IF v_from_transaction_id IS NOT NULL THEN

    RAISE EXCEPTION 'Transfer transactions cannot have asset transactions'
      USING
        DETAIL = format(
          'Transfer from transaction ID %s to transaction ID %s has an asset transaction associated', 
          v_from_transaction_id,
          v_to_transaction_id
        ),
        ERRCODE = 'check_violation',
        HINT = 'Transactions in a transfer cannot be asset transactions';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for INSERT transfers table
CREATE TRIGGER trg_transfers_asset_transactions_check_insert
  BEFORE INSERT
  ON transfers
  FOR EACH ROW
  EXECUTE FUNCTION check_transfers_asset_transaction();

-- Trigger for UPDATE transfers table
CREATE TRIGGER trg_transfers_asset_transactions_check_update
  BEFORE UPDATE OF from_transaction_id, to_transaction_id
  ON transfers
  FOR EACH ROW
  WHEN (OLD.from_transaction_id IS DISTINCT FROM NEW.from_transaction_id
    OR OLD.to_transaction_id IS DISTINCT FROM NEW.to_transaction_id)
  EXECUTE FUNCTION check_transfers_asset_transaction();

-- Trigger for INSERT asset_transactions table
CREATE TRIGGER trg_asset_transactions_transfers_check_insert
  BEFORE INSERT
  ON asset_transactions
  FOR EACH ROW
  EXECUTE FUNCTION check_transfers_asset_transaction();

-- Trigger for UPDATE asset_transactions table
CREATE TRIGGER trg_asset_transactions_transfers_check_update
  BEFORE UPDATE OF transaction_id
  ON asset_transactions
  FOR EACH ROW
  WHEN (OLD.transaction_id IS DISTINCT FROM NEW.transaction_id)
  EXECUTE FUNCTION check_transfers_asset_transaction();

-- ===============================================================
-- Function and triggers to check asset transactions only in asset
-- account
-- ===============================================================
-- Trigger function for asset transactions account validation
CREATE OR REPLACE FUNCTION check_asset_transactions_account_asset()
  RETURNS TRIGGER
  AS $$
DECLARE
  v_transaction_id integer;
  v_account_id integer;
BEGIN
  CASE
    -- Handle asset_transactions table operations
    WHEN TG_TABLE_NAME = 'asset_transactions'
      AND TG_OP IN ('INSERT', 'UPDATE') THEN

      -- Check if transaction belongs to a non-asset account
      SELECT t.id, t.account_id
      INTO v_transaction_id, v_account_id
      FROM transactions t
      INNER JOIN accounts a ON t.account_id = a.id
      WHERE t.id = NEW.transaction_id
        AND a.is_asset_account = FALSE
      LIMIT 1;

    -- Handle transactions table operations (account_id change)
    WHEN TG_TABLE_NAME = 'transactions'
      AND TG_OP = 'UPDATE' THEN

      -- Check if this transaction has assets AND new account is a non-asset account
      IF EXISTS (
        SELECT 1
        FROM asset_transactions
        WHERE transaction_id = NEW.id
      ) THEN

        IF EXISTS (
          SELECT 1
          FROM accounts
          WHERE id = NEW.account_id
            AND is_asset_account = FALSE
        ) THEN

          v_transaction_id := NEW.id;
          v_account_id := NEW.account_id;
        END IF;
      END IF;
    
    -- Handle accounts table operations (is_asset_account change)
    WHEN TG_TABLE_NAME = 'accounts'
      AND TG_OP = 'UPDATE' THEN

      -- Check if updated account is a non-asset account
      IF NEW.is_asset_account = FALSE THEN

        -- Find first asset transaction in this account
        SELECT t.id
        INTO v_transaction_id
        FROM transactions t
        INNER JOIN asset_transactions ast ON t.id = ast.transaction_id
        WHERE t.account_id = NEW.id
        LIMIT 1;

        IF FOUND THEN

          v_account_id := NEW.id;
        END IF;
      END IF;
    
    -- Edge case to prevent unexpected behavior
    ELSE
      RAISE EXCEPTION 'Trigger function called inappropriately on table % with operation %', 
        TG_TABLE_NAME, TG_OP;
  END CASE;

  -- Raise exception if constraint violation found
  IF v_transaction_id IS NOT NULL THEN

    RAISE EXCEPTION 'Asset transactions only allowed on asset accounts'
      USING
        DETAIL = format(
          'Transaction ID %s cannot have asset transactions because account ID %s has is_asset_account = FALSE', 
          v_transaction_id, 
          v_account_id
        ),
        ERRCODE = 'check_violation',
        HINT = 'Only transactions on accounts with is_asset_account = TRUE can have asset transactions';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for INSERT asset_transactions table
CREATE TRIGGER trg_asset_transactions_is_asset_account_check_insert
  BEFORE INSERT
  ON asset_transactions
  FOR EACH ROW
  EXECUTE FUNCTION check_asset_transactions_account_asset();

-- Trigger for UPDATE asset_transactions table
CREATE TRIGGER trg_asset_transactions_is_asset_account_check_update
  BEFORE UPDATE OF transaction_id
  ON asset_transactions
  FOR EACH ROW
  WHEN (OLD.transaction_id IS DISTINCT FROM NEW.transaction_id)
  EXECUTE FUNCTION check_asset_transactions_account_asset();

-- Trigger for UPDATE transactions table
CREATE TRIGGER trg_transactions_asset_account_check_update
  BEFORE UPDATE OF account_id
  ON transactions
  FOR EACH ROW
  WHEN (OLD.account_id IS DISTINCT FROM NEW.account_id)
  EXECUTE FUNCTION check_asset_transactions_account_asset();

-- Trigger for UPDATE accounts table
CREATE TRIGGER trg_accounts_asset_transactions_check_update
  BEFORE UPDATE OF is_asset_account
  ON accounts
  FOR EACH ROW
  WHEN (OLD.is_asset_account = TRUE AND NEW.is_asset_account = FALSE)
  EXECUTE FUNCTION check_asset_transactions_account_asset();

-- ===============================================================
-- Function and triggers to check asset transactions sum match
-- transaction amount
-- ===============================================================
-- Trigger function for asset transactions amount validation
CREATE OR REPLACE FUNCTION check_asset_transactions_amount()
  RETURNS TRIGGER
  AS $$
DECLARE
  v_transaction_id integer;
  v_transaction_amount numeric(18, 2);
  v_assets_transaction_sum numeric(18, 2);
BEGIN
  CASE
    -- Handle asset_transactions table operations
    WHEN TG_TABLE_NAME = 'asset_transactions' THEN

      -- Check if sum of asset transactions matches transaction amount
      SELECT t.id, t.amount, ast.ast_sum
      INTO v_transaction_id, v_transaction_amount, v_assets_transaction_sum
      FROM (
        SELECT transaction_id, CAST(ROUND(SUM((quantity * price_per_unit / exchange_rate) + fee), 2) AS NUMERIC(18, 2)) AS ast_sum
        FROM asset_transactions
        WHERE transaction_id IN (NEW.transaction_id, OLD.transaction_id)
        GROUP BY transaction_id
      ) ast
      INNER JOIN transactions t ON ast.transaction_id = t.id
      WHERE t.amount + ast.ast_sum <> 0
      LIMIT 1;

    -- Handle transactions table operations (amount change)
    WHEN TG_TABLE_NAME = 'transactions'
      AND TG_OP = 'UPDATE' THEN

      -- Check if sum of assets for this transaction matches new amount
      SELECT transaction_id, CAST(ROUND(SUM((quantity * price_per_unit / exchange_rate) + fee), 2) AS NUMERIC(18, 2))
      INTO v_transaction_id, v_assets_transaction_sum
      FROM asset_transactions
      WHERE transaction_id = NEW.id
      GROUP BY transaction_id
      HAVING NEW.amount + CAST(ROUND(SUM((quantity * price_per_unit / exchange_rate) + fee), 2) AS NUMERIC(18, 2)) <> 0
      LIMIT 1;

      IF FOUND THEN

        v_transaction_amount := NEW.amount;
      END IF;
    
    -- Edge case to prevent unexpected behavior
    ELSE
      RAISE EXCEPTION 'Trigger function called inappropriately on table % with operation %', 
        TG_TABLE_NAME, TG_OP;
  END CASE;

  -- Raise exception if constraint violation found
  IF v_transaction_id IS NOT NULL THEN

    RAISE EXCEPTION 'Asset transactions sum does not match transaction amount'
      USING
        DETAIL = format(
          'Transaction ID %s has an asset amount sum of %s not equal to the actual amount %s',
          v_transaction_id, 
          -v_assets_transaction_sum,
          v_transaction_amount
        ),
        ERRCODE = 'check_violation',
        HINT = 'Ensure all asset transactions for this transaction sum to the negative transaction amount';
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Constraint trigger for INSERT/DELETE asset_transactions table
CREATE CONSTRAINT TRIGGER trg_asset_transactions_amount_check_insert_delete
  AFTER INSERT OR DELETE
  ON asset_transactions 
  DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  EXECUTE FUNCTION check_asset_transactions_amount();

-- Constraint trigger for UPDATE asset_transactions table
CREATE CONSTRAINT TRIGGER trg_asset_transactions_amount_check_update
  AFTER UPDATE OF transaction_id, quantity, price_per_unit, exchange_rate, fee
  ON asset_transactions 
  DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  WHEN (OLD.transaction_id IS DISTINCT FROM NEW.transaction_id
    OR OLD.quantity IS DISTINCT FROM NEW.quantity
    OR OLD.price_per_unit IS DISTINCT FROM NEW.price_per_unit
    OR OLD.exchange_rate IS DISTINCT FROM NEW.exchange_rate
    OR OLD.fee IS DISTINCT FROM NEW.fee)
  EXECUTE FUNCTION check_asset_transactions_amount();

-- Trigger for UPDATE transactions table
CREATE TRIGGER trg_transactions_asset_amount_check_update
  BEFORE UPDATE OF amount
  ON transactions 
  FOR EACH ROW
  WHEN (OLD.amount IS DISTINCT FROM NEW.amount)
  EXECUTE FUNCTION check_asset_transactions_amount();

-- ===============================================================
-- Function and triggers to check asset transactions ledger
-- consistency
-- ===============================================================
-- Trigger function for asset transactions ledger validation
CREATE OR REPLACE FUNCTION check_asset_transactions_ledger()
  RETURNS TRIGGER
  AS $$
DECLARE
  v_transaction_id integer;
  v_asset_id integer;
BEGIN
  CASE
    -- Handle asset_transactions table operations
    WHEN TG_TABLE_NAME = 'asset_transactions'
      AND TG_OP IN ('INSERT', 'UPDATE') THEN

      -- Check if transaction and asset belong to different ledgers
      IF EXISTS (
        SELECT 1
        FROM transactions t
        INNER JOIN accounts a ON t.account_id = a.id
        INNER JOIN assets ass ON ass.id = NEW.asset_id
        WHERE t.id = NEW.transaction_id
          AND a.ledger_id <> ass.ledger_id
      ) THEN
        v_transaction_id := NEW.transaction_id;
        v_asset_id := NEW.asset_id;
      END IF;

    -- Handle transactions table operations (account_id change)
    WHEN TG_TABLE_NAME = 'transactions'
      AND TG_OP = 'UPDATE' THEN

      -- Find first asset_transactions with ledger mismatch
      SELECT ast.transaction_id, ast.asset_id
      INTO v_transaction_id, v_asset_id
      FROM asset_transactions ast
      INNER JOIN assets ass ON ast.asset_id = ass.id
      INNER JOIN accounts a ON a.id = NEW.account_id
      WHERE ast.transaction_id = NEW.id
        AND a.ledger_id <> ass.ledger_id
      LIMIT 1;
    
    -- Handle accounts table operations (ledger_id change)
    WHEN TG_TABLE_NAME = 'accounts'
      AND TG_OP = 'UPDATE' THEN

      -- Find first transaction with asset from different ledger
      SELECT ast.transaction_id, ast.asset_id
      INTO v_transaction_id, v_asset_id
      FROM transactions t
      INNER JOIN asset_transactions ast ON t.id = ast.transaction_id
      INNER JOIN assets ass ON ast.asset_id = ass.id
      WHERE t.account_id = NEW.id
        AND NEW.ledger_id <> ass.ledger_id
      LIMIT 1;
    
    -- Handle assets table operations (ledger_id change)
    WHEN TG_TABLE_NAME = 'assets'
      AND TG_OP = 'UPDATE' THEN

      -- Find first asset_transactions with ledger mismatch
      SELECT ast.transaction_id, ast.asset_id
      INTO v_transaction_id, v_asset_id
      FROM asset_transactions ast
      INNER JOIN transactions t ON ast.transaction_id = t.id
      INNER JOIN accounts a ON t.account_id = a.id
      WHERE ast.asset_id = NEW.id
        AND a.ledger_id <> NEW.ledger_id
      LIMIT 1;
    
    -- Edge case to prevent unexpected behavior
    ELSE
      RAISE EXCEPTION 'Trigger function called inappropriately on table % with operation %', 
        TG_TABLE_NAME, TG_OP;
  END CASE;

  -- Raise exception if constraint violation found
  IF v_transaction_id IS NOT NULL THEN

    RAISE EXCEPTION 'Asset and transaction must belong to the same ledger'
      USING
        DETAIL = format(
          'Asset ID %s and transaction ID %s belong to different ledgers', 
          v_asset_id,
          v_transaction_id
        ),
        ERRCODE = 'check_violation',
        HINT = 'Asset transactions can only use assets from the same ledger as the transaction account';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for INSERT asset_transactions table
CREATE TRIGGER trg_asset_transactions_ledger_check_insert
  BEFORE INSERT
  ON asset_transactions
  FOR EACH ROW
  EXECUTE FUNCTION check_asset_transactions_ledger();

-- Trigger for UPDATE asset_transactions table
CREATE TRIGGER trg_asset_transactions_ledger_check_update
  BEFORE UPDATE OF transaction_id, asset_id
  ON asset_transactions
  FOR EACH ROW
  WHEN (OLD.transaction_id IS DISTINCT FROM NEW.transaction_id
    OR OLD.asset_id IS DISTINCT FROM NEW.asset_id)
  EXECUTE FUNCTION check_asset_transactions_ledger();

-- Trigger for UPDATE transactions table
CREATE TRIGGER trg_transactions_asset_ledger_check_update
  BEFORE UPDATE OF account_id
  ON transactions
  FOR EACH ROW
  WHEN (OLD.account_id IS DISTINCT FROM NEW.account_id)
  EXECUTE FUNCTION check_asset_transactions_ledger();

-- Trigger for UPDATE accounts table
CREATE TRIGGER trg_accounts_asset_ledger_check_update
  BEFORE UPDATE OF ledger_id
  ON accounts
  FOR EACH ROW
  WHEN (OLD.ledger_id IS DISTINCT FROM NEW.ledger_id)
  EXECUTE FUNCTION check_asset_transactions_ledger();

-- Trigger for UPDATE assets table
CREATE TRIGGER trg_assets_ledger_check_update
  BEFORE UPDATE OF ledger_id
  ON assets
  FOR EACH ROW
  WHEN (OLD.ledger_id IS DISTINCT FROM NEW.ledger_id)
  EXECUTE FUNCTION check_asset_transactions_ledger();

-- ===============================================================
-- Function and triggers to cleared transactions
-- ===============================================================
-- Trigger function for cleared transactions validation
CREATE OR REPLACE FUNCTION check_transactions_cleared()
  RETURNS TRIGGER
  AS $$
DECLARE
  v_transaction_id_on_budget integer;
  v_transaction_id_transfer integer;
BEGIN
  CASE
    -- Handle transactions table operations
    WHEN TG_TABLE_NAME = 'transactions'
      AND TG_OP IN ('INSERT', 'UPDATE') THEN

      -- Check if it is a cleared transaction
      IF NEW.cleared = TRUE THEN 

        -- Check if cleared transaction has no categories when on budget account
        IF EXISTS (
          SELECT 1
          FROM accounts a
          INNER JOIN account_types at ON a.account_type_id = at.id
          WHERE a.id = NEW.account_id
            AND at.on_budget_account = TRUE
            AND NOT EXISTS (
              SELECT 1
              FROM category_transactions
              WHERE transaction_id = NEW.id)
        ) THEN

          v_transaction_id_on_budget := NEW.id;

        -- Check if transaction is a transfer or has payee
        ELSIF NOT EXISTS (
          SELECT 1
          FROM payee_transactions
          WHERE transaction_id = NEW.id
        ) AND NOT EXISTS (
          SELECT 1
          FROM transfers
          WHERE from_transaction_id = NEW.id
            OR to_transaction_id = NEW.id
        ) THEN

            v_transaction_id_transfer := NEW.id;
        END IF;
      END IF;

    -- Handle category_transactions table operations
    WHEN TG_TABLE_NAME = 'category_transactions'
      AND TG_OP IN ('UPDATE', 'DELETE') THEN

      -- Check if cleared transaction will have no categories after this operation
      IF EXISTS (
        SELECT 1
        FROM transactions t
        WHERE t.id = OLD.transaction_id
          AND t.cleared = TRUE
          AND NOT EXISTS (
            SELECT 1
            FROM category_transactions ct
            WHERE ct.transaction_id = t.id
              AND ct.category_id <> OLD.category_id)
      ) THEN

        v_transaction_id_on_budget := OLD.transaction_id;
      END IF;
    
    -- Handle payee_transactions table operations
    WHEN TG_TABLE_NAME = 'payee_transactions'
      AND TG_OP IN ('UPDATE', 'DELETE') THEN

      -- Check if cleared transaction will have no payee after this operation (and is not a transfer)
      IF EXISTS (
        SELECT 1
        FROM transactions t
        WHERE t.id = OLD.transaction_id
          AND t.cleared = TRUE
          AND NOT EXISTS (
            SELECT 1
            FROM transfers tr
            WHERE tr.from_transaction_id = t.id
              OR tr.to_transaction_id = t.id)
      ) THEN

        v_transaction_id_transfer := OLD.transaction_id;
      END IF;
    
    -- Handle transfers table operations
    WHEN TG_TABLE_NAME = 'transfers'
      AND TG_OP IN ('UPDATE', 'DELETE') THEN

      -- Check if any transaction stops being part of a transfer and has no payee
      SELECT t.id
      INTO v_transaction_id_transfer
      FROM transactions t
      WHERE t.id IN (OLD.from_transaction_id, OLD.to_transaction_id)
        AND t.id NOT IN (NEW.from_transaction_id, NEW.to_transaction_id)
        AND t.cleared = TRUE
        AND NOT EXISTS (
          SELECT 1
          FROM payee_transactions pt
          WHERE pt.transaction_id = t.id)
      LIMIT 1;

    -- Handle accounts table operations
    WHEN TG_TABLE_NAME = 'accounts'
      AND TG_OP = 'UPDATE' THEN

      -- Check if account is changing from off-budget to on-budget
      IF EXISTS (
        SELECT 1
        FROM account_types at_new
        INNER JOIN account_types at_old ON at_old.id = OLD.account_type_id
        WHERE at_new.id = NEW.account_type_id
          AND at_new.on_budget_account = TRUE
          AND at_old.on_budget_account = FALSE
      ) THEN

        -- Check if any cleared transactions from that account have no categories
        SELECT t.id
        INTO v_transaction_id_on_budget
        FROM transactions t
        WHERE t.account_id = NEW.id
          AND t.cleared = TRUE
          AND NOT EXISTS (
            SELECT 1
            FROM category_transactions ct
            WHERE ct.transaction_id = t.id)
        LIMIT 1;

      END IF;
    
    -- Handle account_types table operations
    WHEN TG_TABLE_NAME = 'account_types'
      AND TG_OP = 'UPDATE' THEN

      -- Check if account type is on-budget
      IF NEW.on_budget_account = TRUE THEN

        SELECT t.id
        INTO v_transaction_id_on_budget
        FROM accounts a
        INNER JOIN transactions t ON a.id = t.account_id
        WHERE a.account_type_id = NEW.id
          AND t.cleared = TRUE
          AND NOT EXISTS (
            SELECT 1
            FROM category_transactions ct
            WHERE ct.transaction_id = t.id)
        LIMIT 1;

      END IF;
    
    -- Edge case to prevent unexpected behavior
    ELSE
      RAISE EXCEPTION 'Trigger function called inappropriately on table % with operation %', 
        TG_TABLE_NAME, TG_OP;
  END CASE;

  -- Raise exception if on budget constraint violation found
  IF v_transaction_id_on_budget IS NOT NULL THEN

    RAISE EXCEPTION 'Cleared transactions on budget accounts must be categorized'
      USING
        DETAIL = format(
          'Transaction ID %s belongs to an on-budget account but is not categorized', 
          v_transaction_id_on_budget
        ),
        ERRCODE = 'check_violation',
        HINT = 'On-budget account transactions can only be cleared if they are categorized';
  END IF;

  -- Raise exception if transfer constraint violation found
  IF v_transaction_id_transfer IS NOT NULL THEN

    RAISE EXCEPTION 'Cleared non-transfer transactions must have a payee'
      USING
        DETAIL = format(
          'Transaction ID %s is not a transfer and does not have a payee', 
          v_transaction_id_transfer
        ),
        ERRCODE = 'check_violation',
        HINT = 'Non-transfer transactions can only be cleared if they have a payee';
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Trigger for INSERT transactions table
CREATE TRIGGER trg_transactions_cleared_check_insert
  BEFORE INSERT
  ON transactions
  FOR EACH ROW
  WHEN (NEW.cleared = TRUE)
  EXECUTE FUNCTION check_transactions_cleared();

-- Trigger for UPDATE transactions table
CREATE TRIGGER trg_transactions_cleared_check_update
  BEFORE UPDATE OF account_id, cleared
  ON transactions
  FOR EACH ROW
  WHEN (NEW.cleared = TRUE
    AND (OLD.cleared = FALSE OR OLD.account_id IS DISTINCT FROM NEW.account_id))
  EXECUTE FUNCTION check_transactions_cleared();

-- Trigger for UPDATE category_transactions table
CREATE TRIGGER trg_category_transactions_cleared_check_update
  BEFORE UPDATE OF transaction_id
  ON category_transactions
  FOR EACH ROW
  WHEN (OLD.transaction_id IS DISTINCT FROM NEW.transaction_id)
  EXECUTE FUNCTION check_transactions_cleared();

-- Trigger for DELETE category_transactions table
CREATE TRIGGER trg_category_transactions_cleared_check_delete
  BEFORE DELETE
  ON category_transactions
  FOR EACH ROW
  EXECUTE FUNCTION check_transactions_cleared();

-- Trigger for UPDATE payee_transactions table
CREATE TRIGGER trg_payee_transactions_cleared_check_update
  BEFORE UPDATE OF transaction_id
  ON payee_transactions
  FOR EACH ROW
  WHEN (OLD.transaction_id IS DISTINCT FROM NEW.transaction_id)
  EXECUTE FUNCTION check_transactions_cleared();

-- Trigger for DELETE payee_transactions table
CREATE TRIGGER trg_payee_transactions_cleared_check_delete
  BEFORE DELETE
  ON payee_transactions
  FOR EACH ROW
  EXECUTE FUNCTION check_transactions_cleared();

-- Trigger for UPDATE transfers table
CREATE TRIGGER trg_transfers_cleared_check_update
  BEFORE UPDATE OF from_transaction_id, to_transaction_id
  ON transfers
  FOR EACH ROW
  WHEN (OLD.from_transaction_id IS DISTINCT FROM NEW.from_transaction_id
    OR OLD.to_transaction_id IS DISTINCT FROM NEW.to_transaction_id)
  EXECUTE FUNCTION check_transactions_cleared();

-- Trigger for DELETE transfers table
CREATE TRIGGER trg_transfers_cleared_check_delete
  BEFORE DELETE
  ON transfers
  FOR EACH ROW
  EXECUTE FUNCTION check_transactions_cleared();

-- Trigger for UPDATE accounts table
CREATE TRIGGER trg_accounts_cleared_check_update
  BEFORE UPDATE OF account_type_id
  ON accounts
  FOR EACH ROW
  WHEN (OLD.account_type_id IS DISTINCT FROM NEW.account_type_id)
  EXECUTE FUNCTION check_transactions_cleared();

-- Trigger for UPDATE account_types table
CREATE TRIGGER trg_account_types_cleared_check_update
  BEFORE UPDATE OF on_budget_account
  ON account_types
  FOR EACH ROW
  WHEN (OLD.on_budget_account = FALSE AND NEW.on_budget_account = TRUE)
  EXECUTE FUNCTION check_transactions_cleared();

-- ===============================================================
-- Function and triggers to check categorized budget ledger
-- consistency
-- ===============================================================
-- Trigger function for category budgets ledger validation
CREATE OR REPLACE FUNCTION check_category_budgets_ledger()
  RETURNS TRIGGER
  AS $$
DECLARE
  v_budget_id integer;
  v_category_id integer;
BEGIN
  CASE
    -- Handle category_budgets table operations
    WHEN TG_TABLE_NAME = 'category_budgets'
      AND TG_OP IN ('INSERT', 'UPDATE') THEN

      -- Check if budget and category belong to different ledgers
      IF EXISTS (
        SELECT 1
        FROM budgets b
        INNER JOIN categories c ON c.id = NEW.category_id
        INNER JOIN category_groups cg ON c.category_group_id = cg.id
        WHERE b.id = NEW.budget_id
          AND b.ledger_id <> cg.ledger_id
      ) THEN
        v_budget_id := NEW.budget_id;
        v_category_id := NEW.category_id;
      END IF;
    
    -- Handle budgets table operations (ledger_id change)
    WHEN TG_TABLE_NAME = 'budgets'
      AND TG_OP = 'UPDATE' THEN

      -- Find first category_budgets with ledger mismatch
      SELECT cb.budget_id, cb.category_id
      INTO v_budget_id, v_category_id
      FROM category_budgets cb
      INNER JOIN categories c ON cb.category_id = c.id
      INNER JOIN category_groups cg ON c.category_group_id = cg.id
      WHERE cb.budget_id = NEW.id
        AND NEW.ledger_id <> cg.ledger_id
      LIMIT 1;
    
    -- Handle categories table operations (category_group_id change)
    WHEN TG_TABLE_NAME = 'categories'
      AND TG_OP = 'UPDATE' THEN

      -- Find first category_budgets with ledger mismatch
      SELECT cb.budget_id, cb.category_id
      INTO v_budget_id, v_category_id
      FROM category_budgets cb
      INNER JOIN budgets b ON cb.budget_id = b.id
      INNER JOIN category_groups cg ON cg.id = NEW.category_group_id
      WHERE cb.category_id = NEW.id
        AND b.ledger_id <> cg.ledger_id
      LIMIT 1;

    -- Handle category_groups table operations (ledger_id change)
    WHEN TG_TABLE_NAME = 'category_groups'
      AND TG_OP = 'UPDATE' THEN

      -- Find first category_budgets with ledger mismatch
      SELECT cb.budget_id, cb.category_id
      INTO v_budget_id, v_category_id
      FROM categories c
      INNER JOIN category_budgets cb ON c.id = cb.category_id
      INNER JOIN budgets b ON cb.budget_id = b.id
      WHERE c.category_group_id = NEW.id
        AND b.ledger_id <> NEW.ledger_id
      LIMIT 1;
    
    -- Edge case to prevent unexpected behavior
    ELSE
      RAISE EXCEPTION 'Trigger function called inappropriately on table % with operation %', 
        TG_TABLE_NAME, TG_OP;
  END CASE;

  -- Raise exception if constraint violation found
  IF v_budget_id IS NOT NULL THEN

    RAISE EXCEPTION 'Category and budget must belong to the same ledger'
      USING
        DETAIL = format(
          'Category ID %s and budget ID %s belong to different ledgers', 
          v_category_id,
          v_budget_id
        ),
        ERRCODE = 'check_violation',
        HINT = 'Category budgets can only use categories from the same ledger as the budget';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for INSERT category_budgets table
CREATE TRIGGER trg_category_budgets_ledger_check_insert
  BEFORE INSERT
  ON category_budgets
  FOR EACH ROW
  EXECUTE FUNCTION check_category_budgets_ledger();

-- Trigger for UPDATE category_budgets table
CREATE TRIGGER trg_category_budgets_ledger_check_update
  BEFORE UPDATE OF budget_id, category_id
  ON category_budgets
  FOR EACH ROW
  WHEN (OLD.budget_id IS DISTINCT FROM NEW.budget_id
    OR OLD.category_id IS DISTINCT FROM NEW.category_id)
  EXECUTE FUNCTION check_category_budgets_ledger();

-- Trigger for UPDATE budgets table
CREATE TRIGGER trg_budgets_ledger_check_update
  BEFORE UPDATE OF ledger_id
  ON budgets
  FOR EACH ROW
  WHEN (OLD.ledger_id IS DISTINCT FROM NEW.ledger_id)
  EXECUTE FUNCTION check_category_budgets_ledger();

-- Trigger for UPDATE categories table
CREATE TRIGGER trg_categories_budget_ledger_check_update
  BEFORE UPDATE OF category_group_id
  ON categories
  FOR EACH ROW
  WHEN (OLD.category_group_id IS DISTINCT FROM NEW.category_group_id)
  EXECUTE FUNCTION check_category_budgets_ledger();

-- Trigger for UPDATE category_groups table
CREATE TRIGGER trg_category_groups_budget_ledger_check_update
  BEFORE UPDATE OF ledger_id
  ON category_groups
  FOR EACH ROW
  WHEN (OLD.ledger_id IS DISTINCT FROM NEW.ledger_id)
  EXECUTE FUNCTION check_category_budgets_ledger();