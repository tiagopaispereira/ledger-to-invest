-- ===============================================================
-- LTI (Ledger-To-Invest) App Database Function and Trigger Schema
-- PostgreSQL Implementation
-- ===============================================================
--
-- ===============================================================
-- Function and triggers to update the updated_at timestamp
-- ===============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
  RETURNS TRIGGER
  AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$
LANGUAGE 'plpgsql';

CREATE TRIGGER update_date_formats_updated_at
  BEFORE UPDATE ON date_formats
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_currencies_updated_at
  BEFORE UPDATE ON currencies
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_currency_exchange_rates_updated_at
  BEFORE UPDATE ON currency_exchange_rates
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ledgers_updated_at
  BEFORE UPDATE ON ledgers
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_account_types_updated_at
  BEFORE UPDATE ON account_types
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_accounts_updated_at
  BEFORE UPDATE ON accounts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_asset_types_updated_at
  BEFORE UPDATE ON asset_types
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_assets_updated_at
  BEFORE UPDATE ON assets
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_asset_prices_updated_at
  BEFORE UPDATE ON asset_prices
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_category_groups_updated_at
  BEFORE UPDATE ON category_groups
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_categories_updated_at
  BEFORE UPDATE ON categories
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_goal_types_updated_at
  BEFORE UPDATE ON goal_types
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_goals_updated_at
  BEFORE UPDATE ON goals
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payees_updated_at
  BEFORE UPDATE ON payees
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_transactions_updated_at
  BEFORE UPDATE ON transactions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payee_transactions_updated_at
  BEFORE UPDATE ON payee_transactions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_category_transactions_updated_at
  BEFORE UPDATE ON category_transactions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_transfers_updated_at
  BEFORE UPDATE ON transfers
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_asset_transactions_updated_at
  BEFORE UPDATE ON asset_transactions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_budgets_updated_at
  BEFORE UPDATE ON budgets
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_category_budgets_updated_at
  BEFORE UPDATE ON category_budgets
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ===============================================================
-- Function and triggers to check if the asset account uses an 
-- account type that does allow investments
-- ===============================================================
CREATE OR REPLACE FUNCTION check_account_asset_account_type_can_invest ()
  RETURNS TRIGGER
  AS $$
DECLARE
  v_account_id integer;
  v_account_type_id integer;
BEGIN
  CASE
    WHEN TG_TABLE_NAME = 'accounts'
      AND TG_OP IN ('INSERT', 'UPDATE') THEN
      
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
    
    WHEN TG_TABLE_NAME = 'account_types'
      AND TG_OP = 'UPDATE' THEN
      
      IF NEW.can_invest = FALSE THEN
        SELECT id INTO v_account_id
        FROM accounts
        WHERE account_type_id = NEW.id
          AND is_asset_account = TRUE
        LIMIT 1;
        
        IF FOUND THEN
          v_account_type_id := NEW.id;
        END IF;
      END IF;
    
    ELSE
      RAISE EXCEPTION 'Trigger function called inappropriately on table % with operation %', TG_TABLE_NAME, TG_OP;
  END CASE;
  
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

CREATE TRIGGER trg_accounts_asset_investment_check
  BEFORE INSERT OR UPDATE OF is_asset_account, account_type_id 
  ON accounts
  FOR EACH ROW
  WHEN (NEW.is_asset_account = TRUE)
  EXECUTE FUNCTION check_account_asset_account_type_can_invest();

CREATE TRIGGER trg_account_types_investment_check
  BEFORE UPDATE OF can_invest 
  ON account_types
  FOR EACH ROW
  WHEN (OLD.can_invest = TRUE AND NEW.can_invest = FALSE)
  EXECUTE FUNCTION check_account_asset_account_type_can_invest();

-- ===============================================================
-- Function and triggers to check if goal have a target month when
-- using goal type that requires dates
-- ===============================================================
CREATE OR REPLACE FUNCTION check_goal_month_goal_type_has_date ()
  RETURNS TRIGGER
  AS $$
DECLARE
  v_category_id integer;
  v_goal_type_id integer;
BEGIN
  CASE
    WHEN TG_TABLE_NAME = 'goals'
      AND TG_OP IN ('INSERT', 'UPDATE') THEN
      
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
    
    WHEN TG_TABLE_NAME = 'goal_types'
      AND TG_OP = 'UPDATE' THEN
      
      IF NEW.has_date = TRUE THEN
        SELECT category_id INTO v_category_id
        FROM goals
        WHERE goal_type_id = NEW.id
          AND goal_month IS NULL
        LIMIT 1;
      
        IF FOUND THEN
          v_goal_type_id := NEW.id;
        END IF;
      END IF;
    
    ELSE
      RAISE EXCEPTION 'Trigger function called inappropriately on table % with operation %', TG_TABLE_NAME, TG_OP;
  END CASE;
  
  IF v_category_id IS NOT NULL THEN
    RAISE EXCEPTION 'Goal must have a target month when using goal type that requires dates'
      USING
        DETAIL = format(
          'Goal for Category ID %s must have a goal_month because goal type ID %s has has_date = TRUE', 
          v_category_id, 
          v_goal_type_id
        ),
        ERRCODE = 'check_violation',
        HINT = 'Either set a goal_month or use a goal type with has_date = FALSE';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_goals_month_has_date_check
  BEFORE INSERT OR UPDATE OF goal_month, goal_type_id 
  ON goals
  FOR EACH ROW
  WHEN (NEW.goal_month IS NULL)
  EXECUTE FUNCTION check_goal_month_goal_type_has_date();

CREATE TRIGGER trg_goal_types_has_date_check
  BEFORE UPDATE OF has_date 
  ON goal_types
  FOR EACH ROW
  WHEN (OLD.has_date = FALSE AND NEW.has_date = TRUE)
  EXECUTE FUNCTION check_goal_month_goal_type_has_date();

-- ===============================================================
-- Function and triggers to check categorized transactions in
-- on budget account
-- ===============================================================
CREATE OR REPLACE FUNCTION check_category_transactions_on_budget_account()
  RETURNS TRIGGER
  AS $$
DECLARE
  v_transaction_ids int[];
  DECLARE rec RECORD;
