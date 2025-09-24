-- ====================================
-- LTI (Ledger-To-Invest) App Database Schema
-- PostgreSQL Implementation
-- ====================================
-- Drop Database
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

DROP FUNCTION IF EXISTS check_asset_transactions_ledger;

DROP FUNCTION IF EXISTS check_asset_transactions_amount;

DROP FUNCTION IF EXISTS check_asset_transactions_account_asset;

DROP FUNCTION IF EXISTS check_transfers_ledger;

DROP FUNCTION IF EXISTS check_transfers_categorization;

DROP FUNCTION IF EXISTS check_transfers_amounts;

DROP FUNCTION IF EXISTS check_transfers_between_accounts;

DROP FUNCTION IF EXISTS check_transfers_without_payee;

DROP FUNCTION IF EXISTS check_payee_transactions_ledger;

DROP FUNCTION IF EXISTS check_category_transactions_ledger;

DROP FUNCTION IF EXISTS check_category_transactions_amount;

DROP FUNCTION IF EXISTS check_goal_type_has_date_goal_month;

DROP FUNCTION IF EXISTS check_goal_month_goal_type_has_date;

DROP FUNCTION IF EXISTS check_account_type_can_invest_account_asset;

DROP FUNCTION IF EXISTS check_account_asset_account_type_can_invest;

DROP FUNCTION IF EXISTS update_updated_at_column;

-- ====================================
-- USER MANAGEMENT
-- ====================================
CREATE TABLE IF NOT EXISTS
    date_formats (
        id SERIAL PRIMARY KEY,
        tag VARCHAR(50) UNIQUE NOT NULL,
        detail TEXT NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    );

CREATE TABLE IF NOT EXISTS
    currencies (
        id SERIAL PRIMARY KEY,
        code VARCHAR(3) UNIQUE NOT NULL,
        detail TEXT NOT NULL,
        symbol VARCHAR(3) NOT NULL,
        on_left BOOLEAN NOT NULL,
        breaking_space BOOLEAN NOT NULL,
        fractional_separator VARCHAR(1) NOT NULL,
        thousand_separator VARCHAR(1) NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    );

CREATE TABLE IF NOT EXISTS
    currency_exchange_rates (
        from_currency_id INTEGER NOT NULL,
        to_currency_id INTEGER NOT NULL,
        date DATE NOT NULL,
        rate NUMERIC(18, 6) NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (from_currency_id, to_currency_id, date),
        FOREIGN KEY (from_currency_id) REFERENCES currencies (id),
        FOREIGN KEY (to_currency_id) REFERENCES currencies (id),
        CONSTRAINT check_different_currencies CHECK (from_currency_id <> to_currency_id)
    );

CREATE TABLE IF NOT EXISTS
    users (
        id SERIAL PRIMARY KEY,
        username VARCHAR(255) UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        first_name VARCHAR(255) NOT NULL,
        last_name VARCHAR(255) NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        email_active BOOLEAN NOT NULL DEFAULT FALSE,
        is_active BOOLEAN NOT NULL DEFAULT TRUE,
        has_privileges BOOLEAN NOT NULL DEFAULT FALSE,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    );

-- ====================================
-- BUDGET STRUCTURE
-- ====================================
CREATE TABLE IF NOT EXISTS
    ledgers (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL,
        tag VARCHAR(255) NOT NULL,
        date_format_id INTEGER NOT NULL,
        currency_id INTEGER NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (date_format_id) REFERENCES date_formats (id),
        FOREIGN KEY (currency_id) REFERENCES currencies (id),
        UNIQUE (user_id, tag)
    );

-- ====================================
-- ACCOUNT MANAGEMENT
-- ====================================
CREATE TABLE IF NOT EXISTS
    account_types (
        id SERIAL PRIMARY KEY,
        tag VARCHAR(50) UNIQUE NOT NULL,
        detail TEXT NOT NULL,
        on_budget_account BOOLEAN NOT NULL DEFAULT TRUE,
        can_invest BOOLEAN NOT NULL DEFAULT FALSE,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT check_can_invest CHECK (
            NOT (
                can_invest AND
                on_budget_account
            )
        )
    );

CREATE TABLE IF NOT EXISTS
    accounts (
        id SERIAL PRIMARY KEY,
        ledger_id INTEGER NOT NULL,
        tag VARCHAR(50) NOT NULL,
        account_type_id INTEGER NOT NULL,
        currency_id INTEGER NOT NULL,
        is_asset_account BOOLEAN NOT NULL DEFAULT FALSE,
        is_closed BOOLEAN NOT NULL DEFAULT FALSE,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (ledger_id) REFERENCES ledgers (id) ON DELETE CASCADE,
        FOREIGN KEY (account_type_id) REFERENCES account_types (id),
        FOREIGN KEY (currency_id) REFERENCES currencies (id),
        UNIQUE (ledger_id, tag)
    );

-- ====================================
-- INVESTMENT TRACKING
-- ====================================
CREATE TABLE IF NOT EXISTS
    asset_types (
        id SERIAL PRIMARY KEY,
        tag VARCHAR(50) UNIQUE NOT NULL,
        detail TEXT NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    );

CREATE TABLE IF NOT EXISTS
    assets (
        id SERIAL PRIMARY KEY,
        ledger_id INTEGER NOT NULL,
        symbol VARCHAR(20) NOT NULL,
        tag VARCHAR(255) NOT NULL,
        asset_type_id INTEGER NOT NULL,
        currency_id INTEGER NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (ledger_id) REFERENCES ledgers (id) ON DELETE CASCADE,
        FOREIGN KEY (asset_type_id) REFERENCES asset_types (id),
        FOREIGN KEY (currency_id) REFERENCES currencies (id),
        UNIQUE (ledger_id, symbol),
        UNIQUE (ledger_id, tag)
    );

CREATE TABLE IF NOT EXISTS
    asset_prices (
        asset_id INTEGER NOT NULL,
        date DATE NOT NULL,
        price NUMERIC(18, 6) NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (asset_id, date),
        FOREIGN KEY (asset_id) REFERENCES assets (id) ON DELETE CASCADE
    );

-- ====================================
-- CATEGORY MANAGEMENT
-- ====================================
CREATE TABLE IF NOT EXISTS
    category_groups (
        id SERIAL PRIMARY KEY,
        ledger_id INTEGER NOT NULL,
        tag VARCHAR(255) NOT NULL,
        sort_order INTEGER NOT NULL,
        is_system BOOLEAN NOT NULL DEFAULT FALSE,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (ledger_id) REFERENCES ledgers (id) ON DELETE CASCADE,
        UNIQUE (ledger_id, tag),
        UNIQUE (ledger_id, sort_order)
    );

CREATE TABLE IF NOT EXISTS
    categories (
        id SERIAL PRIMARY KEY,
        category_group_id INTEGER NOT NULL,
        tag VARCHAR(255) NOT NULL,
        sort_order INTEGER NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (category_group_id) REFERENCES category_groups (id) ON DELETE CASCADE,
        UNIQUE (category_group_id, tag),
        UNIQUE (category_group_id, sort_order)
    );

-- ====================================
-- GOALS
-- ====================================
CREATE TABLE IF NOT EXISTS
    goal_types (
        id SERIAL PRIMARY KEY,
        tag VARCHAR(50) UNIQUE NOT NULL,
        detail TEXT NOT NULL,
        has_date BOOLEAN NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    );

