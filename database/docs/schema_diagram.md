# LTI Database Schema Diagram

The LTI (Ledger-To-Invest) application uses a PostgreSQL database with a comprehensive schema designed to ledgering, handle budgeting and investment tracking.

This document provides a high-level Entity-Relationship (ER) diagram for the Ledger-To-Invest (LTI) application's database. Its purpose is to give developers a quick visual overview of the database structure, the main entities, and how they relate to one another.

For a detailed breakdown of each table and its business logic, see `table-relationship.md`.

## Complete Entity Relationship Diagram

```mermaid
erDiagram
    %% Configuration Tables
    date_formats {
        int id PK
        varchar tag UK
        text detail
        timestamp created_at
        timestamp updated_at
    }
    
    currencies {
        int id PK
        varchar code UK
        text detail
        varchar symbol
        boolean on_left
        boolean breaking_space
        varchar fractional_separator
        varchar thousand_separator
        timestamp created_at
        timestamp updated_at
    }
    
    currency_exchange_rates {
        int from_currency_id PK, FK
        int to_currency_id PK, FK
        date date PK
        numeric rate
        timestamp created_at
        timestamp updated_at
    }
    
    %% User Management
    users {
        int id PK
        varchar username UK
        text password_hash
        varchar first_name
        varchar last_name
        varchar email UK
        boolean email_active
        boolean is_active
        boolean has_privileges
        timestamp created_at
        timestamp updated_at
    }
    
    %% Ledger Structure
    ledgers {
        int id PK
        int user_id FK
        varchar tag
        int date_format_id FK
        int currency_id FK
        timestamp created_at
        timestamp updated_at
    }
    
    %% Account Management
    account_types {
        int id PK
        varchar tag UK
        text detail
        boolean on_budget_account
        boolean can_invest
        timestamp created_at
        timestamp updated_at
    }
    
    accounts {
        int id PK
        int ledger_id FK
        varchar tag
        int account_type_id FK
        int currency_id FK
        boolean is_asset_account
        boolean is_closed
        timestamp created_at
        timestamp updated_at
    }
    
    %% Investment Tracking
    asset_types {
        int id PK
        varchar tag UK
        text detail
        timestamp created_at
        timestamp updated_at
    }
    
    assets {
        int id PK
        int ledger_id FK
        varchar symbol
        varchar tag
        int asset_type_id FK
        int currency_id FK
        timestamp created_at
        timestamp updated_at
    }
    
    asset_prices {
        int asset_id PK, FK
        date date PK
        numeric price
        timestamp created_at
        timestamp updated_at
    }
    
    %% Category Management
    category_groups {
        int id PK
        int ledger_id FK
        varchar tag
        int sort_order
        boolean is_system
        timestamp created_at
        timestamp updated_at
    }
    
    categories {
        int id PK
        int category_group_id FK
        varchar tag
        int sort_order
        timestamp created_at
        timestamp updated_at
    }
    
    %% Goals
    goal_types {
        int id PK
        varchar tag UK
        text detail
        timestamp created_at
        timestamp updated_at
    }
    
    goals {
        int category_id PK, FK
        int goal_type_id FK
        numeric goal_amount
        date goal_month
        timestamp created_at
        timestamp updated_at
    }
    
    %% Payees
    payees {
        int id PK
        int ledger_id FK
        varchar tag
        timestamp created_at
        timestamp updated_at
    }
    
    %% Transactions
    transactions {
        int id PK
        int account_id FK
        date date
        numeric amount
        text memo
        boolean cleared
        timestamp created_at
        timestamp updated_at
    }

    payee_transactions {
        int transaction_id PK, FK
        int payee_id FK
        timestamp created_at
        timestamp updated_at
    }
    
    category_transactions {
        int transaction_id PK, FK
        int category_id PK, FK
        numeric amount
        timestamp created_at
        timestamp updated_at
    }
    
    transfers {
        int from_transaction_id PK, FK
        int to_transaction_id PK, FK
        timestamp created_at
        timestamp updated_at
    }
    
    asset_transactions {
        int transaction_id PK, FK
        int asset_id FK
        numeric quantity
        numeric price_per_unit
        numeric exchange_rate
        numeric fee
        timestamp created_at
        timestamp updated_at
    }
    
    %% Budget Tracking
    budgets {
        int id PK
        int ledger_id FK
        date budget_month
        timestamp created_at
        timestamp updated_at
    }
    
    category_budgets {
        int budget_id PK, FK
        int category_id PK, FK
        numeric budgeted_amount
        timestamp created_at
        timestamp updated_at
    }
    
    %% Relationships
    currencies ||--o{ currency_exchange_rates : "from_currency"
    currencies ||--o{ currency_exchange_rates : "to_currency"
    currencies ||--o{ ledgers : "uses"
    currencies ||--o{ accounts : "uses"
    currencies ||--o{ assets : "priced_in"
    
    date_formats ||--o{ ledgers : "uses"
    
    users ||--o{ ledgers : "owns"
    
    ledgers ||--o{ accounts : "contains"
    ledgers ||--o{ category_groups : "organizes"
    ledgers ||--o{ assets : "tracks"
    ledgers ||--o{ payees : "manages"
    ledgers ||--o{ budgets : "planned"
    
    account_types ||--o{ accounts : "defines"
    accounts ||--o{ transactions : "records"
    
    asset_types ||--o{ assets : "categorizes"
    assets ||--o{ asset_prices : "valued"
    assets ||--o{ asset_transactions : "traded"
    
    category_groups ||--o{ categories : "groups"
    categories ||--|| goals : "targets"
    categories ||--o{ category_transactions : "categorizes"
    categories ||--o{ category_budgets : "budgeted"
    
    goal_types ||--o{ goals : "defines"
    
    payees ||--o{ payee_transactions : "from/to"
    
    transactions ||--o{ category_transactions : "splits_into"
    transactions ||--|| payee_transactions : "receive/send"
    transactions ||--|| transfers : "from_transaction"
    transactions ||--|| transfers : "to_transaction"
    transactions ||--|| asset_transactions : "details"
    
    budgets ||--o{ category_budgets : "allocates"
```