BEGIN
  IF (TG_TABLE_NAME = 'transactions') THEN
    SELECT
      ARRAY_AGG(DISTINCT transaction_id) INTO v_transaction_ids
    FROM
      category_transactions
    WHERE
      transaction_id = NEW.id;
  ELSIF (TG_TABLE_NAME = 'accounts') THEN
    SELECT
      ARRAY_AGG(DISTINCT category_transactions.transaction_id) INTO v_transaction_ids
    FROM
      category_transactions
      INNER JOIN transactions ON category_transactions.transaction_id = transactions.id
    WHERE
      transactions.account_id = NEW.id;
  ELSIF (TG_TABLE_NAME = 'account_types') THEN
    SELECT
      ARRAY_AGG(DISTINCT category_transactions.transaction_id) INTO v_transaction_ids
    FROM
      category_transactions
      INNER JOIN transactions ON category_transactions.transaction_id = transactions.id
      INNER JOIN accounts ON transactions.account_id = accounts.id
    WHERE
      accounts.account_type_id = NEW.id;
  ELSE
    v_transaction_ids := ARRAY[NEW.transaction_id];
  END IF;
  FOR rec IN (
    SELECT
      transactions.id,
      transactions.account_id,
      account_types.on_budget_account
    FROM
      transactions
      INNER JOIN accounts ON transactions.account_id = accounts.id
      INNER JOIN account_types ON accounts.account_type_id = account_types.id
    WHERE
      transactions.id = ANY (v_transaction_ids))
    LOOP
      IF (rec.on_budget_account = FALSE) THEN
        RAISE EXCEPTION 'Categorized transactions only allowed in Accounts with on_budget_account (for transaction_id % and account_id %).', rec.id, rec.account_id;
      END IF;
    END LOOP;
  RETURN NEW;
END;
$$
LANGUAGE 'plpgsql';

CREATE TRIGGER trg_category_transactions_on_budget_account_on_change
  AFTER INSERT OR UPDATE ON category_transactions
  FOR EACH ROW
  EXECUTE FUNCTION check_category_transactions_on_budget_account();

CREATE TRIGGER trg_category_transactions_on_budget_account_on_transactions_change
  AFTER UPDATE OF account_id ON transactions
  FOR EACH ROW
  WHEN(OLD.account_id IS DISTINCT FROM NEW.account_id)
  EXECUTE FUNCTION check_category_transactions_on_budget_account();

CREATE TRIGGER trg_category_transactions_on_budget_account_on_accounts_change
  AFTER UPDATE OF account_type_id ON accounts
  FOR EACH ROW
  WHEN(OLD.account_type_id IS DISTINCT FROM NEW.account_type_id)
  EXECUTE FUNCTION check_category_transactions_on_budget_account();

CREATE TRIGGER trg_category_transactions_on_budget_account_on_account_types_change
  AFTER UPDATE OF on_budget_account ON account_types
  FOR EACH ROW
  WHEN(OLD.on_budget_account IS DISTINCT FROM NEW.on_budget_account)
  EXECUTE FUNCTION check_category_transactions_on_budget_account();

-- ===============================================================
-- Function and triggers to check categorized transactions amounts
-- ===============================================================
CREATE OR REPLACE FUNCTION check_category_transactions_amount()
  RETURNS TRIGGER
  AS $$
DECLARE
  v_transaction_ids int[];
  DECLARE v_transaction_id int;
  DECLARE v_category_transactions_sum numeric(18, 2);
  DECLARE v_transactions_amount numeric(18, 2);
BEGIN
  IF (TG_TABLE_NAME = 'transactions') THEN
    SELECT
      ARRAY_AGG(DISTINCT transaction_id) INTO v_transaction_ids
    FROM
      category_transactions
    WHERE
      transaction_id IN (NEW.id);
  ELSE
    SELECT
      ARRAY_AGG(DISTINCT transaction_id) INTO v_transaction_ids
    FROM
      category_transactions
    WHERE
      transaction_id IN (NEW.transaction_id, OLD.transaction_id);
  END IF;
  IF (v_transaction_ids IS NOT NULL) THEN
    FOREACH v_transaction_id IN ARRAY v_transaction_ids LOOP
      SELECT
        COALESCE(SUM(amount), 0) INTO v_category_transactions_sum
      FROM
        category_transactions
      WHERE
        transaction_id = v_transaction_id;
      SELECT
        amount INTO v_transactions_amount
      FROM
        transactions
      WHERE
        id = v_transaction_id;
      IF (v_transactions_amount <> v_category_transactions_sum) THEN
        RAISE EXCEPTION 'Categorized transactions sum (%) does not equal the total transaction amount (%) for transaction_id %.', v_category_transactions_sum, v_transactions_amount, v_transaction_id;
      END IF;
    END LOOP;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$
LANGUAGE 'plpgsql';

CREATE CONSTRAINT TRIGGER trg_category_transactions_amount_on_change
  AFTER INSERT OR UPDATE OR DELETE ON category_transactions DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  EXECUTE FUNCTION check_category_transactions_amount();

CREATE CONSTRAINT TRIGGER trg_category_transactions_amount_on_transactions_change
  AFTER UPDATE OF amount ON transactions DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  WHEN(OLD.amount IS DISTINCT FROM NEW.amount)
  EXECUTE FUNCTION check_category_transactions_amount();

-- ===============================================================
-- Function and triggers to check categorized transactions ledger
-- consistency
-- ===============================================================
CREATE OR REPLACE FUNCTION check_category_transactions_ledger()
  RETURNS TRIGGER
  AS $$
DECLARE
  v_transaction_ids int[];
  DECLARE v_category_ids int[];
  DECLARE v_ledger_count int;
  DECLARE rec RECORD;
BEGIN
  IF (TG_TABLE_NAME = 'transactions') THEN
    SELECT
      ARRAY_AGG(DISTINCT transaction_id),
      ARRAY_AGG(DISTINCT category_id) INTO v_transaction_ids,
      v_category_ids
    FROM
      category_transactions
    WHERE
      transaction_id = NEW.id;
  ELSIF (TG_TABLE_NAME = 'accounts') THEN
    SELECT
      ARRAY_AGG(DISTINCT category_transactions.transaction_id),
      ARRAY_AGG(DISTINCT category_transactions.category_id) INTO v_transaction_ids,
      v_category_ids
    FROM
      category_transactions
      INNER JOIN transactions ON category_transactions.transaction_id = transactions.id
    WHERE
      transactions.account_id = NEW.id;
  ELSIF (TG_TABLE_NAME = 'categories') THEN
    SELECT
      ARRAY_AGG(DISTINCT transaction_id),
      ARRAY_AGG(DISTINCT category_id) INTO v_transaction_ids,
      v_category_ids
    FROM
      category_transactions
    WHERE
      category_id = NEW.id;
  ELSIF (TG_TABLE_NAME = 'category_groups') THEN
    SELECT
      ARRAY_AGG(DISTINCT category_transactions.transaction_id),
      ARRAY_AGG(DISTINCT category_transactions.category_id) INTO v_transaction_ids,
      v_category_ids
    FROM
      category_transactions
      INNER JOIN categories ON category_transactions.category_id = categories.id
    WHERE
      categories.category_group_id = NEW.id;
  ELSE
    v_transaction_ids := ARRAY[NEW.transaction_id];
    v_category_ids := ARRAY[NEW.category_id];
  END IF;
  FOR rec IN (
    SELECT
      transaction_id,
      category_id
    FROM
      category_transactions
    WHERE
      transaction_id = ANY (v_transaction_ids)
      AND category_id = ANY (v_category_ids))
    LOOP
      SELECT
        COUNT(DISTINCT ledger_id) INTO v_ledger_count
      FROM (
        SELECT
          accounts.ledger_id
        FROM
          transactions
          INNER JOIN accounts ON transactions.account_id = accounts.id
        WHERE
          transactions.id = rec.transaction_id
        UNION ALL
        SELECT
          category_groups.ledger_id
        FROM
          categories
          INNER JOIN category_groups ON categories.category_group_id = category_groups.id
        WHERE
          categories.id = rec.category_id);
      IF (v_ledger_count > 1) THEN
        RAISE EXCEPTION 'Categorized transactions category can only be associated with account transaction from the same ledger (for transaction_id % and category_id %).', rec.transaction_id, rec.category_id;
      END IF;
    END LOOP;
  RETURN NEW;