CREATE TABLE IF NOT EXISTS
    goals (
        category_id INTEGER PRIMARY KEY,
        goal_type_id INTEGER NOT NULL,
        goal_amount NUMERIC(18, 2) NOT NULL,
        goal_month DATE,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE,
        FOREIGN KEY (goal_type_id) REFERENCES goal_types (id),
        CONSTRAINT check_goal_date_first_of_month CHECK (
            goal_month IS NULL OR
            EXTRACT(
                DAY
                FROM
                    goal_month
            ) = 1
        ),
        CONSTRAINT check_goal_amount_positive CHECK (goal_amount > 0)
    );

-- ====================================
-- PAYEES
-- ====================================
CREATE TABLE IF NOT EXISTS
    payees (
        id SERIAL PRIMARY KEY,
        ledger_id INTEGER NOT NULL,
        tag VARCHAR(255) NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (ledger_id) REFERENCES ledgers (id) ON DELETE CASCADE,
        UNIQUE (ledger_id, tag)
    );

-- ====================================
-- TRANSACTIONS
-- ====================================
CREATE TABLE IF NOT EXISTS
    transactions (
        id SERIAL PRIMARY KEY,
        account_id INTEGER NOT NULL,
        date DATE NOT NULL,
        amount NUMERIC(18, 2) NOT NULL,
        memo TEXT,
        cleared BOOLEAN NOT NULL DEFAULT FALSE,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE,
        CONSTRAINT check_transactions_amount_zero CHECK (amount <> 0)
    );

CREATE TABLE IF NOT EXISTS
    payee_transactions (
        transaction_id INTEGER PRIMARY KEY,
        payee_id INTEGER NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE,
        FOREIGN KEY (payee_id) REFERENCES payees (id) ON DELETE CASCADE
    );

CREATE TABLE IF NOT EXISTS
    category_transactions (
        transaction_id INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        amount NUMERIC(18, 2) NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (transaction_id, category_id),
        FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE,
        CONSTRAINT check_category_transactions_amount_zero CHECK (amount <> 0)
    );

-- ====================================
-- TRANSFERS
-- ====================================
CREATE TABLE IF NOT EXISTS
    transfers (
        from_transaction_id INTEGER UNIQUE NOT NULL,
        to_transaction_id INTEGER UNIQUE NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (from_transaction_id, to_transaction_id),
        FOREIGN KEY (from_transaction_id) REFERENCES transactions (id) ON DELETE CASCADE,
        FOREIGN KEY (to_transaction_id) REFERENCES transactions (id) ON DELETE CASCADE,
        CONSTRAINT check_different_transactions CHECK (from_transaction_id <> to_transaction_id)
    );

-- ====================================
-- ASSET TRANSACTIONS
-- ====================================
CREATE TABLE IF NOT EXISTS
    asset_transactions (
        transaction_id INTEGER NOT NULL,
        asset_id INTEGER NOT NULL,
        quantity NUMERIC(18, 8) NOT NULL,
        price_per_unit NUMERIC(18, 6) NOT NULL,
        exchange_rate NUMERIC(18, 6) NOT NULL DEFAULT 1,
        fee NUMERIC(18, 2) NOT NULL DEFAULT 0,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (transaction_id, asset_id),
        FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE,
        FOREIGN KEY (asset_id) REFERENCES assets (id)
    );

-- ====================================
-- BUDGET TRACKING
-- ====================================
CREATE TABLE IF NOT EXISTS
    budgets (
        id SERIAL PRIMARY KEY,
        ledger_id INTEGER NOT NULL,
        budget_month DATE NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (ledger_id) REFERENCES ledgers (id) ON DELETE CASCADE,
        UNIQUE (ledger_id, budget_month),
        CONSTRAINT check_month_first_day CHECK (
            EXTRACT(
                DAY
                FROM
                    budget_month
            ) = 1
        )
    );

