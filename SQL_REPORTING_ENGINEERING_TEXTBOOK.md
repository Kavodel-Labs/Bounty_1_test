# SQL Reporting Engineering Textbook
## Complete Guide to Building Gaming Platform Analytics Reports

**Version:** 1.0
**Date:** November 19, 2025
**Audience:** Data Engineers, SQL Developers, BI Analysts
**Complexity:** Intermediate to Advanced

---

## 📚 Table of Contents

### Part I: Foundations
1. [Introduction & Architecture](#part-i-introduction--architecture)
2. [Database Schema Overview](#database-schema-overview)
3. [Report Structure Philosophy](#report-structure-philosophy)

### Part II: Core Components
4. [CTE Design Patterns](#part-ii-cte-design-patterns)
5. [Filter Systems](#filter-systems)
6. [Currency Handling](#currency-handling)
7. [Metric Calculations](#metric-calculations)

### Part III: Implementation Guide
8. [Building a Report Step-by-Step](#part-iii-building-a-report-step-by-step)
9. [Testing & Validation](#testing--validation)
10. [Performance Optimization](#performance-optimization)

### Part IV: Reference
11. [Standard Formulas](#part-iv-standard-formulas-reference)
12. [Common Pitfalls](#common-pitfalls-and-solutions)
13. [Troubleshooting Guide](#troubleshooting-guide)

---

# PART I: Introduction & Architecture

## Introduction

This textbook documents the complete standard for building SQL reports for a gaming/casino platform analytics system. Every report in this company MUST follow these patterns to ensure:

- ✅ **Accuracy** - Correct calculations across all metrics
- ✅ **Consistency** - Same logic produces same results everywhere
- ✅ **Performance** - Queries execute efficiently at scale
- ✅ **Maintainability** - Easy to understand and modify
- ✅ **Compatibility** - Works with Metabase Field Filters

---

## Database Schema Overview

### Core Tables

#### 1. `players` Table
**Purpose:** Stores all registered users.

**Key Fields:**
```sql
id                 BIGINT PRIMARY KEY    -- Unique player identifier
created_at         TIMESTAMP             -- Registration timestamp
email_verified     BOOLEAN               -- Email verification status
company_id         BIGINT                -- FK to companies (brand)
affiliate_id       BIGINT                -- FK to affiliates
country            VARCHAR(2)            -- ISO country code (e.g., 'US')
os                 VARCHAR(50)           -- Operating system
browser            VARCHAR(50)           -- Browser type
```

**Usage in Reports:**
- Registration metrics
- Player filtering
- Demographic analysis

**Joins:**
```sql
-- Get player with brand name
SELECT p.*, c.name as brand_name
FROM players p
LEFT JOIN companies c ON c.id = p.company_id
```

---

#### 2. `transactions` Table
**Purpose:** Stores ALL financial and gaming transactions.

**Key Fields:**
```sql
id                      BIGINT PRIMARY KEY
player_id               BIGINT                -- FK to players
created_at              TIMESTAMP             -- Transaction timestamp
transaction_category    VARCHAR(50)           -- Type of transaction (see below)
transaction_type        VARCHAR(20)           -- 'credit' or 'debit'
status                  VARCHAR(20)           -- 'completed', 'cancelled', 'pending'
balance_type            VARCHAR(30)           -- 'withdrawable' or 'non-withdrawable'
amount                  NUMERIC(19,4)         -- Amount in ORIGINAL currency
currency_type           VARCHAR(3)            -- Currency code (e.g., 'USD')
eur_amount              NUMERIC(19,4)         -- Converted to EUR (may be NULL)
external_transaction_id VARCHAR(255)          -- External system reference
player_bonus_id         BIGINT                -- FK to player_bonus (if bonus-related)
```

**Transaction Categories:**
```
deposit              - Player deposits money
withdrawal           - Player withdraws money
game_bet             - Player places a bet (cash or promo)
bonus                - Bonus credits/debits (promo bets if external_transaction_id)
bonus_completion     - Bonus wagering completed
free_spin_bonus      - Free spins granted
free_bet             - Free bet granted
free_bet_win         - Free bet win credited
freebet_win          - Free bet win (alternative spelling)
```

**Transaction Types:**
```
credit   - Money/bonus added to player balance
debit    - Money/bonus removed from player balance
```

**Balance Types:**
```
withdrawable       - Real money that can be withdrawn
non-withdrawable   - Bonus money that must be wagered
```

**Status Values:**
```
completed   - Transaction processed successfully
cancelled   - Transaction was cancelled/reversed
pending     - Transaction awaiting processing
```

---

#### 3. `player_balances` Table
**Purpose:** Tracks player balances by currency and type.

**Key Fields:**
```sql
player_id       BIGINT    -- FK to players
currency_type   VARCHAR(3)  -- Currency code
balance_type    VARCHAR(30) -- 'withdrawable' or 'non-withdrawable'
balance         NUMERIC(19,4)  -- Current balance
```

**Usage in Reports:**
- Currency filtering for players
- Balance verification

**Join Pattern:**
```sql
-- Get players with specific currency wallet
LEFT JOIN player_balances pb ON pb.player_id = p.id
  AND pb.balance_type = 'withdrawable'
WHERE ({{currency_filter}} = 'EUR' OR pb.currency_type IN ({{currency_filter}}))
```

---

#### 4. `companies` Table
**Purpose:** Stores brand/operator information.

**Key Fields:**
```sql
id       BIGINT PRIMARY KEY
name     VARCHAR(255)    -- Brand name
currency VARCHAR(3)      -- Default currency
```

**Usage in Reports:**
- Brand filtering
- Default currency reference (rarely used now)

---

## Report Structure Philosophy

All reports follow a standardized CTE (Common Table Expression) structure:

```
INPUT PARAMETERS
  ↓
DATE BOUNDS CALCULATION
  ↓
DATE SERIES GENERATION
  ↓
PLAYER FILTERING
  ↓
METRIC CALCULATION CTEs (parallel)
  ↓
DATA ASSEMBLY
  ↓
FINAL OUTPUT (with TOTAL row)
```

### Why CTEs?

**Advantages:**
1. **Readability** - Each CTE has a clear purpose
2. **Modularity** - Easy to test individual components
3. **Maintainability** - Changes are localized
4. **Reusability** - CTEs can reference other CTEs
5. **Performance** - PostgreSQL optimizes CTE execution plans

**Example Structure:**
```sql
WITH
input_cte AS (...),      -- Step 1: Capture inputs
bounds_cte AS (...),      -- Step 2: Calculate date bounds
series_cte AS (...),      -- Step 3: Generate date series
filtered_players AS (...), -- Step 4: Filter players
metric_1 AS (...),        -- Step 5a: Calculate metric 1
metric_2 AS (...),        -- Step 5b: Calculate metric 2 (parallel)
metric_3 AS (...),        -- Step 5c: Calculate metric 3 (parallel)
final_data AS (...)       -- Step 6: Assemble all metrics

SELECT * FROM final_data  -- Step 7: Output
```

---

# PART II: CTE Design Patterns

## 1. Input Parameter CTEs

### Purpose
Capture Metabase input parameters and provide default values.

### Pattern
```sql
start_input AS (
  SELECT NULL::date AS start_date WHERE FALSE
  [[ UNION ALL SELECT {{start_date}}::date ]]
),
end_input AS (
  SELECT NULL::date AS end_date WHERE FALSE
  [[ UNION ALL SELECT {{end_date}}::date ]]
),
```

### How It Works

**When user provides {{start_date}}:**
```sql
-- Metabase expands to:
start_input AS (
  SELECT NULL::date AS start_date WHERE FALSE  -- Returns 0 rows
  UNION ALL
  SELECT '2025-01-01'::date  -- Returns 1 row with user's date
)
-- Result: 1 row with value '2025-01-01'
```

**When user does NOT provide {{start_date}}:**
```sql
-- Metabase expands to:
start_input AS (
  SELECT NULL::date AS start_date WHERE FALSE  -- Returns 0 rows
  -- UNION ALL clause is removed by Metabase
)
-- Result: 0 rows (NULL)
```

### Why This Pattern?

**Problem:** Metabase Field Filters are optional. How do you handle both cases?

**Solution:** This pattern creates a table with:
- 0 rows if no input (treated as NULL)
- 1 row if input provided

Then in `bounds_raw`:
```sql
bounds_raw AS (
  SELECT
    COALESCE((SELECT MAX(end_date) FROM end_input), CURRENT_DATE) AS end_date_raw,
    (SELECT MAX(start_date) FROM start_input) AS start_date_raw
)
```

- `MAX(end_date)` returns NULL if no input, then COALESCE uses CURRENT_DATE
- `MAX(start_date)` returns NULL if no input

**Perfect for optional parameters!**

---

## 2. Bounds Calculation CTE

### Purpose
Normalize and validate date ranges.

### Daily Report Pattern
```sql
bounds_raw AS (
  SELECT
    COALESCE((SELECT MAX(end_date) FROM end_input), CURRENT_DATE) AS end_date_raw,
    (SELECT MAX(start_date) FROM start_input) AS start_date_raw
),
bounds AS (
  SELECT
    end_date_raw AS end_date,
    CASE
      WHEN start_date_raw IS NULL THEN end_date_raw - INTERVAL '31 day'  -- Default: last 31 days
      WHEN start_date_raw > end_date_raw THEN end_date_raw                 -- Invalid: use end date
      ELSE start_date_raw                                                   -- Valid: use as-is
    END AS start_date
  FROM bounds_raw
)
```

### Monthly Report Pattern
```sql
bounds AS (
  SELECT
    -- Clamp end to last day of month
    DATE_TRUNC('month', end_date_raw) + INTERVAL '1 month' - INTERVAL '1 day' AS end_date,
    CASE
      WHEN start_date_raw IS NULL
        THEN DATE_TRUNC('month', end_date_raw - INTERVAL '12 months')  -- Default: last 12 months
      WHEN start_date_raw > end_date_raw
        THEN DATE_TRUNC('month', end_date_raw)                         -- Invalid: use end month
      ELSE DATE_TRUNC('month', start_date_raw)                         -- Valid: truncate to month start
    END AS start_date
  FROM bounds_raw
)
```

### Key Principles

1. **Always provide defaults** - Reports should work without parameters
2. **Validate user input** - Handle start > end gracefully
3. **Align to reporting period** - Monthly reports truncate to month boundaries

---

## 3. Date Series Generation

### Purpose
Create a row for each reporting period (day or month).

### Daily Series
```sql
date_series AS (
  SELECT
    d::date AS report_date,              -- The date for this row
    d AS start_ts,                        -- Midnight of this day
    LEAST(d + INTERVAL '1 day', NOW()) AS end_ts  -- End of day (or NOW if today)
  FROM generate_series(
    (SELECT start_date FROM bounds),
    (SELECT end_date FROM bounds),
    INTERVAL '1 day'
  ) AS d
)
```

### Why LEAST(d + INTERVAL '1 day', NOW())?

**Problem:** If today is January 15, 2025 at 3:00 PM and you generate a series including today:
- `start_ts` = 2025-01-15 00:00:00
- `end_ts` = 2025-01-16 00:00:00 (tomorrow!)

This would include future transactions if clock is wrong or timezone issues.

**Solution:** Use `LEAST(..., NOW())`:
- For past days: end_ts = tomorrow midnight (full 24 hours)
- For today: end_ts = current time (partial day)

### Monthly Series
```sql
month_series AS (
  SELECT
    DATE_TRUNC('month', d)::date AS report_month,
    DATE_TRUNC('month', d) AS start_ts,
    LEAST(DATE_TRUNC('month', d) + INTERVAL '1 month', NOW()) AS end_ts
  FROM generate_series(
    (SELECT start_date FROM bounds),
    (SELECT end_date FROM bounds),
    INTERVAL '1 month'
  ) AS d
)
```

### Join Pattern

All metric CTEs join to the series:
```sql
metric_cte AS (
  SELECT
    ds.report_date,  -- Group by reporting period
    COUNT(DISTINCT t.player_id) AS player_count,
    SUM(t.amount) AS total_amount
  FROM date_series ds
  LEFT JOIN transactions t
    ON t.created_at >= ds.start_ts
    AND t.created_at < ds.end_ts
  GROUP BY ds.report_date
)
```

**Why LEFT JOIN?**
- Ensures every date in series appears in output, even if zero transactions
- Creates rows with 0/NULL for days with no activity

---

## 4. Player Filtering CTE

### Purpose
Pre-filter players based on Field Filters to improve performance and accuracy.

### Standard Pattern (CTO-Approved)
```sql
filtered_players AS (
  SELECT DISTINCT players.id AS player_id
  FROM players
  LEFT JOIN companies ON companies.id = players.company_id
  WHERE 1=1
    [[ AND {{brand}} ]]                    -- Brand filter
    [[ AND players.country = CASE {{country}}  -- Country filter with mapping
      WHEN 'Romania' THEN 'RO'
      WHEN 'France' THEN 'FR'
      -- ... all country mappings ...
    END ]]
    [[ AND CASE                             -- Traffic source filter
      WHEN {{traffic_source}} = 'Organic' THEN players.affiliate_id IS NULL
      WHEN {{traffic_source}} = 'Affiliate' THEN players.affiliate_id IS NOT NULL
      ELSE TRUE
    END ]]
    [[ AND {{affiliate_id}} ]]             -- Affiliate ID filter
    [[ AND {{affiliate_name}} ]]           -- Affiliate name filter
    [[ AND CONCAT(players.os, ' / ', players.browser) = {{registration_launcher}} ]]  -- Device filter
    [[ AND {{is_test_account}} ]]          -- Test account filter
)
```

### Field Filter Syntax

**Metabase Field Filters** use double bracket syntax: `[[ AND {{filter_name}} ]]`

**When user applies filter:**
```sql
-- Metabase expands:
[[ AND {{brand}} ]]
-- Becomes:
AND companies.name = 'Brand ABC'
```

**When user does NOT apply filter:**
```sql
-- Metabase removes the entire clause:
[[ AND {{brand}} ]]
-- Becomes: (nothing)
```

### Critical Rule: NO ALIASES IN FIELD FILTERS!

**❌ WRONG:**
```sql
filtered_players AS (
  SELECT DISTINCT
    players.id AS player_id,
    companies.name AS brand_name  -- Creating alias
  FROM players
  LEFT JOIN companies ON companies.id = players.company_id
  WHERE 1=1
    [[ AND {{brand}} ]]  -- Metabase will look for companies.name, but might fail
)
```

**✅ CORRECT:**
```sql
filtered_players AS (
  SELECT DISTINCT players.id AS player_id  -- No company fields in SELECT
  FROM players
  LEFT JOIN companies ON companies.id = players.company_id
  WHERE 1=1
    [[ AND {{brand}} ]]  -- Metabase can correctly inject filter on companies.name
)
```

**Why?** Metabase's Field Filter injection works directly on table fields, not aliases.

---

## 5. Player Registration CTE (WITH Currency Filtering)

### Purpose
Get registration data for players, filtered by their wallet currency.

### Standard Pattern (CTO-Approved)
```sql
player_reg AS (
  SELECT DISTINCT  -- ✅ DISTINCT because player_balances may have multiple rows
    p.id AS player_id,
    p.created_at AS registration_ts,
    p.email_verified,
    c.name AS brand_name
  FROM players p
  INNER JOIN filtered_players fp ON p.id = fp.player_id
  LEFT JOIN companies c ON p.company_id = c.id
  LEFT JOIN player_balances pb ON pb.player_id = p.id  -- ✅ Join to balances
    AND pb.balance_type = 'withdrawable'                -- ✅ Only cash wallets
  WHERE 1=1
    [[ AND ({{currency_filter}} = 'EUR' OR pb.currency_type IN ({{currency_filter}})) ]]  -- ✅ Currency filter
),
```

### Why This Matters

**Without currency filtering:**
- Player with USD wallet included in EUR report
- Their registration counted in EUR registrations (wrong!)

**With currency filtering:**
- Only players with EUR wallets counted in EUR report
- Accurate currency-specific metrics

### Why DISTINCT?

**Problem:** A player can have multiple balances (one per currency).

Example player_balances rows for player ID 123:
```
player_id | currency_type | balance_type   | balance
123       | EUR           | withdrawable   | 100.00
123       | USD           | withdrawable   | 50.00
```

Without DISTINCT:
```sql
SELECT p.id, p.created_at
FROM players p
LEFT JOIN player_balances pb ON pb.player_id = p.id
WHERE p.id = 123
-- Returns: 2 rows (one per balance)
```

With DISTINCT:
```sql
SELECT DISTINCT p.id, p.created_at
FROM players p
LEFT JOIN player_balances pb ON pb.player_id = p.id
WHERE p.id = 123
-- Returns: 1 row (deduplicated)
```

---

# Filter Systems

## Currency Filtering (CRITICAL SECTION)

### The Complete Currency Filtering Standard

Currency filtering must happen in **TWO places**:

1. **WHERE Clause:** Filter which transactions to include
2. **CASE Statement:** Determine which amount field to use

---

### 1. WHERE Clause Currency Filter

**Standard Pattern:**
```sql
WHERE 1=1
  [[ AND ({{currency_filter}} = 'EUR' OR t.currency_type IN ({{currency_filter}})) ]]
```

**How It Works:**

| User Selection | Filter Expansion | Logic |
|----------------|------------------|-------|
| EUR | `('EUR' = 'EUR' OR t.currency_type IN ('EUR'))` | TRUE OR TRUE = TRUE for all rows |
| USD | `('EUR' = 'USD' OR t.currency_type IN ('USD'))` | FALSE OR (only USD) = only USD |
| Multiple | `('EUR' = 'USD,CAD' OR t.currency_type IN ('USD','CAD'))` | Only USD and CAD |

**Why this works:**
- **EUR selection = show ALL currencies** (because we convert everything to EUR using eur_amount)
- **Specific currency = show only that currency** (use native amounts)

---

### 2. CASE Statement Currency Conversion

**Standard Pattern (3-Level Hierarchy):**
```sql
COALESCE(SUM(CASE
  WHEN <transaction_filters>
  THEN
    CASE
      -- Level 1: Native currency matches filter
      WHEN t.currency_type = {{currency_filter}}
      THEN t.amount

      -- Level 2: Converting to EUR
      WHEN {{currency_filter}} = 'EUR'
      THEN COALESCE(t.eur_amount, t.amount)  -- Fallback to amount if NULL

      -- Level 3: Fallback
      ELSE t.amount
    END
END), 0) AS metric_name
```

**Level-by-Level Explanation:**

#### Level 1: Native Currency Match
```sql
WHEN t.currency_type = {{currency_filter}}
THEN t.amount
```

**When this triggers:**
- User filters by USD
- Transaction is in USD
- **Action:** Use the raw `amount` field (100 USD = 100)

**Why?** No conversion needed - the transaction is already in the requested currency.

---

#### Level 2: EUR Conversion
```sql
WHEN {{currency_filter}} = 'EUR'
THEN COALESCE(t.eur_amount, t.amount)
```

**When this triggers:**
- User filters by EUR
- Transaction can be any currency

**Action:**
1. Check if `eur_amount` exists (pre-computed EUR conversion)
2. If yes: use `eur_amount`
3. If NULL: fallback to `amount` (use original value)

**Example:**

| Transaction | amount | eur_amount | Result |
|-------------|--------|------------|---------|
| Tx 1 (USD)  | 100    | 85         | 85 EUR (converted) |
| Tx 2 (EUR)  | 50     | 50         | 50 EUR (native) |
| Tx 3 (CAD)  | 200    | NULL       | 200 EUR (fallback - no conversion available) |

**Why fallback to amount?**
- Better to have approximate data than zero
- NULL conversions shouldn't hide transactions
- Total will be more accurate than dropping rows

---

#### Level 3: Fallback
```sql
ELSE t.amount
```

**When this triggers:**
- Edge cases
- Multi-currency selection (not common)

**Action:** Use raw amount as last resort.

---

### Complete Example: Deposit Amount Calculation

```sql
deposit_metrics AS (
  SELECT
    ds.report_date,

    -- Count of deposits
    COUNT(*) FILTER (
      WHERE t.transaction_category='deposit'
        AND t.transaction_type='credit'
        AND t.status='completed'
        AND t.balance_type='withdrawable'
    ) AS deposits_count,

    -- Total deposit amount
    COALESCE(SUM(CASE
      WHEN t.transaction_category='deposit'
       AND t.transaction_type='credit'
       AND t.status='completed'
       AND t.balance_type='withdrawable'
      THEN
        CASE
          -- Level 1: Native currency
          WHEN t.currency_type = {{currency_filter}}
          THEN t.amount

          -- Level 2: EUR conversion
          WHEN {{currency_filter}} = 'EUR'
          THEN COALESCE(t.eur_amount, t.amount)

          -- Level 3: Fallback
          ELSE t.amount
        END
    END), 0) AS deposits_amount

  FROM date_series ds
  LEFT JOIN transactions t
    ON t.created_at >= ds.start_ts
    AND t.created_at < ds.end_ts
  INNER JOIN filtered_players fp ON t.player_id = fp.player_id
  JOIN players ON players.id = t.player_id
  JOIN companies ON companies.id = players.company_id
  WHERE 1=1
    [[ AND ({{currency_filter}} = 'EUR' OR t.currency_type IN ({{currency_filter}})) ]]
  GROUP BY ds.report_date
),
```

---

### Common Mistakes to Avoid

#### ❌ Mistake #1: Using 0 instead of amount fallback
```sql
-- WRONG
WHEN {{currency_filter}} = 'EUR'
THEN COALESCE(t.eur_amount, 0)  -- ❌ NULL becomes 0
```

**Impact:** Transactions without EUR conversion disappear from totals.

#### ❌ Mistake #2: Not checking native currency first
```sql
-- WRONG
CASE
  WHEN {{currency_filter}} = 'EUR'
  THEN COALESCE(t.eur_amount, t.amount)
  ELSE t.amount
END
```

**Impact:** When filtering by USD, USD transactions go through EUR conversion logic unnecessarily.

#### ❌ Mistake #3: Complex COALESCE in WHERE clause
```sql
-- WRONG
WHERE UPPER(COALESCE(t.metadata->>'currency', t.cash_currency, players.wallet_currency)) = {{currency_filter}}
```

**Impact:** Breaks Metabase Field Filters, slow performance.

#### ✅ Correct: Simple OR logic
```sql
-- CORRECT
WHERE ({{currency_filter}} = 'EUR' OR t.currency_type IN ({{currency_filter}}))
```

---

## Transaction Category Filters

### Standard Transaction Filters

Every transaction-based metric needs proper filtering. Here are the standard patterns:

#### Deposits
```sql
WHERE t.transaction_category = 'deposit'
  AND t.transaction_type = 'credit'
  AND t.status = 'completed'
  AND t.balance_type = 'withdrawable'
```

**Why each filter:**
- `transaction_category = 'deposit'` → Only deposit transactions
- `transaction_type = 'credit'` → Money added to account (not reversals)
- `status = 'completed'` → Successful deposits only
- `balance_type = 'withdrawable'` → Real money deposits (not bonus)

---

#### Withdrawals
```sql
WHERE t.transaction_category = 'withdrawal'
  AND t.transaction_type = 'debit'
  AND t.status = 'completed'
  AND t.balance_type = 'withdrawable'
```

**For cancelled withdrawals:**
```sql
WHERE t.transaction_category = 'withdrawal'
  AND t.transaction_type = 'debit'
  AND t.status = 'cancelled'  -- ← Different status
  AND t.balance_type = 'withdrawable'
```

**Why check cancelled?**
- Tracks player withdrawal requests that were rejected
- Important for fraud analysis and player experience

---

#### Cash Bets
```sql
WHERE t.transaction_type = 'debit'
  AND t.transaction_category = 'game_bet'
  AND t.balance_type = 'withdrawable'
  AND t.status = 'completed'
```

**Key points:**
- `balance_type = 'withdrawable'` → Using real money (not bonus)
- `transaction_type = 'debit'` → Money leaving player balance

---

#### Cash Wins
```sql
WHERE t.transaction_type = 'credit'
  AND t.transaction_category = 'game_bet'
  AND t.balance_type = 'withdrawable'
  AND t.status = 'completed'
```

**Key points:**
- `transaction_type = 'credit'` → Money added back to balance (opposite of bet)
- Same category ('game_bet') - wins are still part of game transactions

---

#### Promo Bets (CTO-Approved Logic)
```sql
WHERE t.transaction_type = 'debit'
  AND t.transaction_category = 'bonus'
  AND t.status = 'completed'
  AND t.external_transaction_id IS NOT NULL  -- ✅ NEW STANDARD
```

**Critical: Use `external_transaction_id IS NOT NULL`**

**OLD logic (deprecated):**
```sql
AND t.balance_type = 'non-withdrawable'  -- ❌ OLD WAY
```

**Why the change?**
- More accurate identification of promotional bets
- `external_transaction_id` indicates external bonus system triggered the bet
- `balance_type` alone can include other bonus activity

---

#### Promo Wins (CTO-Approved Logic)
```sql
WHERE t.transaction_type = 'credit'
  AND t.transaction_category = 'bonus'
  AND t.status = 'completed'
  AND t.external_transaction_id IS NOT NULL  -- ✅ NEW STANDARD
```

---

#### Granted Bonus (CTO-Approved Logic)
```sql
WHERE (
  -- Regular bonus credits
  (t.transaction_category = 'bonus'
   AND t.transaction_type = 'credit'
   AND t.status = 'completed'
   AND t.balance_type = 'non-withdrawable'
   AND t.player_bonus_id IS NOT NULL)

  OR

  -- Free spin bonus
  (t.transaction_category = 'free_spin_bonus'
   AND t.transaction_type = 'credit'
   AND t.status = 'completed'
   AND t.balance_type = 'non-withdrawable'
   AND t.player_bonus_id IS NOT NULL)

  OR

  -- Free bet wins
  (t.transaction_category IN ('free_bet', 'free_bet_win', 'freebet_win')
   AND t.transaction_type = 'credit'
   AND t.status = 'completed'
   AND t.balance_type = 'non-withdrawable'
   AND t.player_bonus_id IS NOT NULL)

  OR

  -- Bonus completion (non-withdrawable portion)
  (t.transaction_category = 'bonus_completion'
   AND t.transaction_type = 'credit'
   AND t.status = 'completed'
   AND t.balance_type = 'non-withdrawable'
   AND t.player_bonus_id IS NOT NULL)
)
```

**Key points:**
- Must have `player_bonus_id IS NOT NULL` → Linked to bonus campaign
- Includes multiple bonus types
- Only `non-withdrawable` balance type
- This is "bonus cost" from business perspective

---

#### Bonus Cost (Converted Bonuses)
```sql
WHERE t.transaction_type = 'credit'
  AND t.balance_type = 'withdrawable'  -- ✅ Note: withdrawable (completed wagering)
  AND t.status = 'completed'
  AND t.transaction_category = 'bonus_completion'
```

**Difference from Granted Bonus:**
- Granted Bonus = bonus given to player (non-withdrawable)
- Bonus Cost = bonus that player successfully converted to cash (withdrawable)

**Business meaning:**
- Granted Bonus = €10,000 given
- Bonus Cost = €3,000 converted to cash
- Casino kept €7,000 (player forfeited/failed wagering)

---

## FTD (First Time Depositor) Logic

### Overview

FTD identification is complex because it requires:
1. Finding each player's FIRST deposit ever
2. Filtering by currency
3. Filtering by date range
4. Classifying FTDs (New, Old, D0, Late)

### Complete FTD CTEs

#### Step 1: Get All Deposits with Ranking
```sql
ftd_all_deposits AS (
  SELECT
    t.player_id,
    t.created_at,
    ROW_NUMBER() OVER (PARTITION BY t.player_id ORDER BY t.created_at ASC) as deposit_rank
  FROM transactions t
  INNER JOIN filtered_players fp ON t.player_id = fp.player_id
  JOIN players ON players.id = t.player_id
  JOIN companies ON companies.id = players.company_id
  WHERE t.transaction_category = 'deposit'
    AND t.transaction_type = 'credit'
    AND t.status = 'completed'
    AND t.balance_type = 'withdrawable'  -- ✅ Only real money deposits
    [[ AND ({{currency_filter}} = 'EUR' OR t.currency_type IN ({{currency_filter}})) ]]
),
```

**How ROW_NUMBER works:**

Player 123's deposits:
```
player_id | created_at           | deposit_rank
123       | 2025-01-15 10:00:00  | 1  ← FIRST deposit
123       | 2025-01-20 14:00:00  | 2
123       | 2025-02-05 09:00:00  | 3
```

`PARTITION BY t.player_id` → Separate ranking per player
`ORDER BY t.created_at ASC` → Earliest deposit gets rank 1

---

#### Step 2: Extract First Deposits Only
```sql
ftd_first AS (
  SELECT
    player_id,
    created_at AS first_deposit_ts
  FROM ftd_all_deposits
  WHERE deposit_rank = 1  -- ← Only the first deposit
    AND created_at >= (SELECT start_date FROM bounds)
    AND created_at < (SELECT end_date FROM bounds) + INTERVAL '1 day'
),
```

**Why filter by date HERE?**
- We want FTDs that happened within the report period
- A player's first deposit must fall in our date range to be counted

---

#### Step 3: Join with Registration Data
```sql
ftds AS (
  SELECT
    DATE_TRUNC('day', ff.first_deposit_ts)::date AS report_date,  -- For daily reports
    -- OR for monthly:
    -- DATE_TRUNC('month', ff.first_deposit_ts)::date AS report_month,
    pr.player_id,
    pr.registration_ts,
    ff.first_deposit_ts
  FROM ftd_first ff
  JOIN player_reg pr ON pr.player_id = ff.player_id
),
```

**Why join to player_reg?**
- Need registration timestamp to classify FTD type
- Need to compare registration date vs deposit date

---

#### Step 4: Calculate FTD Metrics with Classification
```sql
ftd_metrics AS (
  SELECT
    ds.report_date,  -- or ms.report_month for monthly

    -- Total FTDs
    COUNT(DISTINCT f.player_id) AS ftds_count,

    -- NEW FTDs (CTO-Approved Logic)
    COUNT(*) FILTER (
      WHERE DATE_TRUNC('month', f.registration_ts) = DATE_TRUNC('month', f.first_deposit_ts)
        AND DATE_TRUNC('day', f.registration_ts) <> DATE_TRUNC('day', f.first_deposit_ts)
    ) AS new_ftds,

    -- OLD FTDs (CTO-Approved Logic)
    COUNT(*) FILTER (
      WHERE DATE_TRUNC('month', f.registration_ts) < DATE_TRUNC('month', f.first_deposit_ts)
    ) AS old_ftds,

    -- D0 FTDs (Same Day)
    COUNT(*) FILTER (
      WHERE DATE_TRUNC('day', f.registration_ts) = DATE_TRUNC('day', f.first_deposit_ts)
    ) AS d0_ftds,

    -- Late FTDs (Not Same Day)
    COUNT(*) FILTER (
      WHERE DATE_TRUNC('day', f.registration_ts) <> DATE_TRUNC('day', f.first_deposit_ts)
    ) AS late_ftds

  FROM date_series ds  -- or month_series ms for monthly
  LEFT JOIN ftds f ON f.report_date = ds.report_date  -- or f.report_month = ms.report_month
  GROUP BY ds.report_date  -- or ms.report_month
),
```

### FTD Classification Logic Explained

#### Example Players:

| Player | Registration Date | First Deposit Date | Classification |
|--------|-------------------|-------------------|----------------|
| Alice  | Jan 15, 2025      | Jan 15, 2025      | **D0 FTD** (same day) |
| Bob    | Jan 15, 2025      | Jan 20, 2025      | **New FTD** (same month, different day) |
| Carol  | Dec 20, 2024      | Jan 10, 2025      | **Old FTD** (different month) |

#### Code Walkthrough:

**D0 FTD (Alice):**
```sql
WHERE DATE_TRUNC('day', '2025-01-15') = DATE_TRUNC('day', '2025-01-15')
-- TRUE → Counted as D0 FTD
```

**New FTD (Bob):**
```sql
WHERE DATE_TRUNC('month', '2025-01-15') = DATE_TRUNC('month', '2025-01-20')  -- Both January
  AND DATE_TRUNC('day', '2025-01-15') <> DATE_TRUNC('day', '2025-01-20')    -- Different days
-- TRUE → Counted as New FTD
```

**Old FTD (Carol):**
```sql
WHERE DATE_TRUNC('month', '2024-12-20') < DATE_TRUNC('month', '2025-01-10')
-- December < January
-- TRUE → Counted as Old FTD
```

**Late FTD:**
- Late FTD = Not same day (includes both New and Old)
- Late FTD = New FTD + Old FTD

---

## Metric Calculation Patterns

### COUNT Metrics

#### Distinct Player Counts
```sql
COUNT(DISTINCT t.player_id) FILTER (WHERE <conditions>) AS unique_players
```

**Example: Unique Depositors**
```sql
COUNT(DISTINCT t.player_id) FILTER (
  WHERE t.transaction_category='deposit'
    AND t.transaction_type='credit'
    AND t.status='completed'
    AND t.balance_type='withdrawable'
) AS unique_depositors
```

#### Transaction Counts
```sql
COUNT(*) FILTER (WHERE <conditions>) AS transaction_count
```

**Example: Number of Deposits**
```sql
COUNT(*) FILTER (
  WHERE t.transaction_category='deposit'
    AND t.transaction_type='credit'
    AND t.status='completed'
    AND t.balance_type='withdrawable'
) AS deposits_count
```

**COUNT(*) vs COUNT(column):**
- `COUNT(*)` counts all rows
- `COUNT(column)` counts non-NULL values
- Use `COUNT(*)` with FILTER for transaction counts

---

### SUM Metrics with Currency Conversion

**Standard Pattern:**
```sql
COALESCE(SUM(CASE
  WHEN <transaction_conditions>
  THEN <currency_conversion_logic>
END), 0) AS metric_name
```

**Why COALESCE(..., 0)?**
- SUM returns NULL if no matching rows
- COALESCE converts NULL to 0 for cleaner output
- Avoids NULL propagation in calculations

**Example: Total Deposit Amount**
```sql
COALESCE(SUM(CASE
  WHEN t.transaction_category='deposit'
   AND t.transaction_type='credit'
   AND t.status='completed'
   AND t.balance_type='withdrawable'
  THEN
    CASE
      WHEN t.currency_type = {{currency_filter}}
      THEN t.amount
      WHEN {{currency_filter}} = 'EUR'
      THEN COALESCE(t.eur_amount, t.amount)
      ELSE t.amount
    END
END), 0) AS deposits_amount
```

---

### Derived Metrics (Calculated from Other Metrics)

#### GGR (Gross Gaming Revenue)
```sql
"GGR" = "Cash Bet" + "Promo Bet" - "Cash Win" - "Promo Win"
```

**In SQL:**
```sql
ROUND(
  COALESCE(bet.cash_bet, 0) +
  COALESCE(bet.promo_bet, 0) -
  COALESCE(bet.cash_win, 0) -
  COALESCE(bet.promo_win, 0),
2) AS "GGR"
```

#### Cash GGR
```sql
"Cash GGR" = "Cash Bet" - "Cash Win"
```

**In SQL:**
```sql
ROUND(
  COALESCE(bet.cash_bet, 0) -
  COALESCE(bet.cash_win, 0),
2) AS "Cash GGR"
```

#### Turnover
```sql
"Turnover" = "Cash Bet" + "Promo Bet"
```

#### CashFlow
```sql
"CashFlow" = "Deposits" - "Withdrawals"
```

---

### Percentage and Ratio Metrics

**Standard Pattern with Zero Division Protection:**
```sql
ROUND(
  CASE WHEN <denominator> > 0
    THEN (<numerator> / <denominator>) * 100
    ELSE 0
  END,
2) AS "Percentage Metric"
```

**Example: FTD Conversion Rate**
```sql
ROUND(
  CASE WHEN COALESCE(r.total_registrations, 0) > 0
    THEN COALESCE(fm.ftds_count, 0)::numeric / r.total_registrations * 100
    ELSE 0
  END,
2) AS "%Conversion total reg"
```

**Why ::numeric cast?**
- Integer division in PostgreSQL truncates: `5 / 2 = 2`
- Casting to numeric preserves decimals: `5::numeric / 2 = 2.5`

**Example: Payout Percentage**
```sql
ROUND(
  CASE WHEN (COALESCE(bet.cash_bet, 0) + COALESCE(bet.promo_bet, 0)) > 0
    THEN (COALESCE(bet.cash_win, 0) + COALESCE(bet.promo_win, 0)) /
         (COALESCE(bet.cash_bet, 0) + COALESCE(bet.promo_bet, 0)) * 100
    ELSE 0
  END,
2) AS "Payout %"
```

---

### New Metrics (CTO-Approved)

#### Bonus Cost Ratio
**Formula:**
```
Bonus Cost Ratio = (Bonus Cost / Granted Bonus) × 100
```

**SQL:**
```sql
ROUND(
  CASE WHEN COALESCE(gb.granted_bonus_amount, 0) > 0
    THEN COALESCE(bcost.total_bonus_cost, 0) / gb.granted_bonus_amount * 100
    ELSE 0
  END,
2) AS "Bonus Cost Ratio"
```

**Business Meaning:**
- Shows what % of granted bonuses were converted to cash
- Lower is better for casino (more forfeited bonuses)
- Example: 30% means €30 converted for every €100 granted

---

#### Turnover Factor
**Formula:**
```
Turnover Factor = Total Turnover / Total Deposits
```

**SQL:**
```sql
ROUND(
  CASE WHEN COALESCE(dm.deposits_amount, 0) > 0
    THEN (COALESCE(bet.cash_bet, 0) + COALESCE(bet.promo_bet, 0)) / dm.deposits_amount
    ELSE 0
  END,
2) AS "Turnover Factor"
```

**Business Meaning:**
- Shows how many times players bet their deposits
- Higher is better (more engaged players)
- Example: 2.5 means players bet €2.50 for every €1 deposited

---

# PART III: Building a Report Step-by-Step

## Complete Example: Building a Daily KPI Report

Let's build a simplified Daily KPI report from scratch, following all standards.

### Step 1: Define Requirements

**Report Name:** Daily Player Activity
**Time Period:** Day-by-day with TOTAL row
**Metrics:**
- Registrations
- FTDs
- Deposits (count and amount)
- Active Players

**Filters:**
- Date range (start_date, end_date)
- Currency

---

### Step 2: Set Up Input Parameters

```sql
WITH
/* Capture date inputs */
start_input AS (
  SELECT NULL::date AS start_date WHERE FALSE
  [[ UNION ALL SELECT {{start_date}}::date ]]
),
end_input AS (
  SELECT NULL::date AS end_date WHERE FALSE
  [[ UNION ALL SELECT {{end_date}}::date ]]
),
```

**Test:** Run in Metabase. If user provides dates, they appear. If not, no error.

---

### Step 3: Calculate Date Bounds

```sql
/* Normalize and validate date range */
bounds_raw AS (
  SELECT
    COALESCE((SELECT MAX(end_date) FROM end_input), CURRENT_DATE) AS end_date_raw,
    (SELECT MAX(start_date) FROM start_input) AS start_date_raw
),
bounds AS (
  SELECT
    end_date_raw AS end_date,
    CASE
      WHEN start_date_raw IS NULL THEN end_date_raw - INTERVAL '31 day'
      WHEN start_date_raw > end_date_raw THEN end_date_raw
      ELSE start_date_raw
    END AS start_date
  FROM bounds_raw
),
```

**Test:** Query `SELECT * FROM bounds` → Should return 1 row with valid date range.

---

### Step 4: Generate Date Series

```sql
/* Create a row for each day */
date_series AS (
  SELECT
    d::date AS report_date,
    d AS start_ts,
    LEAST(d + INTERVAL '1 day', NOW()) AS end_ts
  FROM generate_series(
    (SELECT start_date FROM bounds),
    (SELECT end_date FROM bounds),
    INTERVAL '1 day'
  ) AS d
),
```

**Test:** Query `SELECT * FROM date_series` → Should return one row per day in range.

---

### Step 5: Filter Players

```sql
/* Pre-filter players by criteria */
filtered_players AS (
  SELECT DISTINCT players.id AS player_id
  FROM players
  LEFT JOIN companies ON companies.id = players.company_id
  WHERE 1=1
    -- Add Field Filters as needed
),
```

**Test:** Query `SELECT COUNT(*) FROM filtered_players` → Should return player count.

---

### Step 6: Player Registration CTE

```sql
/* Get player registration data */
player_reg AS (
  SELECT DISTINCT
    p.id AS player_id,
    p.created_at AS registration_ts
  FROM players p
  INNER JOIN filtered_players fp ON p.id = fp.player_id
  LEFT JOIN player_balances pb ON pb.player_id = p.id
    AND pb.balance_type = 'withdrawable'
  WHERE 1=1
    [[ AND ({{currency_filter}} = 'EUR' OR pb.currency_type IN ({{currency_filter}})) ]]
),

/* Count registrations by day */
registrations AS (
  SELECT
    ds.report_date,
    COUNT(pr.*) AS total_registrations
  FROM date_series ds
  LEFT JOIN player_reg pr
    ON pr.registration_ts >= ds.start_ts
    AND pr.registration_ts < ds.end_ts
  GROUP BY ds.report_date
),
```

**Test:** Query `SELECT * FROM registrations` → Should show registrations per day.

---

### Step 7: FTD Logic

```sql
/* Find all deposits ranked by player */
ftd_all_deposits AS (
  SELECT
    t.player_id,
    t.created_at,
    ROW_NUMBER() OVER (PARTITION BY t.player_id ORDER BY t.created_at ASC) as deposit_rank
  FROM transactions t
  INNER JOIN filtered_players fp ON t.player_id = fp.player_id
  WHERE t.transaction_category = 'deposit'
    AND t.transaction_type = 'credit'
    AND t.status = 'completed'
    AND t.balance_type = 'withdrawable'
    [[ AND ({{currency_filter}} = 'EUR' OR t.currency_type IN ({{currency_filter}})) ]]
),

/* Extract first deposits in date range */
ftd_first AS (
  SELECT
    player_id,
    created_at AS first_deposit_ts
  FROM ftd_all_deposits
  WHERE deposit_rank = 1
    AND created_at >= (SELECT start_date FROM bounds)
    AND created_at < (SELECT end_date FROM bounds) + INTERVAL '1 day'
),

/* Count FTDs by day */
ftd_metrics AS (
  SELECT
    DATE_TRUNC('day', ff.first_deposit_ts)::date AS report_date,
    COUNT(DISTINCT ff.player_id) AS ftds_count
  FROM ftd_first ff
  GROUP BY DATE_TRUNC('day', ff.first_deposit_ts)::date
),
```

**Test:** Query `SELECT * FROM ftd_metrics` → Should show FTD counts per day.

---

### Step 8: Deposit Metrics

```sql
/* Calculate deposit counts and amounts */
deposit_metrics AS (
  SELECT
    ds.report_date,
    COUNT(*) FILTER (
      WHERE t.transaction_category='deposit'
        AND t.transaction_type='credit'
        AND t.status='completed'
        AND t.balance_type='withdrawable'
    ) AS deposits_count,
    COALESCE(SUM(CASE
      WHEN t.transaction_category='deposit'
       AND t.transaction_type='credit'
       AND t.status='completed'
       AND t.balance_type='withdrawable'
      THEN
        CASE
          WHEN t.currency_type = {{currency_filter}}
          THEN t.amount
          WHEN {{currency_filter}} = 'EUR'
          THEN COALESCE(t.eur_amount, t.amount)
          ELSE t.amount
        END
    END), 0) AS deposits_amount
  FROM date_series ds
  LEFT JOIN transactions t
    ON t.created_at >= ds.start_ts
    AND t.created_at < ds.end_ts
  INNER JOIN filtered_players fp ON t.player_id = fp.player_id
  WHERE 1=1
    [[ AND ({{currency_filter}} = 'EUR' OR t.currency_type IN ({{currency_filter}})) ]]
  GROUP BY ds.report_date
),
```

**Test:** Query `SELECT * FROM deposit_metrics` → Should show deposits per day.

---

### Step 9: Active Player Metrics

```sql
/* Count active players */
active_players AS (
  SELECT
    ds.report_date,
    COUNT(DISTINCT t.player_id) FILTER (
      WHERE t.transaction_category='game_bet'
    ) AS active_players_count
  FROM date_series ds
  LEFT JOIN transactions t
    ON t.created_at >= ds.start_ts
    AND t.created_at < ds.end_ts
  INNER JOIN filtered_players fp ON t.player_id = fp.player_id
  WHERE 1=1
    [[ AND ({{currency_filter}} = 'EUR' OR t.currency_type IN ({{currency_filter}})) ]]
  GROUP BY ds.report_date
),
```

**Test:** Query `SELECT * FROM active_players` → Should show player counts per day.

---

### Step 10: Assemble Daily Data

```sql
/* Combine all metrics for each day */
daily_data AS (
  SELECT
    0 as sort_order,  -- For ordering (data rows)
    ds.report_date::text AS "Date",
    COALESCE(r.total_registrations, 0) AS "Registrations",
    COALESCE(fm.ftds_count, 0) AS "FTDs",
    COALESCE(dm.deposits_count, 0) AS "Deposits",
    ROUND(COALESCE(dm.deposits_amount, 0), 2) AS "Deposit Amount",
    COALESCE(ap.active_players_count, 0) AS "Active Players"
  FROM date_series ds
  LEFT JOIN registrations r ON r.report_date = ds.report_date
  LEFT JOIN ftd_metrics fm ON fm.report_date = ds.report_date
  LEFT JOIN deposit_metrics dm ON dm.report_date = ds.report_date
  LEFT JOIN active_players ap ON ap.report_date = ds.report_date
)
```

**Test:** Query `SELECT * FROM daily_data` → Should show one row per day with all metrics.

---

### Step 11: Create TOTAL Row and Final Output

```sql
/* Create TOTAL summary row and combine with daily rows */
SELECT
  -1 as sort_order,  -- TOTAL row sorts first
  'TOTAL' AS "Date",
  SUM("Registrations") AS "Registrations",
  SUM("FTDs") AS "FTDs",
  SUM("Deposits") AS "Deposits",
  ROUND(SUM("Deposit Amount"), 2) AS "Deposit Amount",

  -- Active Players for TOTAL: unique count across entire period
  (SELECT COUNT(DISTINCT t.player_id)
   FROM transactions t
   INNER JOIN filtered_players fp ON t.player_id = fp.player_id
   WHERE t.transaction_category='game_bet'
     AND t.created_at >= (SELECT start_date FROM bounds)
     AND t.created_at < (SELECT end_date FROM bounds) + INTERVAL '1 day'
     [[ AND ({{currency_filter}} = 'EUR' OR t.currency_type IN ({{currency_filter}})) ]]
  ) AS "Active Players"
FROM daily_data

UNION ALL

SELECT * FROM daily_data

ORDER BY sort_order, "Date" DESC;
```

**Why subquery for Active Players in TOTAL?**
- Daily active players sum to more than unique players (same player active multiple days)
- TOTAL needs COUNT(DISTINCT) across entire period, not SUM of daily counts

---

### Complete Report

Put all sections together:

```sql
WITH
start_input AS (...),
end_input AS (...),
bounds_raw AS (...),
bounds AS (...),
date_series AS (...),
filtered_players AS (...),
player_reg AS (...),
registrations AS (...),
ftd_all_deposits AS (...),
ftd_first AS (...),
ftd_metrics AS (...),
deposit_metrics AS (...),
active_players AS (...),
daily_data AS (...)

SELECT ... FROM daily_data  -- TOTAL row
UNION ALL
SELECT * FROM daily_data
ORDER BY sort_order, "Date" DESC;
```

---

## Testing & Validation

### Unit Testing Each CTE

Test CTEs individually by querying them directly:

```sql
-- Test 1: Check bounds
SELECT * FROM bounds;
-- Expected: 1 row with start_date and end_date

-- Test 2: Check date series
SELECT COUNT(*) FROM date_series;
-- Expected: Number of days in range

-- Test 3: Check filtered players
SELECT COUNT(*) FROM filtered_players;
-- Expected: Number of players matching filters

-- Test 4: Check registrations
SELECT * FROM registrations ORDER BY report_date;
-- Expected: Registrations per day

-- Test 5: Check FTDs
SELECT * FROM ftd_metrics ORDER BY report_date;
-- Expected: FTD counts per day
```

### Validation Queries

#### Validate Deposit Amounts
```sql
-- Compare report total with direct query
SELECT SUM(amount)
FROM transactions
WHERE transaction_category='deposit'
  AND transaction_type='credit'
  AND status='completed'
  AND balance_type='withdrawable'
  AND created_at >= '2025-01-01'
  AND created_at < '2025-02-01';
-- Should match report TOTAL for January
```

#### Validate Player Counts
```sql
-- Check distinct players
SELECT COUNT(DISTINCT player_id)
FROM transactions
WHERE transaction_category='game_bet'
  AND created_at >= '2025-01-01'
  AND created_at < '2025-02-01';
-- Should match "Active Players" TOTAL for January
```

---

## Performance Optimization

### 1. Early Filtering

**Principle:** Filter data as early as possible in the query.

**❌ Bad:**
```sql
-- Filter AFTER joining all data
SELECT COUNT(*)
FROM transactions t
JOIN players p ON p.id = t.player_id
WHERE p.country = 'US'  -- Late filter
  AND t.created_at >= '2025-01-01';
```

**✅ Good:**
```sql
-- Filter BEFORE joining
WITH filtered_players AS (
  SELECT id FROM players WHERE country = 'US'  -- Early filter
),
metrics AS (
  SELECT COUNT(*)
  FROM transactions t
  INNER JOIN filtered_players fp ON t.player_id = fp.player_id
  WHERE t.created_at >= '2025-01-01'
)
```

---

### 2. Appropriate Indexes

Ensure these indexes exist:

```sql
-- Transactions table
CREATE INDEX idx_tx_created_at ON transactions(created_at);
CREATE INDEX idx_tx_player_id ON transactions(player_id);
CREATE INDEX idx_tx_category_type ON transactions(transaction_category, transaction_type);
CREATE INDEX idx_tx_currency ON transactions(currency_type);

-- Players table
CREATE INDEX idx_players_created_at ON players(created_at);
CREATE INDEX idx_players_country ON players(country);
CREATE INDEX idx_players_company_id ON players(company_id);

-- Player balances
CREATE INDEX idx_pb_player_currency ON player_balances(player_id, currency_type, balance_type);
```

---

### 3. Avoid N+1 Queries

**❌ Bad: Subquery per row**
```sql
SELECT
  ds.report_date,
  (SELECT COUNT(*)
   FROM transactions t
   WHERE DATE(t.created_at) = ds.report_date
  ) AS tx_count  -- Executes once PER ROW
FROM date_series ds;
```

**✅ Good: Single join**
```sql
SELECT
  ds.report_date,
  COUNT(t.id) AS tx_count
FROM date_series ds
LEFT JOIN transactions t
  ON DATE(t.created_at) = ds.report_date
GROUP BY ds.report_date;  -- Single scan of transactions
```

---

### 4. Use FILTER Instead of Multiple CASE Statements

**❌ Slower:**
```sql
SELECT
  SUM(CASE WHEN status='completed' THEN amount END) AS completed,
  SUM(CASE WHEN status='pending' THEN amount END) AS pending
FROM transactions;
```

**✅ Faster:**
```sql
SELECT
  SUM(amount) FILTER (WHERE status='completed') AS completed,
  SUM(amount) FILTER (WHERE status='pending') AS pending
FROM transactions;
```

---

# PART IV: Standard Formulas Reference

## Registration Metrics

| Metric | Formula | SQL Example |
|--------|---------|-------------|
| Total Registrations | COUNT(players) | `COUNT(pr.*)` |
| Complete Registrations | COUNT(WHERE email_verified) | `COUNT(CASE WHEN pr.email_verified THEN 1 END)` |

---

## Deposit/Withdrawal Metrics

| Metric | Formula | SQL Pattern |
|--------|---------|-------------|
| Deposit Count | COUNT(deposits) | `COUNT(*) FILTER (WHERE category='deposit' AND ...)` |
| Deposit Amount | SUM(amount) | See Currency Conversion Pattern |
| Unique Depositors | COUNT(DISTINCT player_id) | `COUNT(DISTINCT t.player_id) FILTER (WHERE ...)` |
| Withdrawal Count | COUNT(withdrawals) | Similar to deposits |
| Withdrawal Amount | SUM(ABS(amount)) | Use ABS() for withdrawals |
| CashFlow | Deposits - Withdrawals | `deposits_amount - withdrawals_amount` |

---

## Betting Metrics

| Metric | Formula | Components |
|--------|---------|------------|
| Cash Bet | SUM(cash bets) | `category='game_bet' AND balance_type='withdrawable' AND type='debit'` |
| Cash Win | SUM(cash wins) | `category='game_bet' AND balance_type='withdrawable' AND type='credit'` |
| Promo Bet | SUM(promo bets) | `category='bonus' AND external_transaction_id IS NOT NULL AND type='debit'` |
| Promo Win | SUM(promo wins) | `category='bonus' AND external_transaction_id IS NOT NULL AND type='credit'` |
| Turnover | Cash Bet + Promo Bet | Sum both |
| GGR | (Cash + Promo Bet) - (Cash + Promo Win) | All bets minus all wins |
| Cash GGR | Cash Bet - Cash Win | Real money only |

---

## Bonus Metrics

| Metric | Formula | Filter Logic |
|--------|---------|--------------|
| Granted Bonus | SUM(bonuses given) | Multiple categories, `balance_type='non-withdrawable'`, `player_bonus_id IS NOT NULL` |
| Bonus Cost | SUM(bonuses converted) | `category='bonus_completion'`, `balance_type='withdrawable'` |
| Bonus Cost Ratio | (Bonus Cost / Granted Bonus) × 100 | Percentage |

---

## Conversion and Ratio Metrics

| Metric | Formula | SQL Pattern |
|--------|---------|-------------|
| FTD Conversion | (FTDs / Registrations) × 100 | `ftds::numeric / registrations * 100` |
| Payout % | (Wins / Bets) × 100 | `(cash_win + promo_win) / (cash_bet + promo_bet) * 100` |
| Bonus Ratio (GGR) | (Bonus Cost / GGR) × 100 | `bonus_cost / ggr * 100` |
| Turnover Factor | Turnover / Deposits | `(cash_bet + promo_bet) / deposits_amount` |

---

## Common Pitfalls and Solutions

### Pitfall #1: NULL Propagation

**Problem:**
```sql
SELECT cash_bet - cash_win AS ggr
-- If cash_win is NULL: 100 - NULL = NULL (not 100!)
```

**Solution:**
```sql
SELECT COALESCE(cash_bet, 0) - COALESCE(cash_win, 0) AS ggr
-- If cash_win is NULL: 100 - 0 = 100 ✓
```

---

### Pitfall #2: Integer Division

**Problem:**
```sql
SELECT 5 / 2 AS ratio;  -- Returns 2 (not 2.5!)
```

**Solution:**
```sql
SELECT 5::numeric / 2 AS ratio;  -- Returns 2.5 ✓
```

---

### Pitfall #3: Division by Zero

**Problem:**
```sql
SELECT revenue / deposits AS ratio;
-- If deposits = 0: ERROR!
```

**Solution:**
```sql
SELECT
  CASE WHEN deposits > 0
    THEN revenue / deposits
    ELSE 0
  END AS ratio;
```

---

### Pitfall #4: Time Zone Issues

**Problem:**
```sql
SELECT COUNT(*)
FROM transactions
WHERE DATE(created_at) = '2025-01-15';  -- Which timezone?
```

**Solution:**
```sql
SELECT COUNT(*)
FROM transactions
WHERE created_at >= '2025-01-15 00:00:00'
  AND created_at < '2025-01-16 00:00:00';  -- Explicit range
```

---

### Pitfall #5: Duplicate Rows from JOINs

**Problem:**
```sql
SELECT COUNT(*)
FROM players p
LEFT JOIN player_balances pb ON pb.player_id = p.id;
-- If player has 2 balances, counted twice!
```

**Solution:**
```sql
SELECT COUNT(DISTINCT p.id)  -- Or use DISTINCT in CTE
FROM players p
LEFT JOIN player_balances pb ON pb.player_id = p.id;
```

---

## Troubleshooting Guide

### Issue: Report Returns No Data

**Check List:**
1. ✓ Are date bounds correct? `SELECT * FROM bounds;`
2. ✓ Is date series generating? `SELECT * FROM date_series;`
3. ✓ Are there any players? `SELECT COUNT(*) FROM filtered_players;`
4. ✓ Are transactions in range? `SELECT COUNT(*) FROM transactions WHERE created_at >= ... AND created_at < ...;`
5. ✓ Are Field Filters too restrictive?

---

### Issue: Wrong Currency Amounts

**Check List:**
1. ✓ Is currency filter correct? `SELECT {{currency_filter}};`
2. ✓ Is `eur_amount` NULL for some transactions? `SELECT COUNT(*) FROM transactions WHERE eur_amount IS NULL;`
3. ✓ Is fallback logic using `COALESCE(eur_amount, amount)` not `COALESCE(eur_amount, 0)`?
4. ✓ Is 3-level hierarchy implemented correctly?

---

### Issue: FTD Counts Don't Match

**Check List:**
1. ✓ Is `balance_type = 'withdrawable'` filter applied?
2. ✓ Is currency filter applied in `ftd_all_deposits`?
3. ✓ Is `ROW_NUMBER()` partitioned by player_id?
4. ✓ Is date range filter in `ftd_first` correct?

---

### Issue: TOTAL Row Shows Wrong Values

**Check List:**
1. ✓ Are you using SUM() for summ able metrics?
2. ✓ Are you using subqueries for DISTINCT counts (active players)?
3. ✓ Are percentage calculations using period-level data, not sums?

---

## Summary Checklist for New Reports

Use this checklist when creating a new report:

**Structure:**
- [ ] Input parameter CTEs (start_input, end_input)
- [ ] Bounds calculation with defaults
- [ ] Date/month series generation
- [ ] filtered_players CTE with Field Filters
- [ ] player_reg CTE with currency filter
- [ ] All metric CTEs
- [ ] Final data assembly CTE
- [ ] TOTAL row + data rows with UNION ALL

**Currency Handling:**
- [ ] WHERE clause: `({{currency_filter}} = 'EUR' OR t.currency_type IN ({{currency_filter}}))`
- [ ] CASE statement: 3-level hierarchy (native → EUR → fallback)
- [ ] EUR conversion: `COALESCE(t.eur_amount, t.amount)` not `COALESCE(t.eur_amount, 0)`

**Transaction Filters:**
- [ ] Correct transaction_category
- [ ] Correct transaction_type (credit/debit)
- [ ] Status = 'completed'
- [ ] Correct balance_type
- [ ] Promo bets: `external_transaction_id IS NOT NULL`
- [ ] Granted bonus: `player_bonus_id IS NOT NULL`

**Joins:**
- [ ] INNER JOIN to filtered_players
- [ ] JOIN to players table
- [ ] JOIN to companies table
- [ ] LEFT JOIN to date_series (for time-based metrics)

**Performance:**
- [ ] Early filtering
- [ ] Appropriate indexes exist
- [ ] No N+1 query patterns
- [ ] Use FILTER where possible

**Testing:**
- [ ] Test each CTE individually
- [ ] Validate totals against direct queries
- [ ] Test with/without Field Filters
- [ ] Test with different currencies
- [ ] Test edge cases (no data, zero amounts)

---

**End of SQL Reporting Engineering Textbook**

**Document Owner:** Data Engineering Team
**Version:** 1.0
**Last Updated:** November 19, 2025
**Status:** CTO-Approved Standard