END;
$$
LANGUAGE 'plpgsql';

CREATE CONSTRAINT TRIGGER trg_category_transactions_ledger_on_change
  AFTER INSERT OR UPDATE ON category_transactions DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  EXECUTE FUNCTION check_category_transactions_ledger();

CREATE CONSTRAINT TRIGGER trg_category_transactions_ledger_on_transactions_change
  AFTER UPDATE OF account_id ON transactions DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  WHEN(OLD.account_id IS DISTINCT FROM NEW.account_id)
  EXECUTE FUNCTION check_category_transactions_ledger();

CREATE CONSTRAINT TRIGGER trg_category_transactions_ledger_on_accounts_change
  AFTER UPDATE OF ledger_id ON accounts DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  WHEN(OLD.ledger_id IS DISTINCT FROM NEW.ledger_id)
  EXECUTE FUNCTION check_category_transactions_ledger();

CREATE CONSTRAINT TRIGGER trg_category_transactions_ledger_on_categories_change
  AFTER UPDATE OF category_group_id ON categories DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  WHEN(OLD.category_group_id IS DISTINCT FROM NEW.category_group_id)
  EXECUTE FUNCTION check_category_transactions_ledger();

CREATE CONSTRAINT TRIGGER trg_category_transactions_ledger_on_category_groups_change
  AFTER UPDATE OF ledger_id ON category_groups DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  WHEN(OLD.ledger_id IS DISTINCT FROM NEW.ledger_id)
  EXECUTE FUNCTION check_category_transactions_ledger();

-- ===============================================================
-- Function and triggers to check payee transactions ledger
-- consistency
-- ===============================================================
CREATE OR REPLACE FUNCTION check_payee_transactions_ledger()
  RETURNS TRIGGER
  AS $$
DECLARE
  v_transaction_ids int[];
  DECLARE v_payee_ids int[];
  DECLARE v_ledger_count int;
  DECLARE rec RECORD;
BEGIN
  IF (TG_TABLE_NAME = 'transactions') THEN
    SELECT
      ARRAY_AGG(DISTINCT transaction_id),
      ARRAY_AGG(DISTINCT payee_id) INTO v_transaction_ids,
      v_payee_ids
    FROM
      payee_transactions
    WHERE
      transaction_id = NEW.id;
  ELSIF (TG_TABLE_NAME = 'accounts') THEN
    SELECT
      ARRAY_AGG(DISTINCT payee_transactions.transaction_id),
      ARRAY_AGG(DISTINCT payee_transactions.payee_id) INTO v_transaction_ids,
      v_payee_ids
    FROM
      payee_transactions
      INNER JOIN transactions ON payee_transactions.transaction_id = transactions.id
    WHERE
      transactions.account_id = NEW.id;
  ELSIF (TG_TABLE_NAME = 'payees') THEN
    SELECT
      ARRAY_AGG(DISTINCT transaction_id),
      ARRAY_AGG(DISTINCT payee_id) INTO v_transaction_ids,
      v_payee_ids
    FROM
      payee_transactions
    WHERE
      payee_id = NEW.id;
  ELSE
    v_transaction_ids := ARRAY[NEW.transaction_id];
    v_payee_ids := ARRAY[NEW.payee_id];
  END IF;
  FOR rec IN (
    SELECT
      transaction_id,
      payee_id
    FROM
      payee_transactions
    WHERE
      transaction_id = ANY (v_transaction_ids)
      AND payee_id = ANY (v_payee_ids))
    LOOP
      SELECT
        COUNT(DISTINCT ledger_id) INTO v_ledger_count
      FROM (
        SELECT
          accounts.ledger_id
        FROM
          transactions
          INNER JOIN accounts ON transactions.account_id = accounts.id
        WHERE
          transactions.id = rec.transaction_id
        UNION ALL
        SELECT
          payees.ledger_id
        FROM
          payees
        WHERE
          payees.id = rec.payee_id);
      IF (v_ledger_count > 1) THEN
        RAISE EXCEPTION 'Payee transactions payee can only be associated with account transaction from the same ledger (for transaction_id % and payee_id %).', rec.transaction_id, rec.payee_id;
      END IF;
    END LOOP;
  RETURN NEW;
END;
$$
LANGUAGE 'plpgsql';

CREATE CONSTRAINT TRIGGER trg_payee_transaction_ledger_on_change
  AFTER INSERT OR UPDATE ON payee_transactions DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  EXECUTE FUNCTION check_payee_transactions_ledger();

CREATE CONSTRAINT TRIGGER trg_payee_transaction_ledger_on_transactions_change
  AFTER UPDATE OF account_id ON transactions DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  WHEN(OLD.account_id IS DISTINCT FROM NEW.account_id)
  EXECUTE FUNCTION check_payee_transactions_ledger();

CREATE CONSTRAINT TRIGGER trg_payee_transaction_ledger_on_accounts_change
  AFTER UPDATE OF ledger_id ON accounts DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  WHEN(OLD.ledger_id IS DISTINCT FROM NEW.ledger_id)
  EXECUTE FUNCTION check_payee_transactions_ledger();

CREATE CONSTRAINT TRIGGER trg_payee_transaction_ledger_on_payees_change
  AFTER UPDATE OF ledger_id ON payees DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  WHEN(OLD.ledger_id IS DISTINCT FROM NEW.ledger_id)
  EXECUTE FUNCTION check_payee_transactions_ledger();

-- ===============================================================
-- Function and triggers to check transfer without payee
-- ===============================================================
CREATE OR REPLACE FUNCTION check_transfers_without_payee()
  RETURNS TRIGGER
  AS $$
DECLARE
  v_from_transaction_id int;
  DECLARE v_to_transaction_id int;
  DECLARE v_transfers_payee_count int;