CREATE TABLE IF NOT EXISTS
    category_budgets (
        budget_id INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        budgeted_amount NUMERIC(19, 2) NOT NULL DEFAULT 0,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (budget_id, category_id),
        FOREIGN KEY (budget_id) REFERENCES budgets (id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
    );

-- ====================================
-- INDEXES FOR PERFORMANCE
-- ====================================
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

-- ====================================
-- FUNCTIONS AND TRIGGERS
-- ====================================
-- Function to update the updated_at timestamp
CREATE OR
REPLACE FUNCTION update_updated_at_column () RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

-- Create triggers for updated_at columns
CREATE TRIGGER update_date_formats_updated_at BEFORE
UPDATE ON date_formats FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column ();

CREATE TRIGGER update_currencies_updated_at BEFORE
UPDATE ON currencies FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column ();

CREATE TRIGGER update_currency_exchange_rates_updated_at BEFORE
UPDATE ON currency_exchange_rates FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column ();

CREATE TRIGGER update_users_updated_at BEFORE
UPDATE ON users FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column ();

CREATE TRIGGER update_ledgers_updated_at BEFORE
UPDATE ON ledgers FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column ();

CREATE TRIGGER update_account_types_updated_at BEFORE
UPDATE ON account_types FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column ();

CREATE TRIGGER update_accounts_updated_at BEFORE
UPDATE ON accounts FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column ();

CREATE TRIGGER update_asset_types_updated_at BEFORE
UPDATE ON asset_types FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column ();

CREATE TRIGGER update_assets_updated_at BEFORE
UPDATE ON assets FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column ();

CREATE TRIGGER update_asset_prices_updated_at BEFORE
UPDATE ON asset_prices FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column ();

CREATE TRIGGER update_category_groups_updated_at BEFORE
UPDATE ON category_groups FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column ();

CREATE TRIGGER update_categories_updated_at BEFORE
UPDATE ON categories FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column ();

CREATE TRIGGER update_goal_types_updated_at BEFORE
UPDATE ON goal_types FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column ();

CREATE TRIGGER update_goals_updated_at BEFORE
UPDATE ON goals FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column ();

CREATE TRIGGER update_payees_updated_at BEFORE
UPDATE ON payees FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column ();

CREATE TRIGGER update_transactions_updated_at BEFORE
UPDATE ON transactions FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column ();

CREATE TRIGGER update_payee_transactions_updated_at BEFORE
UPDATE ON payee_transactions FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column ();

CREATE TRIGGER update_category_transactions_updated_at BEFORE
UPDATE ON category_transactions FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column ();

CREATE TRIGGER update_transfers_updated_at BEFORE
UPDATE ON transfers FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column ();

CREATE TRIGGER update_asset_transactions_updated_at BEFORE
UPDATE ON asset_transactions FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column ();

CREATE TRIGGER update_budgets_updated_at BEFORE
UPDATE ON budgets FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column ();

CREATE TRIGGER update_category_budgets_updated_at BEFORE
UPDATE ON category_budgets FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column ();

-- Create Function and trigger to check if the account can be an asset account based of the account type
CREATE OR
REPLACE FUNCTION check_account_asset_account_type_can_invest () RETURNS TRIGGER AS $$
DECLARE v_account_type_can_invest BOOLEAN; 
BEGIN

    IF (NEW.is_asset_account = TRUE) THEN

        SELECT can_invest INTO v_account_type_can_invest
        FROM account_types
        WHERE id = NEW.account_type_id;

        IF (v_account_type_can_invest = FALSE) THEN
            RAISE EXCEPTION 'Account `%` can not be an asset account since it is not an invest account type.', NEW.tag;
        END IF;

    END IF;

    RETURN NEW;

END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_account_asset_account_type_can_invest_on_change BEFORE INSERT OR
UPDATE ON accounts FOR EACH ROW
EXECUTE FUNCTION check_account_asset_account_type_can_invest ();

-- Create Function and trigger to check if the account type can be modified based on the account associaded
CREATE OR
REPLACE FUNCTION check_account_type_can_invest_account_asset () RETURNS TRIGGER AS $$
DECLARE v_account_asset_count INT; 
BEGIN

    IF (NEW.can_invest = FALSE) THEN

        SELECT COUNT(*) INTO v_account_asset_count
        FROM accounts
        WHERE account_type_id = NEW.id AND is_asset_account = TRUE;

        IF (v_account_asset_count > 0) THEN
            RAISE EXCEPTION 'Account type `%` can not be a non investment account since it already has asset account(s) associated.', NEW.tag;
        END IF;

    END IF;

    RETURN NEW;

END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_account_type_can_invest_account_asset_on_change
AFTER
UPDATE OF can_invest ON account_types FOR EACH ROW WHEN (
    OLD.can_invest IS DISTINCT
    FROM
        NEW.can_invest
)
EXECUTE FUNCTION check_account_type_can_invest_account_asset ();

-- Create Function and trigger to check if the goal should have a month based of the goal type
CREATE OR
REPLACE FUNCTION check_goal_month_goal_type_has_date () RETURNS TRIGGER AS $$
DECLARE v_goal_type_has_date BOOLEAN; 
BEGIN

    IF (NEW.goal_month IS NULL) THEN

        SELECT has_date INTO v_goal_type_has_date
        FROM goal_types
        WHERE id = NEW.goal_type_id;
    
        IF (v_goal_type_has_date = TRUE) THEN
            RAISE EXCEPTION 'Goal for Category Id `%` needs to be have a month associated since it is goal type based on a date.', NEW.category_id;
        END IF;

    END IF;

    RETURN NEW;

END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_goal_month_goal_type_has_date_on_change BEFORE INSERT OR
UPDATE ON goals FOR EACH ROW
EXECUTE FUNCTION check_goal_month_goal_type_has_date ();

-- Create Function and trigger to check if the goal type can be modified based on the goals associaded
CREATE OR
REPLACE FUNCTION check_goal_type_has_date_goal_month () RETURNS TRIGGER AS $$
DECLARE v_goal_month_count INT; 
BEGIN

    IF (NEW.has_date = TRUE) THEN

        SELECT COUNT(*) INTO v_goal_month_count
        FROM goals
        WHERE goal_type_id = NEW.id AND goal_month IS NULL;

        IF (v_goal_month_count > 0) THEN
            RAISE EXCEPTION 'Goal type `%` can not be a goal based on date since it has goals without month associated.', NEW.tag;
        END IF;

    END IF;

    RETURN NEW;

END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_goal_type_has_date_goal_month_on_change
AFTER
UPDATE OF has_date ON goal_types FOR EACH ROW WHEN (
    OLD.has_date IS DISTINCT
    FROM
        NEW.has_date
)
EXECUTE FUNCTION check_goal_type_has_date_goal_month ();

-- Create Function and trigger to check Categorized transactions in on_budget_account
CREATE OR
REPLACE FUNCTION check_category_transactions_on_budget_account () RETURNS TRIGGER AS $$
DECLARE v_transaction_ids INT[];
DECLARE rec RECORD;
BEGIN
   
    IF (TG_TABLE_NAME = 'transactions') THEN
        SELECT ARRAY_AGG(DISTINCT transaction_id) INTO v_transaction_ids
        FROM category_transactions
        WHERE transaction_id = NEW.id;
    ELSIF (TG_TABLE_NAME = 'accounts') THEN
        SELECT ARRAY_AGG(DISTINCT category_transactions.transaction_id) INTO v_transaction_ids
        FROM category_transactions
        INNER JOIN transactions
        ON category_transactions.transaction_id = transactions.id
        WHERE transactions.account_id = NEW.id;
    ELSIF (TG_TABLE_NAME = 'account_types') THEN
        SELECT ARRAY_AGG(DISTINCT category_transactions.transaction_id) INTO v_transaction_ids
        FROM category_transactions
        INNER JOIN transactions
        ON category_transactions.transaction_id = transactions.id
        INNER JOIN accounts
        ON transactions.account_id = accounts.id
        WHERE accounts.account_type_id = NEW.id;
    ELSE
        v_transaction_ids := ARRAY[NEW.transaction_id];
    END IF;

    FOR rec IN (
        SELECT transactions.id, transactions.account_id, account_types.on_budget_account
        FROM transactions
        INNER JOIN accounts
        ON transactions.account_id = accounts.id
        INNER JOIN account_types
        ON accounts.account_type_id = account_types.id
        WHERE transactions.id = ANY(v_transaction_ids)
        )
    LOOP

        IF (rec.on_budget_account = FALSE) THEN
            RAISE EXCEPTION 'Categorized transactions only allowed in Accounts with on_budget_account (for transaction_id % and account_id %).', rec.id, rec.account_id;
        END IF;

    END LOOP;

    RETURN NEW;

END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_category_transactions_on_budget_account_on_change
AFTER INSERT OR
UPDATE ON category_transactions FOR EACH ROW
EXECUTE FUNCTION check_category_transactions_on_budget_account ();

CREATE TRIGGER trg_category_transactions_on_budget_account_on_transactions_change
AFTER
UPDATE OF account_id ON transactions FOR EACH ROW WHEN (
    OLD.account_id IS DISTINCT
    FROM
        NEW.account_id
)
EXECUTE FUNCTION check_category_transactions_on_budget_account ();

CREATE TRIGGER trg_category_transactions_on_budget_account_on_accounts_change
AFTER
UPDATE OF account_type_id ON accounts FOR EACH ROW WHEN (
    OLD.account_type_id IS DISTINCT
    FROM
        NEW.account_type_id
)
EXECUTE FUNCTION check_category_transactions_on_budget_account ();

CREATE TRIGGER trg_category_transactions_on_budget_account_on_account_types_change
AFTER
UPDATE OF on_budget_account ON account_types FOR EACH ROW WHEN (
    OLD.on_budget_account IS DISTINCT
    FROM
        NEW.on_budget_account
)
EXECUTE FUNCTION check_category_transactions_on_budget_account ();

-- Create Function and trigger to validate Categorized transactions amounts
CREATE OR
REPLACE FUNCTION check_category_transactions_amount () RETURNS TRIGGER AS $$
DECLARE v_transaction_ids INT[];
DECLARE v_transaction_id INT;
DECLARE v_category_transactions_sum NUMERIC(18, 2);
DECLARE v_transactions_amount NUMERIC(18, 2);
BEGIN

    IF (TG_TABLE_NAME = 'transactions') THEN
        SELECT ARRAY_AGG(DISTINCT transaction_id) INTO v_transaction_ids
        FROM category_transactions
        WHERE transaction_id IN (NEW.id);
    ELSE
        SELECT ARRAY_AGG(DISTINCT transaction_id) INTO v_transaction_ids
        FROM category_transactions
        WHERE transaction_id IN (NEW.transaction_id, OLD.transaction_id);
    END IF;

    IF (v_transaction_ids IS NOT NULL) THEN

        FOREACH v_transaction_id IN ARRAY v_transaction_ids
        LOOP

            SELECT COALESCE(SUM(amount), 0) INTO v_category_transactions_sum
            FROM category_transactions
            WHERE transaction_id = v_transaction_id;

            SELECT amount INTO v_transactions_amount
            FROM transactions
            WHERE id = v_transaction_id;

            IF (v_transactions_amount <> v_category_transactions_sum) THEN
                RAISE EXCEPTION 'Categorized transactions sum (%) does not equal the total transaction amount (%) for transaction_id %.', v_category_transactions_sum, v_transactions_amount, v_transaction_id;
            END IF;

        END LOOP;

    END IF;

    RETURN COALESCE(NEW, OLD);

END;
$$ LANGUAGE 'plpgsql';

CREATE CONSTRAINT TRIGGER trg_category_transactions_amount_on_change
AFTER INSERT OR
UPDATE OR
DELETE ON category_transactions DEFERRABLE INITIALLY DEFERRED FOR EACH ROW
EXECUTE FUNCTION check_category_transactions_amount ();

CREATE CONSTRAINT TRIGGER trg_category_transactions_amount_on_transactions_change
AFTER
UPDATE OF amount ON transactions DEFERRABLE INITIALLY DEFERRED FOR EACH ROW WHEN (
    OLD.amount IS DISTINCT
    FROM
        NEW.amount
)
EXECUTE FUNCTION check_category_transactions_amount ();

-- Create Function and trigger to validate Categorized transactions Ledger consistency
CREATE OR
REPLACE FUNCTION check_category_transactions_ledger () RETURNS TRIGGER AS $$
DECLARE v_transaction_ids INT[];
DECLARE v_category_ids INT[];
DECLARE v_ledger_count INT;
DECLARE rec RECORD;
BEGIN
   
    IF (TG_TABLE_NAME = 'transactions') THEN
        SELECT ARRAY_AGG(DISTINCT transaction_id), ARRAY_AGG(DISTINCT category_id) INTO v_transaction_ids, v_category_ids
        FROM category_transactions
        WHERE transaction_id = NEW.id;
    ELSIF (TG_TABLE_NAME = 'accounts') THEN
        SELECT ARRAY_AGG(DISTINCT category_transactions.transaction_id), ARRAY_AGG(DISTINCT category_transactions.category_id) INTO v_transaction_ids, v_category_ids
        FROM category_transactions
        INNER JOIN transactions
        ON category_transactions.transaction_id = transactions.id
        WHERE transactions.account_id = NEW.id;
    ELSIF (TG_TABLE_NAME = 'categories') THEN
        SELECT ARRAY_AGG(DISTINCT transaction_id), ARRAY_AGG(DISTINCT category_id) INTO v_transaction_ids, v_category_ids
        FROM category_transactions
        WHERE category_id = NEW.id;
    ELSIF (TG_TABLE_NAME = 'category_groups') THEN
        SELECT ARRAY_AGG(DISTINCT category_transactions.transaction_id), ARRAY_AGG(DISTINCT category_transactions.category_id) INTO v_transaction_ids, v_category_ids
        FROM category_transactions
        INNER JOIN categories
        ON category_transactions.category_id = categories.id
        WHERE categories.category_group_id = NEW.id;
    ELSE
        v_transaction_ids := ARRAY[NEW.transaction_id];
        v_category_ids := ARRAY[NEW.category_id];
    END IF;

    FOR rec IN (
        SELECT transaction_id, category_id
        FROM category_transactions
        WHERE transaction_id = ANY(v_transaction_ids) AND category_id = ANY(v_category_ids)
        )
    LOOP

        SELECT COUNT(DISTINCT ledger_id) INTO v_ledger_count
        FROM (
            SELECT accounts.ledger_id
            FROM transactions
            INNER JOIN accounts
            ON transactions.account_id = accounts.id
            WHERE transactions.id = rec.transaction_id
            UNION ALL
            SELECT category_groups.ledger_id
            FROM categories
            INNER JOIN category_groups
            ON categories.category_group_id = category_groups.id
            WHERE categories.id = rec.category_id
        );

        IF (v_ledger_count > 1) THEN
            RAISE EXCEPTION 'Categorized transactions category can only be associated with account transaction from the same ledger (for transaction_id % and category_id %).', rec.transaction_id, rec.category_id;
        END IF;

    END LOOP;

    RETURN NEW;

END;
$$ LANGUAGE 'plpgsql';

CREATE CONSTRAINT TRIGGER trg_category_transactions_ledger_on_change
AFTER INSERT OR
UPDATE ON category_transactions DEFERRABLE INITIALLY DEFERRED FOR EACH ROW
EXECUTE FUNCTION check_category_transactions_ledger ();

CREATE CONSTRAINT TRIGGER trg_category_transactions_ledger_on_transactions_change
AFTER
UPDATE OF account_id ON transactions DEFERRABLE INITIALLY DEFERRED FOR EACH ROW WHEN (
    OLD.account_id IS DISTINCT
    FROM
        NEW.account_id
)
EXECUTE FUNCTION check_category_transactions_ledger ();

CREATE CONSTRAINT TRIGGER trg_category_transactions_ledger_on_accounts_change
AFTER
UPDATE OF ledger_id ON accounts DEFERRABLE INITIALLY DEFERRED FOR EACH ROW WHEN (
    OLD.ledger_id IS DISTINCT
    FROM
        NEW.ledger_id
)
EXECUTE FUNCTION check_category_transactions_ledger ();

CREATE CONSTRAINT TRIGGER trg_category_transactions_ledger_on_categories_change
AFTER
UPDATE OF category_group_id ON categories DEFERRABLE INITIALLY DEFERRED FOR EACH ROW WHEN (
    OLD.category_group_id IS DISTINCT
    FROM
        NEW.category_group_id
)
EXECUTE FUNCTION check_category_transactions_ledger ();

CREATE CONSTRAINT TRIGGER trg_category_transactions_ledger_on_category_groups_change
AFTER
UPDATE OF ledger_id ON category_groups DEFERRABLE INITIALLY DEFERRED FOR EACH ROW WHEN (
    OLD.ledger_id IS DISTINCT
    FROM
        NEW.ledger_id
)
EXECUTE FUNCTION check_category_transactions_ledger ();

-- Create Function and trigger to validate Payee transactions Ledger consistency
CREATE OR
REPLACE FUNCTION check_payee_transactions_ledger () RETURNS TRIGGER AS $$
DECLARE v_transaction_ids INT[];
DECLARE v_payee_ids INT[];
DECLARE v_ledger_count INT;
DECLARE rec RECORD;
BEGIN

    IF (TG_TABLE_NAME = 'transactions') THEN
        SELECT ARRAY_AGG(DISTINCT transaction_id), ARRAY_AGG(DISTINCT payee_id) INTO v_transaction_ids, v_payee_ids
        FROM payee_transactions
        WHERE transaction_id = NEW.id;
    ELSIF (TG_TABLE_NAME = 'accounts') THEN
        SELECT ARRAY_AGG(DISTINCT payee_transactions.transaction_id), ARRAY_AGG(DISTINCT payee_transactions.payee_id) INTO v_transaction_ids, v_payee_ids
        FROM payee_transactions
        INNER JOIN transactions
        ON payee_transactions.transaction_id = transactions.id
        WHERE transactions.account_id = NEW.id;
    ELSIF (TG_TABLE_NAME = 'payees') THEN
        SELECT ARRAY_AGG(DISTINCT transaction_id), ARRAY_AGG(DISTINCT payee_id) INTO v_transaction_ids, v_payee_ids
        FROM payee_transactions
        WHERE payee_id = NEW.id;
    ELSE
        v_transaction_ids := ARRAY[NEW.transaction_id];
        v_payee_ids := ARRAY[NEW.payee_id];
    END IF;

    FOR rec IN (
        SELECT transaction_id, payee_id
        FROM payee_transactions
        WHERE transaction_id = ANY(v_transaction_ids) AND payee_id = ANY(v_payee_ids)
        )
    LOOP

        SELECT COUNT(DISTINCT ledger_id) INTO v_ledger_count
        FROM (
            SELECT accounts.ledger_id
            FROM transactions
            INNER JOIN accounts
            ON transactions.account_id = accounts.id
            WHERE transactions.id = rec.transaction_id
            UNION ALL
            SELECT payees.ledger_id
            FROM payees
            WHERE payees.id = rec.payee_id
        );

        IF (v_ledger_count > 1) THEN
            RAISE EXCEPTION 'Payee transactions payee can only be associated with account transaction from the same ledger (for transaction_id % and payee_id %).', rec.transaction_id, rec.payee_id;
        END IF;

    END LOOP;

    RETURN NEW;

END;
$$ LANGUAGE 'plpgsql';

CREATE CONSTRAINT TRIGGER trg_payee_transaction_ledger_on_change
AFTER INSERT OR
UPDATE ON payee_transactions DEFERRABLE INITIALLY DEFERRED FOR EACH ROW
EXECUTE FUNCTION check_payee_transactions_ledger ();

CREATE CONSTRAINT TRIGGER trg_payee_transaction_ledger_on_transactions_change
AFTER
UPDATE OF account_id ON transactions DEFERRABLE INITIALLY DEFERRED FOR EACH ROW WHEN (
    OLD.account_id IS DISTINCT
    FROM
        NEW.account_id
)
EXECUTE FUNCTION check_payee_transactions_ledger ();

CREATE CONSTRAINT TRIGGER trg_payee_transaction_ledger_on_accounts_change
AFTER
UPDATE OF ledger_id ON accounts DEFERRABLE INITIALLY DEFERRED FOR EACH ROW WHEN (
    OLD.ledger_id IS DISTINCT
    FROM
        NEW.ledger_id
)
EXECUTE FUNCTION check_payee_transactions_ledger ();

CREATE CONSTRAINT TRIGGER trg_payee_transaction_ledger_on_payees_change
AFTER
UPDATE OF ledger_id ON payees DEFERRABLE INITIALLY DEFERRED FOR EACH ROW WHEN (
    OLD.ledger_id IS DISTINCT
    FROM
        NEW.ledger_id
)
EXECUTE FUNCTION check_payee_transactions_ledger ();

-- Create Function and trigger to validate Transfer without Payee
CREATE OR
REPLACE FUNCTION check_transfers_without_payee () RETURNS TRIGGER AS $$
DECLARE v_from_transaction_id INT;
DECLARE v_to_transaction_id INT;
DECLARE v_transfers_payee_count INT;
BEGIN

    IF (TG_TABLE_NAME = 'payee_transactions') THEN
        SELECT from_transaction_id, to_transaction_id INTO v_from_transaction_id, v_to_transaction_id
        FROM transfers
        WHERE from_transaction_id = NEW.transaction_id OR to_transaction_id = NEW.transaction_id;
    ELSE
        v_from_transaction_id := NEW.from_transaction_id;
        v_to_transaction_id := NEW.to_transaction_id;
    END IF;

    IF (v_from_transaction_id IS NOT NULL AND v_to_transaction_id IS NOT NULL) THEN

        SELECT COUNT(*) INTO v_transfers_payee_count
        FROM payee_transactions
        WHERE transaction_id IN (v_from_transaction_id, v_to_transaction_id);

        IF (v_transfers_payee_count > 0) THEN
            RAISE EXCEPTION 'Transferred transactions can not have payee associated (from transaction_id % to transaction_id %).', v_from_transaction_id, v_to_transaction_id;
        END IF;

    END IF;

    RETURN NEW;

END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_transfers_without_payee_on_change
AFTER INSERT OR
UPDATE ON transfers FOR EACH ROW
EXECUTE FUNCTION check_transfers_without_payee ();

CREATE TRIGGER trg_transfers_without_payee_on_payee_transactions_change
AFTER INSERT OR
UPDATE ON payee_transactions FOR EACH ROW
EXECUTE FUNCTION check_transfers_without_payee ();

-- Create Function and trigger to validate Transfer between different accounts
CREATE OR
REPLACE FUNCTION check_transfers_between_accounts () RETURNS TRIGGER AS $$
DECLARE v_from_transaction_id INT;
DECLARE v_to_transaction_id INT;
DECLARE v_transfers_account_count INT;
BEGIN

    IF (TG_TABLE_NAME = 'transactions') THEN
        SELECT from_transaction_id, to_transaction_id INTO v_from_transaction_id, v_to_transaction_id
        FROM transfers
        WHERE from_transaction_id = NEW.id OR to_transaction_id = NEW.id;
    ELSE
        v_from_transaction_id := NEW.from_transaction_id;
        v_to_transaction_id := NEW.to_transaction_id;
    END IF;

    IF (v_from_transaction_id IS NOT NULL AND v_to_transaction_id IS NOT NULL) THEN

        SELECT COUNT(DISTINCT account_id) INTO v_transfers_account_count
        FROM transactions
        WHERE id IN (v_from_transaction_id, v_to_transaction_id);

        IF (v_transfers_account_count < 2) THEN
            RAISE EXCEPTION 'Transferred transactions from/to the same account not allowed (from transaction_id % to transaction_id %).', v_from_transaction_id, v_to_transaction_id;
        END IF;

    END IF;

    RETURN NEW;

END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_transfers_between_accounts_on_change
AFTER INSERT OR
UPDATE ON transfers FOR EACH ROW
EXECUTE FUNCTION check_transfers_between_accounts ();

CREATE TRIGGER trg_transfers_between_accounts_on_transactions_change
AFTER
UPDATE OF account_id ON transactions FOR EACH ROW WHEN (
    OLD.account_id IS DISTINCT
    FROM
        NEW.account_id
)
EXECUTE FUNCTION check_transfers_between_accounts ();

-- Create Function and trigger to validate Transfer amounts
CREATE OR
REPLACE FUNCTION check_transfers_amounts () RETURNS TRIGGER AS $$
DECLARE v_from_transaction_id INT;
DECLARE v_to_transaction_id INT;
DECLARE v_transfer_from NUMERIC(18, 2);
DECLARE v_transfer_to NUMERIC(18, 2);
BEGIN

    IF (TG_TABLE_NAME = 'transactions') THEN
        SELECT from_transaction_id, to_transaction_id INTO v_from_transaction_id, v_to_transaction_id
        FROM transfers
        WHERE from_transaction_id = NEW.id OR to_transaction_id = NEW.id;
    ELSE
        v_from_transaction_id := NEW.from_transaction_id;
        v_to_transaction_id := NEW.to_transaction_id;
    END IF;

    IF (v_from_transaction_id IS NOT NULL AND v_to_transaction_id IS NOT NULL) THEN

        SELECT amount INTO v_transfer_from
        FROM transactions
        WHERE id IN (v_from_transaction_id);

        SELECT amount INTO v_transfer_to
        FROM transactions
        WHERE id IN (v_to_transaction_id);

        IF ((v_transfer_to + v_transfer_from) <> 0) THEN
            RAISE EXCEPTION 'Transferred amount does not match (from transaction_id % to transaction_id % mismatch %).', v_from_transaction_id, v_to_transaction_id, (v_transfer_to - v_transfer_from);
        ELSIF(v_transfer_from > 0 OR v_transfer_to < 0) THEN
            RAISE EXCEPTION 'Transferred amount does not match transfer direction (from transaction_id % should be negative and to transaction_id % positive).', v_from_transaction_id, v_to_transaction_id;
        END IF;

    END IF;

    RETURN NEW;

END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_transfers_amounts_on_change
AFTER INSERT OR
UPDATE ON transfers FOR EACH ROW
EXECUTE FUNCTION check_transfers_amounts ();

CREATE TRIGGER trg_transfers_amounts_on_transactions_change
AFTER
UPDATE OF amount ON transactions FOR EACH ROW WHEN (
    OLD.amount IS DISTINCT
    FROM
        NEW.amount
)
EXECUTE FUNCTION check_transfers_amounts ();

-- Create Function and trigger to validate Transfer Categorization consistency
CREATE OR
REPLACE FUNCTION check_transfers_categorization () RETURNS TRIGGER AS $$
DECLARE v_from_transaction_ids INT[];
DECLARE v_to_transaction_ids INT[];
DECLARE v_transfers_category_count_mismatch INT;
DECLARE rec RECORD;
BEGIN

    IF (TG_TABLE_NAME = 'transactions') THEN
        SELECT ARRAY_AGG(DISTINCT from_transaction_id), ARRAY_AGG(DISTINCT to_transaction_id) INTO v_from_transaction_ids, v_to_transaction_ids
        FROM transfers
        WHERE from_transaction_id = NEW.id 
            OR to_transaction_id = NEW.id;
    ELSIF (TG_TABLE_NAME = 'accounts') THEN
        SELECT ARRAY_AGG(DISTINCT transfers.from_transaction_id), ARRAY_AGG(DISTINCT transfers.to_transaction_id) INTO v_from_transaction_ids, v_to_transaction_ids
        FROM transfers
        INNER JOIN transactions
        ON transfers.from_transaction_id = transactions.id
            OR transfers.to_transaction_id = transactions.id
        WHERE transactions.account_id = NEW.id;
    ELSIF (TG_TABLE_NAME = 'account_types') THEN
        SELECT ARRAY_AGG(DISTINCT transfers.from_transaction_id), ARRAY_AGG(DISTINCT transfers.to_transaction_id) INTO v_from_transaction_ids, v_to_transaction_ids
        FROM transfers
        INNER JOIN transactions
        ON transfers.from_transaction_id = transactions.id
            OR transfers.to_transaction_id = transactions.id
        INNER JOIN accounts
        ON transactions.account_id = accounts.id
        WHERE accounts.account_type_id = NEW.id;
    ELSIF (TG_TABLE_NAME = 'category_transactions') THEN
        SELECT ARRAY_AGG(DISTINCT from_transaction_id), ARRAY_AGG(DISTINCT to_transaction_id) INTO v_from_transaction_ids, v_to_transaction_ids
        FROM transfers
        WHERE from_transaction_id IN (NEW.transaction_id, OLD.transaction_id)
            OR to_transaction_id IN (NEW.transaction_id, OLD.transaction_id);
    ELSE
        v_from_transaction_ids := ARRAY[NEW.from_transaction_id];
        v_to_transaction_ids := ARRAY[NEW.to_transaction_id];
    END IF;

    FOR rec IN (
        SELECT transfers.from_transaction_id, transfers.to_transaction_id
        FROM transfers
        INNER JOIN transactions from_transaction
        ON transfers.from_transaction_id = from_transaction.id
        INNER JOIN accounts from_account
        ON from_transaction.account_id = from_account.id
        INNER JOIN account_types from_account_type
        ON from_account.account_type_id = from_account_type.id
        INNER JOIN transactions to_transaction
        ON transfers.to_transaction_id = to_transaction.id
        INNER JOIN accounts to_account
        ON to_transaction.account_id = to_account.id
        INNER JOIN account_types to_account_type
        ON to_account.account_type_id = to_account_type.id
        WHERE transfers.from_transaction_id = ANY(v_from_transaction_ids)
            AND transfers.to_transaction_id = ANY(v_to_transaction_ids)
            AND from_account_type.on_budget_account = TRUE
            AND to_account_type.on_budget_account = TRUE
        )
    LOOP

        SELECT COUNT(*) INTO v_transfers_category_count_mismatch
        FROM (
            SELECT category_id
            FROM category_transactions
            WHERE transaction_id IN (rec.from_transaction_id, rec.to_transaction_id)
            GROUP BY category_id
            HAVING SUM(amount) <> 0
        );

        IF (v_transfers_category_count_mismatch > 0) THEN
            RAISE EXCEPTION 'Transferred transactions should be consistent in categorization (from transaction_id % to transaction_id %).', rec.from_transaction_id, rec.to_transaction_id;
        END IF;

    END LOOP;

    RETURN NEW;

END;
$$ LANGUAGE 'plpgsql';

CREATE CONSTRAINT TRIGGER trg_transfers_categorization_on_change
AFTER INSERT OR
UPDATE ON transfers DEFERRABLE INITIALLY DEFERRED FOR EACH ROW
EXECUTE FUNCTION check_transfers_categorization ();

CREATE CONSTRAINT TRIGGER trg_transfers_categorization_on_category_transactions_update
AFTER INSERT OR
UPDATE OR
DELETE ON category_transactions DEFERRABLE INITIALLY DEFERRED FOR EACH ROW
EXECUTE FUNCTION check_transfers_categorization ();

CREATE TRIGGER trg_transfers_categorization_on_transactions_change
AFTER
UPDATE OF account_id ON transactions FOR EACH ROW WHEN (
    OLD.account_id IS DISTINCT
    FROM
        NEW.account_id
)
EXECUTE FUNCTION check_transfers_categorization ();

CREATE TRIGGER trg_transfers_categorization_on_accounts_change
AFTER
UPDATE OF account_type_id ON accounts FOR EACH ROW WHEN (
    OLD.account_type_id IS DISTINCT
    FROM
        NEW.account_type_id
)
EXECUTE FUNCTION check_transfers_categorization ();

CREATE TRIGGER trg_transfers_categorization_on_account_types_change
AFTER
UPDATE OF on_budget_account ON account_types FOR EACH ROW WHEN (
    OLD.on_budget_account IS DISTINCT
    FROM
        NEW.on_budget_account
)
EXECUTE FUNCTION check_transfers_categorization ();

-- Create Function and trigger to validate Transfer Ledger consistency
CREATE OR
REPLACE FUNCTION check_transfers_ledger () RETURNS TRIGGER AS $$
DECLARE v_transaction_ids INT[];
DECLARE v_ledger_count INT;
DECLARE rec RECORD;
BEGIN

    IF (TG_TABLE_NAME = 'transactions') THEN
        v_transaction_ids := ARRAY[NEW.id];
    ELSIF (TG_TABLE_NAME = 'accounts') THEN
        SELECT ARRAY_AGG(DISTINCT transaction_id) INTO v_transaction_ids
        FROM transactions
        WHERE account_id = NEW.id;
    ELSE
        v_transaction_ids := ARRAY[NEW.from_transaction_id, NEW.to_transaction_id];
    END IF;

    FOR rec IN (
        SELECT from_transaction_id, to_transaction_id
        FROM transfers
        WHERE from_transaction_id = ANY(v_transaction_ids) OR to_transaction_id = ANY(v_transaction_ids)
        )
    LOOP

        SELECT COUNT(DISTINCT accounts.ledger_id) INTO v_ledger_count
        FROM transactions
        INNER JOIN accounts
        ON transactions.account_id = accounts.id
        WHERE transactions.id IN (rec.from_transaction_id, rec.to_transaction_id);

        IF (v_ledger_count > 1) THEN
            RAISE EXCEPTION 'Transferred transactions can only be associated with accounts from the same ledger (from transaction_id % to transaction_id %).', rec.from_transaction_id, rec.to_transaction_id;
        END IF;

    END LOOP;

    RETURN NEW;

END;
$$ LANGUAGE 'plpgsql';

CREATE CONSTRAINT TRIGGER trg_transfers_ledger_on_change
AFTER INSERT OR
UPDATE ON transfers DEFERRABLE INITIALLY DEFERRED FOR EACH ROW
EXECUTE FUNCTION check_transfers_ledger ();

CREATE CONSTRAINT TRIGGER trg_transfers_ledger_on_transactions_change
AFTER
UPDATE OF account_id ON transactions DEFERRABLE INITIALLY DEFERRED FOR EACH ROW WHEN (
    OLD.account_id IS DISTINCT
    FROM
        NEW.account_id
)
EXECUTE FUNCTION check_transfers_ledger ();

CREATE CONSTRAINT TRIGGER trg_transfers_ledger_on_accounts_change
AFTER
UPDATE OF ledger_id ON accounts DEFERRABLE INITIALLY DEFERRED FOR EACH ROW WHEN (
    OLD.ledger_id IS DISTINCT
    FROM
        NEW.ledger_id
)
EXECUTE FUNCTION check_transfers_ledger ();

-- Create Function and trigger to check asset transactions in asset account
CREATE OR
REPLACE FUNCTION check_asset_transactions_account_asset () RETURNS TRIGGER AS $$
DECLARE v_transaction_ids INT[];
DECLARE rec RECORD;
BEGIN

    IF (TG_TABLE_NAME = 'transactions') THEN
        SELECT ARRAY_AGG(DISTINCT transaction_id) INTO v_transaction_ids
        FROM asset_transactions
        WHERE transaction_id = NEW.id;
    ELSIF (TG_TABLE_NAME = 'accounts') THEN
        SELECT ARRAY_AGG(DISTINCT asset_transactions.transaction_id) INTO v_transaction_ids
        FROM asset_transactions
        INNER JOIN transactions
        ON asset_transactions.transaction_id = transactions.id
        WHERE transactions.account_id = NEW.id;
    ELSE
        v_transaction_ids := ARRAY[NEW.transaction_id];
    END IF;

    FOR rec IN (
        SELECT transactions.id, transactions.account_id, accounts.is_asset_account
        FROM transactions
        INNER JOIN accounts
        ON transactions.account_id = accounts.id
        WHERE transactions.id = ANY(v_transaction_ids)
        )
    LOOP
    
        IF (rec.is_asset_account = FALSE) THEN
            RAISE EXCEPTION 'Asset Transaction only allowed in Asset Account (for transaction_id % and account_id %).', rec.id, rec.account_id;
        END IF;

    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_asset_transactions_account_asset_on_change
AFTER INSERT OR
UPDATE ON asset_transactions FOR EACH ROW
EXECUTE FUNCTION check_asset_transactions_account_asset ();

CREATE TRIGGER trg_asset_transactions_account_asset_on_transactions_change
AFTER
UPDATE OF account_id ON transactions FOR EACH ROW WHEN (
    OLD.account_id IS DISTINCT
    FROM
        NEW.account_id
)
EXECUTE FUNCTION check_asset_transactions_account_asset ();

CREATE TRIGGER trg_asset_transactions_account_asset_on_accounts_change
AFTER
UPDATE OF is_asset_account ON accounts FOR EACH ROW WHEN (
    OLD.is_asset_account IS DISTINCT
    FROM
        NEW.is_asset_account
)
EXECUTE FUNCTION check_asset_transactions_account_asset ();

-- Create Function and trigger to to validate Asset transactions amounts
CREATE OR
REPLACE FUNCTION check_asset_transactions_amount () RETURNS TRIGGER AS $$
DECLARE v_transaction_ids INT[];
DECLARE v_transaction_id INT;
DECLARE v_asset_transactions_sum NUMERIC(18, 2);
DECLARE v_transactions_amount NUMERIC(18, 2);
BEGIN

    IF (TG_TABLE_NAME = 'transactions') THEN
        SELECT ARRAY_AGG(DISTINCT transaction_id) INTO v_transaction_ids
        FROM asset_transactions
        WHERE transaction_id IN (NEW.id);
    ELSE
        SELECT ARRAY_AGG(DISTINCT transaction_id) INTO v_transaction_ids
        FROM asset_transactions
        WHERE transaction_id IN (NEW.transaction_id, OLD.transaction_id);
    END IF;

    IF (v_transaction_ids IS NOT NULL) THEN

        FOREACH v_transaction_id IN ARRAY v_transaction_ids
        LOOP

            SELECT CAST(COALESCE(ROUND(SUM((quantity * price_per_unit / exchange_rate) + fee), 2), 0) AS NUMERIC(18, 2)) INTO v_asset_transactions_sum
            FROM asset_transactions
            WHERE transaction_id = v_transaction_id;

            SELECT amount INTO v_transactions_amount
            FROM transactions
            WHERE id = v_transaction_id;

            IF ((v_transactions_amount - v_asset_transactions_sum) <> 0) THEN
                RAISE EXCEPTION 'Transaction asset sum (%) does not equal the transaction amount (%) for transaction_id %.', v_asset_transactions_sum, v_transactions_amount, v_transaction_id;
            END IF;

        END LOOP;

    END IF;

    RETURN COALESCE(NEW, OLD);

END;
$$ LANGUAGE 'plpgsql';

CREATE CONSTRAINT TRIGGER trg_asset_transactions_amount_on_change
AFTER INSERT OR
UPDATE OR
DELETE ON asset_transactions DEFERRABLE INITIALLY DEFERRED FOR EACH ROW
EXECUTE FUNCTION check_asset_transactions_amount ();

CREATE CONSTRAINT TRIGGER trg_asset_transactions_amount_on_transactions_change
AFTER
UPDATE OF amount ON transactions DEFERRABLE INITIALLY DEFERRED FOR EACH ROW WHEN (
    OLD.amount IS DISTINCT
    FROM
        NEW.amount
)
EXECUTE FUNCTION check_asset_transactions_amount ();

-- Create Function and trigger to validate Asset transactions Ledger consistency
CREATE OR
REPLACE FUNCTION check_asset_transactions_ledger () RETURNS TRIGGER AS $$
DECLARE v_transaction_ids INT[];
DECLARE v_asset_ids INT[];
DECLARE v_ledger_count INT;
DECLARE rec RECORD;
BEGIN
   
    IF (TG_TABLE_NAME = 'transactions') THEN
        SELECT ARRAY_AGG(DISTINCT transaction_id), ARRAY_AGG(DISTINCT asset_id) INTO v_transaction_ids, v_asset_ids
        FROM asset_transactions
        WHERE transaction_id = NEW.id;
    ELSIF (TG_TABLE_NAME = 'accounts') THEN
        SELECT ARRAY_AGG(DISTINCT asset_transactions.transaction_id), ARRAY_AGG(DISTINCT asset_transactions.asset_id) INTO v_transaction_ids, v_asset_ids
        FROM asset_transactions
        INNER JOIN transactions
        ON asset_transactions.transaction_id = transactions.id
        WHERE transactions.account_id = NEW.id;
    ELSIF (TG_TABLE_NAME = 'assets') THEN
        SELECT ARRAY_AGG(DISTINCT transaction_id), ARRAY_AGG(DISTINCT asset_id) INTO v_transaction_ids, v_asset_ids
        FROM asset_transactions
        WHERE asset_id = NEW.id;
    ELSE
        v_transaction_ids := ARRAY[NEW.transaction_id];
        v_asset_ids := ARRAY[NEW.asset_id];
    END IF;

    FOR rec IN (
        SELECT transaction_id, asset_id
        FROM asset_transactions
        WHERE transaction_id = ANY(v_transaction_ids) AND asset_id = ANY(v_asset_ids)
        )
    LOOP

        SELECT COUNT(DISTINCT ledger_id) INTO v_ledger_count
        FROM (
            SELECT accounts.ledger_id
            FROM transactions
            INNER JOIN accounts
            ON transactions.account_id = accounts.id
            WHERE transactions.id = rec.transaction_id
            UNION ALL
            SELECT assets.ledger_id
            FROM assets
            WHERE assets.id = rec.asset_id
        );

        IF (v_ledger_count > 1) THEN
            RAISE EXCEPTION 'Asset transactions asset can only be associated with account transaction from the same ledger (for transaction_id % and asset_id %).', rec.transaction_id, rec.asset_id;
        END IF;

    END LOOP;

    RETURN NEW;

END;
$$ LANGUAGE 'plpgsql';

CREATE CONSTRAINT TRIGGER trg_asset_transactions_ledger_on_change
AFTER INSERT OR
UPDATE ON asset_transactions DEFERRABLE INITIALLY DEFERRED FOR EACH ROW
EXECUTE FUNCTION check_asset_transactions_ledger ();

CREATE CONSTRAINT TRIGGER trg_asset_transactions_ledger_on_transactions_change
AFTER
UPDATE OF account_id ON transactions DEFERRABLE INITIALLY DEFERRED FOR EACH ROW WHEN (
    OLD.account_id IS DISTINCT
    FROM
        NEW.account_id
)
EXECUTE FUNCTION check_asset_transactions_ledger ();

CREATE CONSTRAINT TRIGGER trg_asset_transactions_ledger_on_accounts_change
AFTER
UPDATE OF ledger_id ON accounts DEFERRABLE INITIALLY DEFERRED FOR EACH ROW WHEN (
    OLD.ledger_id IS DISTINCT
    FROM
        NEW.ledger_id
)
EXECUTE FUNCTION check_asset_transactions_ledger ();

CREATE CONSTRAINT TRIGGER trg_asset_transactions_ledger_on_assets_change
AFTER
UPDATE OF ledger_id ON assets DEFERRABLE INITIALLY DEFERRED FOR EACH ROW WHEN (
    OLD.ledger_id IS DISTINCT
    FROM
        NEW.ledger_id
)
EXECUTE FUNCTION check_asset_transactions_ledger ();

-- Create Function and trigger to validate Categorized Budget Ledger consistency
CREATE OR
REPLACE FUNCTION check_category_budgets_ledger () RETURNS TRIGGER AS $$
DECLARE v_budget_ids INT[];
DECLARE v_category_ids INT[];
DECLARE v_ledger_count INT;
DECLARE rec RECORD;
BEGIN
   
    IF (TG_TABLE_NAME = 'budgets') THEN
        SELECT ARRAY_AGG(DISTINCT budget_id), ARRAY_AGG(DISTINCT category_id) INTO v_budget_ids, v_category_ids
        FROM category_budgets
        WHERE budget_id = NEW.id;
    ELSIF (TG_TABLE_NAME = 'categories') THEN
        SELECT ARRAY_AGG(DISTINCT budget_id), ARRAY_AGG(DISTINCT category_id) INTO v_budget_ids, v_category_ids
        FROM category_budgets
        WHERE category_id = NEW.id;
    ELSIF (TG_TABLE_NAME = 'category_groups') THEN
        SELECT ARRAY_AGG(DISTINCT category_budgets.budget_id), ARRAY_AGG(DISTINCT category_budgets.category_id) INTO v_budget_ids, v_category_ids
        FROM category_budgets
        INNER JOIN categories
        ON category_budgets.category_id = categories.id
        WHERE categories.category_group_id = NEW.id;
    ELSE
        v_budget_ids := ARRAY[NEW.budget_id];
        v_category_ids := ARRAY[NEW.category_id];
    END IF;

    FOR rec IN (
        SELECT budget_id, category_id
        FROM category_budgets
        WHERE budget_id = ANY(v_budget_ids) AND category_id = ANY(v_category_ids)
        )
    LOOP

        SELECT COUNT(DISTINCT ledger_id) INTO v_ledger_count
        FROM (
            SELECT budgets.ledger_id
            FROM budgets
            WHERE budgets.id = rec.budget_id
            UNION ALL
            SELECT category_groups.ledger_id
            FROM categories
            INNER JOIN category_groups
            ON categories.category_group_id = category_groups.id
            WHERE categories.id = rec.category_id
        );

        IF (v_ledger_count > 1) THEN
            RAISE EXCEPTION 'Categorized budgets budget can only be associated with categories from the same ledger (for budget_id % and category_id %).', rec.budget_id, rec.category_id;
        END IF;

    END LOOP;

    RETURN NEW;

END;
$$ LANGUAGE 'plpgsql';

CREATE CONSTRAINT TRIGGER trg_category_budgets_ledger_on_change
AFTER INSERT OR
UPDATE ON category_budgets DEFERRABLE INITIALLY DEFERRED FOR EACH ROW
EXECUTE FUNCTION check_category_budgets_ledger ();

CREATE CONSTRAINT TRIGGER trg_category_budgets_ledger_on_budgets_change
AFTER
UPDATE OF ledger_id ON budgets DEFERRABLE INITIALLY DEFERRED FOR EACH ROW WHEN (
    OLD.ledger_id IS DISTINCT
    FROM
        NEW.ledger_id
)
EXECUTE FUNCTION check_category_budgets_ledger ();

CREATE CONSTRAINT TRIGGER trg_category_budgets_ledger_on_categories_change
AFTER
UPDATE OF category_group_id ON categories DEFERRABLE INITIALLY DEFERRED FOR EACH ROW WHEN (
    OLD.category_group_id IS DISTINCT
    FROM
        NEW.category_group_id
)
EXECUTE FUNCTION check_category_budgets_ledger ();

CREATE CONSTRAINT TRIGGER trg_category_budgets_ledger_on_category_groups_change
AFTER
UPDATE OF ledger_id ON category_groups DEFERRABLE INITIALLY DEFERRED FOR EACH ROW WHEN (
    OLD.ledger_id IS DISTINCT
    FROM
        NEW.ledger_id
)
EXECUTE FUNCTION check_category_budgets_ledger ();