## Functional Layer Overview

```mermaid
graph TB
    subgraph "User Layer"
        A[date_formats]
        B[currencies] 
        C[currency_exchange_rates]
        D[users]
    end
    
    subgraph "Ledger Layer"
        E[ledgers]
    end
    
    subgraph "Account Layer"
        F[account_types]
        G[accounts]
    end
    
    subgraph "Investment Layer"
        H[asset_types]
        I[assets]
        J[asset_prices]
    end
    
    subgraph "Category Layer"
        K[category_groups]
        L[categories]
    end
    
    subgraph "Goals Layer"
        M[goal_types]
        N[goals]
    end
    
    subgraph "Payee Layer"
        O[payees]
    end
    
    subgraph "Transaction Layer"
        P[transactions]
        V[payee_transactions]
        Q[category_transactions]
        R[transfers]
        S[asset_transactions]
    end
    
    subgraph "Budget Layer"
        T[budgets]
        U[category_budgets]
    end
    
    %% Layer Dependencies
    D --> E
    A --> E
    B --> E
    E --> G
    E --> K
    E --> I
    E --> O
    E --> T
    F --> G
    B --> G
    H --> I
    B --> I
    I --> J
    I --> S
    K --> L
    L --> N
    L --> Q
    L --> U
    M --> N
    O --> V
    G --> P
    P --> Q
    P --> V
    P --> R
    P --> S
    T --> U
    B --> C
```

## Table Statistics by Layer

```mermaid
pie title Table Distribution by Functional Layer
    "Transaction Layer" : 5
    "Configuration Layer" : 3
    "Investment Layer" : 3
    "Account Layer" : 2
    "Category Layer" : 2
    "Goals Layer" : 2
    "Budget Layer" : 2
    "User Layer" : 1
    "Ledger Layer" : 1
    "Payee Layer" : 1
```

## Data Flow Overview

```mermaid
flowchart LR
    A[User Creates Ledger] --> B[Sets Up Accounts]
    B --> C[Creates Categories]
    C --> D[Defines Payees]
    D --> E[Records Transactions]
    E --> F{Transaction Type}
    F -->|Simple| G[Single Category]
    F -->|Split| H[Multiple Categories]
    F -->|Transfer| I[Between Accounts]
    F -->|Investment| J[Asset Transaction]
    G --> O[Associates Payee]
    H --> O
    O --> K[Budget Tracking]
    I --> K
    J --> L[Portfolio Tracking]
    K --> M[Monthly Reports]
    L --> N[Investment Analysis]
```

## Key Design Features

### Multi-Currency Support

- Built-in currency handling with exchange rates
- Currency conversion for international transactions
- Historical exchange rate tracking

### Investment Tracking

- Dedicated asset management with pricing history
- Support for stocks, ETFs, bonds, crypto, real estate, etc.
- Automatic portfolio valuation

### Flexible Categories

- Hierarchical category system with groups
- System vs. user-defined categories
- Sortable category organization

### Advanced Transaction Features

- Split transactions across multiple categories
- Transfer management between accounts
- Investment transaction details with fees

### Budget Planning

- Monthly budget allocation and tracking
- Goal setting with multiple goal types
- Progress tracking against targets

### Data Integrity

- Comprehensive constraint system
- Audit trail with timestamps
- Automated validation triggers

### Cascade Behavior

- User data deletion removes entire ledger hierarchy
- Configuration tables protected from deletion

### Audit Trail

- All tables maintain `created_at` and `updated_at` timestamps
- Automatic triggers update timestamps on changes
- Complete change history for compliance and debugging

## Total Schema Statistics

- **Total Tables**: 22
  - **Core Entity Tables**: 13
  - **Lookup Tables**: 5 (date_formats, currencies, account_types, asset_types, goal_types)
  - **Junction Tables**: 4 (currency_exchange_rates, category_budgets, category_transactions, transfers)
- **Indexes**: 18 performance indexes
- **Triggers**: 22 update timestamp triggers + 9 validation triggers
- **Functions**: 5 validation functions