BEGIN
  IF (TG_TABLE_NAME = 'payee_transactions') THEN
    SELECT
      from_transaction_id,
      to_transaction_id INTO v_from_transaction_id,
      v_to_transaction_id
    FROM
      transfers
    WHERE
      from_transaction_id = NEW.transaction_id
      OR to_transaction_id = NEW.transaction_id;
  ELSE
    v_from_transaction_id := NEW.from_transaction_id;
    v_to_transaction_id := NEW.to_transaction_id;
  END IF;
  IF (v_from_transaction_id IS NOT NULL AND v_to_transaction_id IS NOT NULL) THEN
    SELECT
      COUNT(*) INTO v_transfers_payee_count
    FROM
      payee_transactions
    WHERE
      transaction_id IN (v_from_transaction_id, v_to_transaction_id);
    IF (v_transfers_payee_count > 0) THEN
      RAISE EXCEPTION 'Transferred transactions can not have payee associated (from transaction_id % to transaction_id %).', v_from_transaction_id, v_to_transaction_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$
LANGUAGE 'plpgsql';

CREATE TRIGGER trg_transfers_without_payee_on_change
  AFTER INSERT OR UPDATE ON transfers
  FOR EACH ROW
  EXECUTE FUNCTION check_transfers_without_payee();

CREATE TRIGGER trg_transfers_without_payee_on_payee_transactions_change
  AFTER INSERT OR UPDATE ON payee_transactions
  FOR EACH ROW
  EXECUTE FUNCTION check_transfers_without_payee();

-- ===============================================================
-- Function and triggers to check transfer between different
-- accounts
-- ===============================================================
CREATE OR REPLACE FUNCTION check_transfers_between_accounts()
  RETURNS TRIGGER
  AS $$
DECLARE
  v_from_transaction_id int;
  DECLARE v_to_transaction_id int;
  DECLARE v_transfers_account_count int;
BEGIN
  IF (TG_TABLE_NAME = 'transactions') THEN
    SELECT
      from_transaction_id,
      to_transaction_id INTO v_from_transaction_id,
      v_to_transaction_id
    FROM
      transfers
    WHERE
      from_transaction_id = NEW.id
      OR to_transaction_id = NEW.id;
  ELSE
    v_from_transaction_id := NEW.from_transaction_id;
    v_to_transaction_id := NEW.to_transaction_id;
  END IF;
  IF (v_from_transaction_id IS NOT NULL AND v_to_transaction_id IS NOT NULL) THEN
    SELECT
      COUNT(DISTINCT account_id) INTO v_transfers_account_count
    FROM
      transactions
    WHERE
      id IN (v_from_transaction_id, v_to_transaction_id);
    IF (v_transfers_account_count < 2) THEN
      RAISE EXCEPTION 'Transferred transactions from/to the same account not allowed (from transaction_id % to transaction_id %).', v_from_transaction_id, v_to_transaction_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$
LANGUAGE 'plpgsql';

CREATE TRIGGER trg_transfers_between_accounts_on_change
  AFTER INSERT OR UPDATE ON transfers
  FOR EACH ROW
  EXECUTE FUNCTION check_transfers_between_accounts();

CREATE TRIGGER trg_transfers_between_accounts_on_transactions_change
  AFTER UPDATE OF account_id ON transactions
  FOR EACH ROW
  WHEN(OLD.account_id IS DISTINCT FROM NEW.account_id)
  EXECUTE FUNCTION check_transfers_between_accounts();

-- ===============================================================
-- Function and triggers to check transfer amounts
-- ===============================================================
CREATE OR REPLACE FUNCTION check_transfers_amounts()
  RETURNS TRIGGER
  AS $$
DECLARE
  v_from_transaction_id int;
  DECLARE v_to_transaction_id int;
  DECLARE v_transfer_from numeric(18, 2);
  DECLARE v_transfer_to numeric(18, 2);
BEGIN
  IF (TG_TABLE_NAME = 'transactions') THEN
    SELECT
      from_transaction_id,
      to_transaction_id INTO v_from_transaction_id,
      v_to_transaction_id
    FROM
      transfers
    WHERE
      from_transaction_id = NEW.id
      OR to_transaction_id = NEW.id;
  ELSE
    v_from_transaction_id := NEW.from_transaction_id;
    v_to_transaction_id := NEW.to_transaction_id;
  END IF;
  IF (v_from_transaction_id IS NOT NULL AND v_to_transaction_id IS NOT NULL) THEN
    SELECT
      amount INTO v_transfer_from
    FROM
      transactions
    WHERE
      id IN (v_from_transaction_id);
    SELECT
      amount INTO v_transfer_to
    FROM
      transactions
    WHERE
      id IN (v_to_transaction_id);
    IF ((v_transfer_to + v_transfer_from) <> 0) THEN
      RAISE EXCEPTION 'Transferred amount does not match (from transaction_id % to transaction_id % mismatch %).', v_from_transaction_id, v_to_transaction_id,(v_transfer_to - v_transfer_from);
    ELSIF (v_transfer_from > 0
        OR v_transfer_to < 0) THEN
      RAISE EXCEPTION 'Transferred amount does not match transfer direction (from transaction_id % should be negative and to transaction_id % positive).', v_from_transaction_id, v_to_transaction_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$
LANGUAGE 'plpgsql';

CREATE TRIGGER trg_transfers_amounts_on_change
  AFTER INSERT OR UPDATE ON transfers
  FOR EACH ROW
  EXECUTE FUNCTION check_transfers_amounts();

CREATE TRIGGER trg_transfers_amounts_on_transactions_change
  AFTER UPDATE OF amount ON transactions
  FOR EACH ROW
  WHEN(OLD.amount IS DISTINCT FROM NEW.amount)
  EXECUTE FUNCTION check_transfers_amounts();

-- ===============================================================
-- Function and triggers to check transfer categorization
-- consistency
-- ===============================================================
CREATE OR REPLACE FUNCTION check_transfers_categorization()
  RETURNS TRIGGER
  AS $$
DECLARE
  v_from_transaction_ids int[];
  DECLARE v_to_transaction_ids int[];
  DECLARE v_transfers_category_count_mismatch int;
  DECLARE rec RECORD;
BEGIN
  IF (TG_TABLE_NAME = 'transactions') THEN
    SELECT
      ARRAY_AGG(DISTINCT from_transaction_id),
      ARRAY_AGG(DISTINCT to_transaction_id) INTO v_from_transaction_ids,
      v_to_transaction_ids
    FROM
      transfers
    WHERE
      from_transaction_id = NEW.id
      OR to_transaction_id = NEW.id;
  ELSIF (TG_TABLE_NAME = 'accounts') THEN
    SELECT
      ARRAY_AGG(DISTINCT transfers.from_transaction_id),
      ARRAY_AGG(DISTINCT transfers.to_transaction_id) INTO v_from_transaction_ids,
      v_to_transaction_ids
    FROM
      transfers
      INNER JOIN transactions ON transfers.from_transaction_id = transactions.id
        OR transfers.to_transaction_id = transactions.id
    WHERE
      transactions.account_id = NEW.id;
  ELSIF (TG_TABLE_NAME = 'account_types') THEN
    SELECT
      ARRAY_AGG(DISTINCT transfers.from_transaction_id),
      ARRAY_AGG(DISTINCT transfers.to_transaction_id) INTO v_from_transaction_ids,
      v_to_transaction_ids
    FROM
      transfers
      INNER JOIN transactions ON transfers.from_transaction_id = transactions.id
        OR transfers.to_transaction_id = transactions.id
      INNER JOIN accounts ON transactions.account_id = accounts.id
    WHERE
      accounts.account_type_id = NEW.id;
  ELSIF (TG_TABLE_NAME = 'category_transactions') THEN
    SELECT
      ARRAY_AGG(DISTINCT from_transaction_id),
      ARRAY_AGG(DISTINCT to_transaction_id) INTO v_from_transaction_ids,
      v_to_transaction_ids
    FROM
      transfers
    WHERE
      from_transaction_id IN (NEW.transaction_id, OLD.transaction_id)
      OR to_transaction_id IN (NEW.transaction_id, OLD.transaction_id);
  ELSE
    v_from_transaction_ids := ARRAY[NEW.from_transaction_id];
    v_to_transaction_ids := ARRAY[NEW.to_transaction_id];
  END IF;
  FOR rec IN (
    SELECT
      transfers.from_transaction_id,
      transfers.to_transaction_id
    FROM
      transfers
      INNER JOIN transactions from_transaction ON transfers.from_transaction_id = from_transaction.id
      INNER JOIN accounts from_account ON from_transaction.account_id = from_account.id
      INNER JOIN account_types from_account_type ON from_account.account_type_id = from_account_type.id
      INNER JOIN transactions to_transaction ON transfers.to_transaction_id = to_transaction.id
      INNER JOIN accounts to_account ON to_transaction.account_id = to_account.id
      INNER JOIN account_types to_account_type ON to_account.account_type_id = to_account_type.id
    WHERE
      transfers.from_transaction_id = ANY (v_from_transaction_ids)
      AND transfers.to_transaction_id = ANY (v_to_transaction_ids)
      AND from_account_type.on_budget_account = TRUE
      AND to_account_type.on_budget_account = TRUE)
    LOOP
      SELECT
        COUNT(*) INTO v_transfers_category_count_mismatch
      FROM (
        SELECT
          category_id
        FROM
          category_transactions
        WHERE
          transaction_id IN (rec.from_transaction_id, rec.to_transaction_id)
        GROUP BY
          category_id
        HAVING
          SUM(amount) <> 0);
      IF (v_transfers_category_count_mismatch > 0) THEN
        RAISE EXCEPTION 'Transferred transactions should be consistent in categorization (from transaction_id % to transaction_id %).', rec.from_transaction_id, rec.to_transaction_id;
      END IF;
    END LOOP;
  RETURN NEW;
END;
$$
LANGUAGE 'plpgsql';

CREATE CONSTRAINT TRIGGER trg_transfers_categorization_on_change
  AFTER INSERT OR UPDATE ON transfers DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  EXECUTE FUNCTION check_transfers_categorization();

CREATE CONSTRAINT TRIGGER trg_transfers_categorization_on_category_transactions_update
  AFTER INSERT OR UPDATE OR DELETE ON category_transactions DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  EXECUTE FUNCTION check_transfers_categorization();

CREATE TRIGGER trg_transfers_categorization_on_transactions_change
  AFTER UPDATE OF account_id ON transactions
  FOR EACH ROW
  WHEN(OLD.account_id IS DISTINCT FROM NEW.account_id)
  EXECUTE FUNCTION check_transfers_categorization();

CREATE TRIGGER trg_transfers_categorization_on_accounts_change
  AFTER UPDATE OF account_type_id ON accounts
  FOR EACH ROW
  WHEN(OLD.account_type_id IS DISTINCT FROM NEW.account_type_id)
  EXECUTE FUNCTION check_transfers_categorization();

CREATE TRIGGER trg_transfers_categorization_on_account_types_change
  AFTER UPDATE OF on_budget_account ON account_types
  FOR EACH ROW
  WHEN(OLD.on_budget_account IS DISTINCT FROM NEW.on_budget_account)
  EXECUTE FUNCTION check_transfers_categorization();

-- ===============================================================
-- Function and triggers to check transfer ledger consistency
-- ===============================================================
CREATE OR REPLACE FUNCTION check_transfers_ledger()
  RETURNS TRIGGER
  AS $$
DECLARE
  v_transaction_ids int[];
  DECLARE v_ledger_count int;
  DECLARE rec RECORD;
BEGIN
  IF (TG_TABLE_NAME = 'transactions') THEN
    v_transaction_ids := ARRAY[NEW.id];
  ELSIF (TG_TABLE_NAME = 'accounts') THEN
    SELECT
      ARRAY_AGG(DISTINCT transaction_id) INTO v_transaction_ids
    FROM
      transactions
    WHERE
      account_id = NEW.id;
  ELSE
    v_transaction_ids := ARRAY[NEW.from_transaction_id, NEW.to_transaction_id];
  END IF;
  FOR rec IN (
    SELECT
      from_transaction_id,
      to_transaction_id
    FROM
      transfers
    WHERE
      from_transaction_id = ANY (v_transaction_ids)
      OR to_transaction_id = ANY (v_transaction_ids))
    LOOP
      SELECT
        COUNT(DISTINCT accounts.ledger_id) INTO v_ledger_count
      FROM
        transactions
        INNER JOIN accounts ON transactions.account_id = accounts.id
      WHERE
        transactions.id IN (rec.from_transaction_id, rec.to_transaction_id);
      IF (v_ledger_count > 1) THEN
        RAISE EXCEPTION 'Transferred transactions can only be associated with accounts from the same ledger (from transaction_id % to transaction_id %).', rec.from_transaction_id, rec.to_transaction_id;
      END IF;
    END LOOP;
  RETURN NEW;
END;
$$
LANGUAGE 'plpgsql';

CREATE CONSTRAINT TRIGGER trg_transfers_ledger_on_change
  AFTER INSERT OR UPDATE ON transfers DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  EXECUTE FUNCTION check_transfers_ledger();

CREATE CONSTRAINT TRIGGER trg_transfers_ledger_on_transactions_change
  AFTER UPDATE OF account_id ON transactions DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  WHEN(OLD.account_id IS DISTINCT FROM NEW.account_id)
  EXECUTE FUNCTION check_transfers_ledger();

CREATE CONSTRAINT TRIGGER trg_transfers_ledger_on_accounts_change
  AFTER UPDATE OF ledger_id ON accounts DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  WHEN(OLD.ledger_id IS DISTINCT FROM NEW.ledger_id)
  EXECUTE FUNCTION check_transfers_ledger();

-- ===============================================================
-- Function and triggers to check asset transactions in asset
-- account
-- ===============================================================
CREATE OR REPLACE FUNCTION check_asset_transactions_account_asset()
  RETURNS TRIGGER
  AS $$
DECLARE
  v_transaction_ids int[];
  DECLARE rec RECORD;
BEGIN
  IF (TG_TABLE_NAME = 'transactions') THEN
    SELECT
      ARRAY_AGG(DISTINCT transaction_id) INTO v_transaction_ids
    FROM
      asset_transactions
    WHERE
      transaction_id = NEW.id;
  ELSIF (TG_TABLE_NAME = 'accounts') THEN
    SELECT
      ARRAY_AGG(DISTINCT asset_transactions.transaction_id) INTO v_transaction_ids
    FROM
      asset_transactions
      INNER JOIN transactions ON asset_transactions.transaction_id = transactions.id
    WHERE
      transactions.account_id = NEW.id;
  ELSE
    v_transaction_ids := ARRAY[NEW.transaction_id];
  END IF;
  FOR rec IN (
    SELECT
      transactions.id,
      transactions.account_id,
      accounts.is_asset_account
    FROM
      transactions
      INNER JOIN accounts ON transactions.account_id = accounts.id
    WHERE
      transactions.id = ANY (v_transaction_ids))
    LOOP
      IF (rec.is_asset_account = FALSE) THEN
        RAISE EXCEPTION 'Asset Transaction only allowed in Asset Account (for transaction_id % and account_id %).', rec.id, rec.account_id;
      END IF;
    END LOOP;
  RETURN NEW;
END;
$$
LANGUAGE 'plpgsql';

CREATE TRIGGER trg_asset_transactions_account_asset_on_change
  AFTER INSERT OR UPDATE ON asset_transactions
  FOR EACH ROW
  EXECUTE FUNCTION check_asset_transactions_account_asset();

CREATE TRIGGER trg_asset_transactions_account_asset_on_transactions_change
  AFTER UPDATE OF account_id ON transactions
  FOR EACH ROW
  WHEN(OLD.account_id IS DISTINCT FROM NEW.account_id)
  EXECUTE FUNCTION check_asset_transactions_account_asset();

CREATE TRIGGER trg_asset_transactions_account_asset_on_accounts_change
  AFTER UPDATE OF is_asset_account ON accounts
  FOR EACH ROW
  WHEN(OLD.is_asset_account IS DISTINCT FROM NEW.is_asset_account)
  EXECUTE FUNCTION check_asset_transactions_account_asset();

-- ===============================================================
-- Function and triggers to check asset transactions are not also
-- transfers transactions
-- ===============================================================
CREATE OR REPLACE FUNCTION check_asset_transactions_transfers()
  RETURNS TRIGGER
  AS $$
DECLARE
  v_transaction_ids int[];
  DECLARE v_asset_transactions_transfers_count int;
  DECLARE rec RECORD;
BEGIN
  IF (TG_TABLE_NAME = 'transfers') THEN
    SELECT
      ARRAY_AGG(DISTINCT transaction_id) INTO v_transaction_ids
    FROM
      asset_transactions
    WHERE
      transaction_id IN (NEW.from_transaction_id, NEW.to_transaction_id)
    ELSE
      v_transaction_ids := ARRAY[NEW.transaction_id];
  END IF;
  FOR rec IN (
    SELECT
      from_transaction_id,
      to_transaction_id
    FROM
      transfers
    WHERE
      from_transaction_id IN (v_transaction_id)
      OR to_transaction_id IN (v_transaction_id))
    LOOP
      RAISE EXCEPTION 'Asset transaction can not be Transferred transaction (from transaction_id % to transaction_id %).', rec.from_transaction_id, rec.to_transaction_id;
    END LOOP;
  RETURN NEW;
END;
$$
LANGUAGE 'plpgsql';

CREATE TRIGGER trg_asset_transactions_transfers_on_change
  AFTER INSERT OR UPDATE ON asset_transactions
  FOR EACH ROW
  EXECUTE FUNCTION check_asset_transactions_transfers();

CREATE TRIGGER trg_asset_transactions_transfers_on_transfers_change
  AFTER INSERT OR UPDATE ON transfers
  FOR EACH ROW
  EXECUTE FUNCTION check_asset_transactions_transfers();

-- ===============================================================
-- Function and triggers to check asset transactions amounts
-- ===============================================================
CREATE OR REPLACE FUNCTION check_asset_transactions_amount()
  RETURNS TRIGGER
  AS $$
DECLARE
  v_transaction_ids int[];
  DECLARE v_transaction_id int;
  DECLARE v_asset_transactions_sum numeric(18, 2);
  DECLARE v_transactions_amount numeric(18, 2);
BEGIN
  IF (TG_TABLE_NAME = 'transactions') THEN
    SELECT
      ARRAY_AGG(DISTINCT transaction_id) INTO v_transaction_ids
    FROM
      asset_transactions
    WHERE
      transaction_id IN (NEW.id);
  ELSE
    SELECT
      ARRAY_AGG(DISTINCT transaction_id) INTO v_transaction_ids
    FROM
      asset_transactions
    WHERE
      transaction_id IN (NEW.transaction_id, OLD.transaction_id);
  END IF;
  IF (v_transaction_ids IS NOT NULL) THEN
    FOREACH v_transaction_id IN ARRAY v_transaction_ids LOOP
      SELECT
        CAST(COALESCE(ROUND(SUM((quantity * price_per_unit / exchange_rate) + fee), 2), 0) AS NUMERIC(18, 2)) INTO v_asset_transactions_sum
      FROM
        asset_transactions
      WHERE
        transaction_id = v_transaction_id;
      SELECT
        amount INTO v_transactions_amount
      FROM
        transactions
      WHERE
        id = v_transaction_id;
      IF ((v_transactions_amount - v_asset_transactions_sum) <> 0) THEN
        RAISE EXCEPTION 'Asset transactions sum (%) does not equal the transaction amount (%) for transaction_id %.', v_asset_transactions_sum, v_transactions_amount, v_transaction_id;
      END IF;
    END LOOP;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$
LANGUAGE 'plpgsql';

CREATE CONSTRAINT TRIGGER trg_asset_transactions_amount_on_change
  AFTER INSERT OR UPDATE OR DELETE ON asset_transactions DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  EXECUTE FUNCTION check_asset_transactions_amount();

CREATE CONSTRAINT TRIGGER trg_asset_transactions_amount_on_transactions_change
  AFTER UPDATE OF amount ON transactions DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  WHEN(OLD.amount IS DISTINCT FROM NEW.amount)
  EXECUTE FUNCTION check_asset_transactions_amount();

-- ===============================================================
-- Function and triggers to check asset transactions ledger
-- consistency
-- ===============================================================
CREATE OR REPLACE FUNCTION check_asset_transactions_ledger()
  RETURNS TRIGGER
  AS $$
DECLARE
  v_transaction_ids int[];
  DECLARE v_asset_ids int[];
  DECLARE v_ledger_count int;
  DECLARE rec RECORD;
BEGIN
  IF (TG_TABLE_NAME = 'transactions') THEN
    SELECT
      ARRAY_AGG(DISTINCT transaction_id),
      ARRAY_AGG(DISTINCT asset_id) INTO v_transaction_ids,
      v_asset_ids
    FROM
      asset_transactions
    WHERE
      transaction_id = NEW.id;
  ELSIF (TG_TABLE_NAME = 'accounts') THEN
    SELECT
      ARRAY_AGG(DISTINCT asset_transactions.transaction_id),
      ARRAY_AGG(DISTINCT asset_transactions.asset_id) INTO v_transaction_ids,
      v_asset_ids
    FROM
      asset_transactions
      INNER JOIN transactions ON asset_transactions.transaction_id = transactions.id
    WHERE
      transactions.account_id = NEW.id;
  ELSIF (TG_TABLE_NAME = 'assets') THEN
    SELECT
      ARRAY_AGG(DISTINCT transaction_id),
      ARRAY_AGG(DISTINCT asset_id) INTO v_transaction_ids,
      v_asset_ids
    FROM
      asset_transactions
    WHERE
      asset_id = NEW.id;
  ELSE
    v_transaction_ids := ARRAY[NEW.transaction_id];
    v_asset_ids := ARRAY[NEW.asset_id];
  END IF;
  FOR rec IN (
    SELECT
      transaction_id,
      asset_id
    FROM
      asset_transactions
    WHERE
      transaction_id = ANY (v_transaction_ids)
      AND asset_id = ANY (v_asset_ids))
    LOOP
      SELECT
        COUNT(DISTINCT ledger_id) INTO v_ledger_count
      FROM (
        SELECT
          accounts.ledger_id
        FROM
          transactions
          INNER JOIN accounts ON transactions.account_id = accounts.id
        WHERE
          transactions.id = rec.transaction_id
        UNION ALL
        SELECT
          assets.ledger_id
        FROM
          assets
        WHERE
          assets.id = rec.asset_id);
      IF (v_ledger_count > 1) THEN
        RAISE EXCEPTION 'Asset transactions asset can only be associated with account transaction from the same ledger (for transaction_id % and asset_id %).', rec.transaction_id, rec.asset_id;
      END IF;
    END LOOP;
  RETURN NEW;
END;
$$
LANGUAGE 'plpgsql';

CREATE CONSTRAINT TRIGGER trg_asset_transactions_ledger_on_change
  AFTER INSERT OR UPDATE ON asset_transactions DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  EXECUTE FUNCTION check_asset_transactions_ledger();

CREATE CONSTRAINT TRIGGER trg_asset_transactions_ledger_on_transactions_change
  AFTER UPDATE OF account_id ON transactions DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  WHEN(OLD.account_id IS DISTINCT FROM NEW.account_id)
  EXECUTE FUNCTION check_asset_transactions_ledger();

CREATE CONSTRAINT TRIGGER trg_asset_transactions_ledger_on_accounts_change
  AFTER UPDATE OF ledger_id ON accounts DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  WHEN(OLD.ledger_id IS DISTINCT FROM NEW.ledger_id)
  EXECUTE FUNCTION check_asset_transactions_ledger();

CREATE CONSTRAINT TRIGGER trg_asset_transactions_ledger_on_assets_change
  AFTER UPDATE OF ledger_id ON assets DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  WHEN(OLD.ledger_id IS DISTINCT FROM NEW.ledger_id)
  EXECUTE FUNCTION check_asset_transactions_ledger();

-- ===============================================================
-- Function and triggers to check categorized transactions in
-- on budget account
-- ===============================================================
CREATE OR REPLACE FUNCTION check_transactions_cleared()
  RETURNS TRIGGER
  AS $$
DECLARE
  v_transaction_ids int[];
  DECLARE rec RECORD;
BEGIN
  IF (TG_TABLE_NAME = 'category_transactions') THEN
    SELECT
      ARRAY_AGG(DISTINCT id) INTO v_transaction_ids
    FROM
      transactions
    WHERE
      id IN (NEW.transaction_id, OLD.transaction_id)
      AND transactions.cleared = TRUE;
  ELSIF (TG_TABLE_NAME = 'payee_transactions') THEN
    SELECT
      ARRAY_AGG(DISTINCT id) INTO v_transaction_ids
    FROM
      transactions
    WHERE
      id IN (NEW.transaction_id, OLD.transaction_id)
      AND transactions.cleared = TRUE;
  ELSIF (TG_TABLE_NAME = 'asset_transactions') THEN
    SELECT
      ARRAY_AGG(DISTINCT id) INTO v_transaction_ids
    FROM
      transactions
    WHERE
      id IN (NEW.transaction_id, OLD.transaction_id)
      AND transactions.cleared = TRUE;
  ELSIF (TG_TABLE_NAME = 'transfers') THEN
    SELECT
      ARRAY_AGG(DISTINCT id) INTO v_transaction_ids
    FROM
      transactions
    WHERE
      id IN (NEW.from_transaction_id, OLD.from_transaction_id, NEW.to_transaction_id, OLD.to_transaction_id)
      AND transactions.cleared = TRUE;
  ELSIF (TG_TABLE_NAME = 'accounts') THEN
    SELECT
      ARRAY_AGG(DISTINCT id) INTO v_transaction_ids
    FROM
      transactions
    WHERE
      account_id = NEW.id
      AND transactions.cleared = TRUE;
  ELSIF (TG_TABLE_NAME = 'account_types') THEN
    SELECT
      ARRAY_AGG(DISTINCT transactions.id) INTO v_transaction_ids
    FROM
      transactions
      INNER JOIN accounts ON transactions.account_id = accounts.id
    WHERE
      accounts.account_type_id = NEW.id
      AND transactions.cleared = TRUE;
  ELSE
    IF (NEW.cleared = TRUE) THEN
      v_transaction_ids := ARRAY[NEW.transaction_id];
    END IF;
  END IF;
  FOR rec IN (
    SELECT
      transactions.id,
      account_types.on_budget_account,
      category_transactions.transaction_id category_transaction_id,
      payee_transactions.transaction_id payee_transaction_id,
      asset_transactions.transaction_id asset_transaction_id,
      transfers.from_transaction_id transfer_transaction_id
    FROM
      transactions
      INNER JOIN accounts ON transactions.account_id = accounts.id
      INNER JOIN account_types ON accounts.account_type_id = account_types.id
      LEFT JOIN category_transactions ON transactions.id = category_transactions.transaction_id
      LEFT JOIN payee_transactions ON transactions.id = payee_transactions.transaction_id
      LEFT JOIN asset_transactions ON transactions.id = asset_transactions.transaction_id
      LEFT JOIN transfers ON transactions.id = transfers.from_transaction_id
        OR transactions.id = transfers.to_transaction_id
    WHERE
      transactions.id = ANY (v_transaction_ids))
    LOOP
      IF (rec.on_budget_account = TRUE AND rec.category_transaction_id IS NULL) THEN
        RAISE EXCEPTION 'Transactions on budget accounts need to be categorized to be cleared (for transaction_id %).', rec.id;
      ELSIF (rec.transfer_transaction_id IS NULL
          AND rec.payee_transaction_id IS NULL) THEN
        RAISE EXCEPTION 'Transactions that are not transfers need to have a payee to be cleared (for transaction_id %).', rec.id;
      ELSIF (rec.on_budget_account = FALSE
          AND rec.transfer_transaction_id IS NULL
          AND rec.asset_transaction_id IS NULL) THEN
        RAISE EXCEPTION 'Transactions off budget accounts need to be a transfer or an asset transaction (for transaction_id %).', rec.id;
      END IF;
    END LOOP;
  RETURN NEW;
END;
$$
LANGUAGE 'plpgsql';

CREATE CONSTRAINT TRIGGER trg_transactions_cleared_on_change
  AFTER INSERT OR UPDATE ON transactions DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  EXECUTE FUNCTION check_transactions_cleared();

CREATE CONSTRAINT TRIGGER trg_transactions_cleared_on_category_transactions_change
  AFTER INSERT OR UPDATE OR DELETE ON category_transactions DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  EXECUTE FUNCTION check_transactions_cleared();

CREATE CONSTRAINT TRIGGER trg_transactions_cleared_on_payee_transactions_change
  AFTER INSERT OR UPDATE OR DELETE ON payee_transactions DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  EXECUTE FUNCTION check_transactions_cleared();

CREATE CONSTRAINT TRIGGER trg_transactions_cleared_on_transfers_change
  AFTER INSERT OR UPDATE OR DELETE transfers DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  EXECUTE FUNCTION check_transactions_cleared();

CREATE CONSTRAINT TRIGGER trg_transactions_cleared_on_asset_transactions_change
  AFTER INSERT OR UPDATE OR DELETE ON asset_transactions DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  EXECUTE FUNCTION check_transactions_cleared();

CREATE TRIGGER trg_transactions_cleared_on_accounts_change
  AFTER UPDATE OF account_type_id ON accounts
  FOR EACH ROW
  WHEN(OLD.account_type_id IS DISTINCT FROM NEW.account_type_id)
  EXECUTE FUNCTION check_transactions_cleared();

CREATE TRIGGER trg_transactions_cleared_on_account_types_change
  AFTER UPDATE OF on_budget_account ON account_types
  FOR EACH ROW
  WHEN(OLD.on_budget_account IS DISTINCT FROM NEW.on_budget_account)
  EXECUTE FUNCTION check_transactions_cleared();

-- ===============================================================
-- Function and triggers to check categorized budget ledger
-- consistency
-- ===============================================================
CREATE OR REPLACE FUNCTION check_category_budgets_ledger()
  RETURNS TRIGGER
  AS $$
DECLARE
  v_budget_ids int[];
  DECLARE v_category_ids int[];
  DECLARE v_ledger_count int;
  DECLARE rec RECORD;
BEGIN
  IF (TG_TABLE_NAME = 'budgets') THEN
    SELECT
      ARRAY_AGG(DISTINCT budget_id),
      ARRAY_AGG(DISTINCT category_id) INTO v_budget_ids,
      v_category_ids
    FROM
      category_budgets
    WHERE
      budget_id = NEW.id;
  ELSIF (TG_TABLE_NAME = 'categories') THEN
    SELECT
      ARRAY_AGG(DISTINCT budget_id),
      ARRAY_AGG(DISTINCT category_id) INTO v_budget_ids,
      v_category_ids
    FROM
      category_budgets
    WHERE
      category_id = NEW.id;
  ELSIF (TG_TABLE_NAME = 'category_groups') THEN
    SELECT
      ARRAY_AGG(DISTINCT category_budgets.budget_id),
      ARRAY_AGG(DISTINCT category_budgets.category_id) INTO v_budget_ids,
      v_category_ids
    FROM
      category_budgets
      INNER JOIN categories ON category_budgets.category_id = categories.id
    WHERE
      categories.category_group_id = NEW.id;
  ELSE
    v_budget_ids := ARRAY[NEW.budget_id];
    v_category_ids := ARRAY[NEW.category_id];
  END IF;
  FOR rec IN (
    SELECT
      budget_id,
      category_id
    FROM
      category_budgets
    WHERE
      budget_id = ANY (v_budget_ids)
      AND category_id = ANY (v_category_ids))
    LOOP
      SELECT
        COUNT(DISTINCT ledger_id) INTO v_ledger_count
      FROM (
        SELECT
          budgets.ledger_id
        FROM
          budgets
        WHERE
          budgets.id = rec.budget_id
        UNION ALL
        SELECT
          category_groups.ledger_id
        FROM
          categories
          INNER JOIN category_groups ON categories.category_group_id = category_groups.id
        WHERE
          categories.id = rec.category_id);
      IF (v_ledger_count > 1) THEN
        RAISE EXCEPTION 'Categorized budgets budget can only be associated with categories from the same ledger (for budget_id % and category_id %).', rec.budget_id, rec.category_id;
      END IF;
    END LOOP;
  RETURN NEW;
END;
$$
LANGUAGE 'plpgsql';

CREATE CONSTRAINT TRIGGER trg_category_budgets_ledger_on_change
  AFTER INSERT OR UPDATE ON category_budgets DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  EXECUTE FUNCTION check_category_budgets_ledger();

CREATE CONSTRAINT TRIGGER trg_category_budgets_ledger_on_budgets_change
  AFTER UPDATE OF ledger_id ON budgets DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  WHEN(OLD.ledger_id IS DISTINCT FROM NEW.ledger_id)
  EXECUTE FUNCTION check_category_budgets_ledger();

CREATE CONSTRAINT TRIGGER trg_category_budgets_ledger_on_categories_change
  AFTER UPDATE OF category_group_id ON categories DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  WHEN(OLD.category_group_id IS DISTINCT FROM NEW.category_group_id)
  EXECUTE FUNCTION check_category_budgets_ledger();

CREATE CONSTRAINT TRIGGER trg_category_budgets_ledger_on_category_groups_change
  AFTER UPDATE OF ledger_id ON category_groups DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  WHEN(OLD.ledger_id IS DISTINCT FROM NEW.ledger_id)
  EXECUTE FUNCTION check_category_budgets_ledger();

