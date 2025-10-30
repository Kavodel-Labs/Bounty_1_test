# BTB Gaming Analytics Dashboard - Comprehensive Action Plan

**Project:** Standardization and Optimization of Metabase Analytics Reports
**Date:** October 30, 2025
**Status:** Ready for Implementation

---

## Executive Summary

### Current State

The BTB analytics infrastructure demonstrates **professional-grade architecture** with well-designed CTEs, comprehensive filtering, and exceptional documentation. However, critical inconsistencies threaten data accuracy and maintainability:

**Strengths:**
- ✅ Exemplary currency handling with robust COALESCE logic
- ✅ Professional CTE architecture for separation of concerns
- ✅ Comprehensive filtering (brand, geography, traffic, device, test accounts)
- ✅ High-quality inline documentation explaining intent

**Critical Issues:**
- ❌ Filter bugs causing silent data discrepancies (device filter, date parameters)
- ❌ Widespread code duplication (14+ queries with 95% identical logic)
- ❌ Inconsistent naming conventions across reports
- ❌ Missing TOTAL rows in 12 cohort reports
- ❌ Performance issues with multiple full table scans
- ❌ Ambiguous metric definitions (Bonus Cost vs Bonus Converted)

### Investment & ROI

**Total Effort:** ~38 hours over 4-6 weeks
- Development: ~20 hours
- Testing & Validation: ~8 hours
- Documentation: ~6 hours
- Training & Communication: ~4 hours

**Expected ROI:** $6,000-12,000 annually
- 50% reduction in support tickets
- 30% faster new report creation
- Foundation for scaling from 15 to 50+ reports
- Payback period: ~1.5 months

---

## Deep Dive: Code Analysis

### Report Inventory

After thorough analysis, the codebase contains **approximately 13-15 distinct reports**:

#### KPI Reports (2)
1. **Daily KPIs** - Multi-day view with TOTAL row
2. **Monthly KPIs** - Multi-month view with TOTAL row

#### Cohort Reports (12)
3. **New Depositors Cohort** - Absolute counts
4. **New Depositors Cohort (%)** - Percentage values
5. **Depositors Cohort** - Absolute retention counts
6. **Depositors Cohort (%)** - Percentage retention
7. **Deposit Amounts Cohort** - Total amounts by cohort
8. **Deposit Amounts Cohort (%)** - Amounts as % of Month 0
9. **GGR Cohort** - GGR by cohort over time
10. **GGR Cohort (%)** - GGR as % of Month 0
11. **Active Players Cohort** - Player activity counts
12. **Active Players Cohort (%)** - Activity percentages
13. **LTV by Registration Month** - Lifetime value analysis
14. **Additional cohort variants** (likely 1-2 more)

### Code Duplication Analysis

**Duplicated Components:**

1. **`filtered_players` CTE** - Duplicated in ~14 queries
   - ~100 lines per instance
   - Total duplication: ~1,400 lines
   - Logic: Brand, country, traffic source, affiliate, device, test account filtering

2. **Date/Month Bounds Logic** - Duplicated in ~14 queries
   - ~30 lines per instance
   - Total duplication: ~420 lines
   - Logic: Input handling, default date ranges, boundary calculations

3. **Currency Resolution** - Repeated ~30+ times across all queries
   - ~7 lines per instance
   - Total duplication: ~210 lines
   - Logic: `COALESCE(metadata->>'currency', cash_currency, wallet_currency, company.currency)`

4. **FTD Identification** - Duplicated in ~10 queries
   - ~20 lines per instance
   - Total duplication: ~200 lines
   - Logic: First deposit timestamp per player with filters

5. **Transaction Filtering Patterns** - Repeated throughout
   - Deposit filters: ~5 lines × ~15 instances = ~75 lines
   - Withdrawal filters: ~5 lines × ~10 instances = ~50 lines
   - Game bet filters: ~5 lines × ~10 instances = ~50 lines
   - Bonus filters: ~5 lines × ~10 instances = ~50 lines

**Total Code Duplication: ~2,455 lines** (conservative estimate)
**Reduction Potential: 60-70%** with proper abstractions

---

## Phase 1: Critical Bug Fixes (IMMEDIATE - 2 Hours)

### Priority: 🔴 CRITICAL

These bugs cause **incorrect data** to be displayed, undermining trust in the analytics.

### Bug 1: Device Filter Inconsistency

**Issue:**
- Most reports: `CONCAT(players.os, ' / ', players.browser) = {{registration_launcher}}`
- Monthly KPIs & New Depositors Cohort: `players.os = {{registration_launcher}}`

**Impact:**
When user filters for "iOS / Safari", the broken reports show ALL iOS users (including Chrome, Firefox, etc.), inflating numbers and creating data discrepancies.

**Fix:**
```sql
-- BEFORE (Monthly KPIs line ~688, New Depositors Cohort lines ~1850-1900)
[[ AND players.os = {{registration_launcher}} ]]

-- AFTER (standardize to match Daily KPIs)
[[ AND CONCAT(players.os, ' / ', players.browser) = {{registration_launcher}} ]]
```

**Files to Update:**
- `monthly_kpis.sql` (or equivalent section in Business Overview)
- `new_depositors_cohort.sql`
- `new_depositors_cohort_pct.sql`

**Validation:**
1. Run Daily KPIs filtered for "iOS / Safari"
2. Run Monthly KPIs with same filter
3. Compare player counts - should match exactly
4. Test with 3-4 different device combinations

**Time:** 30 minutes

---

### Bug 2: Date Parameter Naming

**Issue:**
New Depositors Cohort queries use `{{start_month}}` and `{{end_month}}` instead of the standard `{{start_date}}` and `{{end_date}}`.

**Impact:**
Dashboard's universal date filter doesn't work for these reports. Users must manually enter dates, creating perception that dashboard is broken.

**Fix:**
```sql
-- BEFORE
[[ UNION ALL SELECT {{start_month}}::date ]]
[[ UNION ALL SELECT {{end_month}}::date ]]

-- AFTER
[[ UNION ALL SELECT {{start_date}}::date ]]
[[ UNION ALL SELECT {{end_date}}::date ]]
```

**Files to Update:**
- `new_depositors_cohort.sql`
- `new_depositors_cohort_pct.sql`

**Validation:**
1. Open dashboard with date filter
2. Select date range
3. Verify New Depositors Cohort reports update correctly
4. Check all cohort reports respond to same date filter

**Time:** 20 minutes

---

### Bug 3: Bonus Metrics Clarification

**Issue:**
"Bonus Converted" and "Bonus Cost" use identical calculations, creating stakeholder confusion.

**Impact:**
Finance and Product teams can't determine true cost of bonus promotions. Unclear if metric includes only principal bonus or principal + winnings.

**Investigation Required:**
```sql
-- Run this query to understand bonus_completion transaction content
SELECT
  transaction_category,
  transaction_type,
  balance_type,
  COUNT(*) as transaction_count,
  AVG(amount) as avg_amount,
  SUM(amount) as total_amount,
  MIN(created_at) as earliest,
  MAX(created_at) as latest
FROM transactions
WHERE transaction_category = 'bonus_completion'
  AND status = 'completed'
GROUP BY transaction_category, transaction_type, balance_type;

-- Compare to bonus credits
SELECT
  transaction_category,
  transaction_type,
  balance_type,
  COUNT(*) as transaction_count,
  SUM(amount) as total_amount
FROM transactions
WHERE transaction_category = 'bonus'
  AND transaction_type = 'credit'
  AND status = 'completed'
GROUP BY transaction_category, transaction_type, balance_type;
```

**Fix Options:**

**Option A:** If bonus_completion = principal only
```sql
-- Keep Bonus Converted as-is
COALESCE(SUM(CASE
  WHEN t.transaction_type='credit'
   AND t.transaction_category='bonus_completion'
   AND t.status='completed'
   AND t.balance_type='withdrawable'
THEN t.amount END), 0) AS bonus_converted_amount,

-- Define Bonus Cost = principal + wins
-- (requires additional query logic or new transaction category)
```

**Option B:** If bonus_completion = principal + wins
```sql
-- Rename "Bonus Converted" → "Bonus Converted (Gross)"
-- Add comment explaining it includes winnings
-- Keep "Bonus Cost" = same metric with clear documentation
```

**Deliverable:**
- Document finding in SQL comments
- Add clarifying column descriptions in Metabase
- Update data dictionary

**Time:** 1 hour

---

## Phase 2: Standardization (THIS WEEK - 12 Hours)

### Priority: 🟡 HIGH

### Task 1: Implement Standard Naming Convention

**Current Problems:**
- `"#Registrations"`, `"REG"`, `"total_registrations"` - same metric, 3 names
- `"GGR"`, `"ggr"`, `"ggr_amount"` - inconsistent capitalization
- Special characters (#, %, spaces) complicate querying

**Solution: Adopt Clear Pattern**

```
{metric}_{type}_{modifier}

Types:
- count    (counting records)
- amount   (monetary values)
- pct      (percentages as numbers)
- rate     (ratios)
- avg      (averages)

Modifiers:
- total, unique, active, new, old, etc.
- Time periods: m1, m3, m6, m12 (for time-locked metrics)
```

**Naming Standard Reference:**

| Current Name | Standard Name | Type | Description |
|--------------|---------------|------|-------------|
| #Registrations | `registrations_count` | count | Total player registrations |
| #FTDs | `ftd_count` | count | First-time depositors |
| #New FTDs | `ftd_count_new` | count | FTDs in registration month |
| #Old FTDs | `ftd_count_old` | count | FTDs after registration month |
| #D0 FTDs | `ftd_count_d0` | count | Same-day FTDs |
| %New FTDs | `ftd_pct_new` | pct | % of FTDs that are new |
| %Conversion total reg | `conversion_pct_total_reg` | pct | FTD/registrations ratio |
| %Conversion complete reg | `conversion_pct_complete_reg` | pct | FTD/verified emails ratio |
| Unique Depositors | `depositors_count_unique` | count | Distinct depositors |
| #Deposits | `deposits_count` | count | Transaction count |
| Deposits Amount | `deposit_amount_total` | amount | Sum of deposit amounts |
| #Withdrawals | `withdrawals_count` | count | Withdrawal transaction count |
| Withdrawals Amount | `withdrawal_amount_total` | amount | Sum of withdrawal amounts |
| %Withdrawals/Deposits | `withdrawal_pct_of_deposits` | pct | Withdrawal/deposit ratio |
| CashFlow | `cashflow_amount` | amount | Deposits - withdrawals |
| Active Players | `players_count_active` | count | Players with game activity |
| Real Active Players | `players_count_active_cash` | count | Players with cash game activity |
| Cash Bet | `bet_amount_cash` | amount | Cash balance bets |
| Cash Win | `win_amount_cash` | amount | Cash balance wins |
| Promo bet | `bet_amount_promo` | amount | Bonus balance bets |
| Promo Win | `win_amount_promo` | amount | Bonus balance wins |
| Turnover | `turnover_amount` | amount | Total bets (cash + promo) |
| GGR | `ggr_amount` | amount | Gross gaming revenue |
| Cash GGR | `ggr_amount_cash` | amount | Cash-only GGR |
| Bonus Converted | `bonus_converted_amount` | amount | Bonuses that became cash |
| Bonus Cost | `bonus_cost_amount` | amount | Total bonus cost |
| Bonus Ratio (GGR) | `bonus_cost_pct_of_ggr` | pct | Bonus cost / GGR |
| Bonus Ratio (Deposits) | `bonus_cost_pct_of_deposits` | pct | Bonus cost / deposits |
| Payout % | `payout_pct` | pct | Win / bet ratio |
| %CashFlow to GGR | `cashflow_pct_of_ggr` | pct | Cashflow / GGR ratio |

**Implementation Process:**

1. **Update SQL queries** (6 hours)
   - Edit final SELECT statements in all 14 reports
   - Use Find & Replace carefully
   - Test each query after renaming

2. **Update Metabase** (3 hours)
   - Update column mappings in dashboard cards
   - Fix any broken visualizations
   - Update custom formatting
   - Verify filters still work

3. **Update documentation** (1 hour)
   - Create data dictionary with new names
   - Document naming patterns
   - Share with team

**Validation:**
- Run all dashboards and verify no broken cards
- Check that filters still wire correctly
- Verify custom formatting preserved
- Compare output values before/after (should be identical)

**Time:** 10 hours

---

### Task 2: Add TOTAL Rows to Cohort Reports

**Issue:**
Daily and Monthly KPI reports have TOTAL summary rows, but all 12 cohort reports don't. Users must manually aggregate for period-wide analysis.

**Solution:**
Apply the pattern from Daily/Monthly KPIs to all cohort reports.

**Pattern:**
```sql
-- At the end of the query, replace:
SELECT * FROM final_report_data
ORDER BY cohort_month DESC;

-- With:
-- TOTAL ROW
SELECT
  -1 AS sort_order,
  'TOTAL' AS cohort_month,
  SUM(cohort_size) AS cohort_size,
  SUM(month_0) AS month_0,
  SUM(month_1) AS month_1,
  -- ... sum all numeric columns ...
  -- For percentages, calculate weighted average:
  ROUND(SUM(month_1_numerator) / NULLIF(SUM(month_1_denominator), 0) * 100, 1) AS month_1_pct
FROM final_report_data

UNION ALL

-- REGULAR ROWS
SELECT
  0 AS sort_order,
  *
FROM final_report_data

ORDER BY sort_order, cohort_month DESC;
```

**Reports to Update:**
1. New Depositors Cohort
2. New Depositors Cohort (%)
3. Depositors Cohort
4. Depositors Cohort (%)
5. Deposit Amounts Cohort
6. Deposit Amounts Cohort (%)
7. GGR Cohort
8. GGR Cohort (%)
9. Active Players Cohort
10. Active Players Cohort (%)
11. LTV by Registration Month
12. (Any additional cohort variants)

**Special Handling for Percentage Reports:**
- Can't just SUM percentages (would be mathematically wrong)
- Must calculate: `(total numerator) / (total denominator) * 100`
- Store numerators/denominators in query, then calculate percentage

**Validation:**
- TOTAL row should appear first
- TOTAL values should equal sum of individual rows (for counts/amounts)
- TOTAL percentages should equal overall percentage (not average of percentages)
- Test with filtered data to ensure TOTAL updates correctly

**Time:** 2 hours

---

## Phase 3: Architecture Optimization (THIS MONTH - 16 Hours)

### Priority: 🟠 MEDIUM (High Impact)

### Task 1: Create Metabase SQL Snippets

**Goal:** Eliminate 60% of code duplication by creating reusable snippets.

#### Snippet 1: Currency Resolution

**Name:** `currency_resolution`

**Code:**
```sql
UPPER(COALESCE(
  t.metadata->>'currency',
  t.cash_currency,
  players.wallet_currency,
  companies.currency
))
```

**Usage:**
```sql
-- Before
WHERE [[ AND UPPER(COALESCE(
        t.metadata->>'currency',
        t.cash_currency,
        players.wallet_currency,
        companies.currency
      )) IN ({{currency_filter}}) ]]

-- After
WHERE [[ AND {{ snippet: currency_resolution }} IN ({{currency_filter}}) ]]
```

**Benefit:** Eliminates ~210 lines of duplicated code

---

#### Snippet 2: Player Filter Joins

**Name:** `player_filter_joins`

**Code:**
```sql
LEFT JOIN companies ON companies.id = players.company_id
```

**Usage:**
```sql
-- In filtered_players CTE
SELECT DISTINCT players.id AS player_id
FROM players
{{ snippet: player_filter_joins }}
WHERE 1=1
  [[ AND {{brand}} ]]
  ...
```

---

#### Snippet 3: Country Code Mapping

**Name:** `country_code_case`

**Code:**
```sql
CASE {{country}}
  WHEN 'Romania' THEN 'RO'
  WHEN 'France' THEN 'FR'
  WHEN 'Germany' THEN 'DE'
  WHEN 'Cyprus' THEN 'CY'
  WHEN 'Poland' THEN 'PL'
  WHEN 'Spain' THEN 'ES'
  WHEN 'Italy' THEN 'IT'
  WHEN 'Canada' THEN 'CA'
  WHEN 'Australia' THEN 'AU'
  WHEN 'United Kingdom' THEN 'GB'
  WHEN 'Finland' THEN 'FI'
  WHEN 'Albania' THEN 'AL'
  WHEN 'Austria' THEN 'AT'
  WHEN 'Belgium' THEN 'BE'
  WHEN 'Brazil' THEN 'BR'
  WHEN 'Bulgaria' THEN 'BG'
  WHEN 'Georgia' THEN 'GE'
  WHEN 'Greece' THEN 'GR'
  WHEN 'Hungary' THEN 'HU'
  WHEN 'India' THEN 'IN'
  WHEN 'Netherlands' THEN 'NL'
  WHEN 'Portugal' THEN 'PT'
  WHEN 'Singapore' THEN 'SG'
  WHEN 'Turkey' THEN 'TR'
  WHEN 'United Arab Emirates' THEN 'AE'
  WHEN 'Afghanistan' THEN 'AF'
  WHEN 'Armenia' THEN 'AM'
  WHEN 'Denmark' THEN 'DK'
  WHEN 'Algeria' THEN 'DZ'
  WHEN 'Andorra' THEN 'AD'
END
```

**Usage:**
```sql
WHERE [[ AND players.country = {{ snippet: country_code_case }} ]]
```

**Benefit:** Eliminates ~50 lines per query × 14 queries = ~700 lines

---

#### Snippet 4: FTD Transaction Filters

**Name:** `ftd_transaction_filters`

**Code:**
```sql
WHERE t.transaction_category = 'deposit'
  AND t.transaction_type = 'credit'
  AND t.status = 'completed'
  AND t.balance_type = 'withdrawable'
```

**Usage:**
```sql
-- In FTD identification queries
SELECT
  t.player_id,
  MIN(t.created_at) AS first_deposit_ts
FROM transactions t
INNER JOIN filtered_players fp ON t.player_id = fp.player_id
{{ snippet: ftd_transaction_filters }}
  [[ AND {{ snippet: currency_resolution }} IN ({{currency_filter}}) ]]
GROUP BY t.player_id
```

---

#### Snippet 5: Traffic Source Logic

**Name:** `traffic_source_filter`

**Code:**
```sql
[[ AND CASE
  WHEN {{traffic_source}} = 'Organic'   THEN players.affiliate_id IS NULL
  WHEN {{traffic_source}} = 'Affiliate' THEN players.affiliate_id IS NOT NULL
  ELSE TRUE
END ]]
```

---

**Implementation Plan:**

1. **Create snippets in Metabase** (1 hour)
   - Settings → Admin → SQL Snippets
   - Create each snippet with clear name and description
   - Test syntax by using in a sample query

2. **Update queries to use snippets** (4 hours)
   - Start with one report, test thoroughly
   - Roll out to remaining reports
   - Keep original queries backed up

3. **Test thoroughly** (1 hour)
   - Run each query with various filter combinations
   - Compare results before/after snippet implementation
   - Verify dashboard filters still work

**Total Time:** 6 hours

---

### Task 2: Create Metabase Models

**Goal:** Provide reusable base datasets that reduce query complexity.

#### Model 1: filtered_players_base

**Purpose:** Pre-filtered player list that all reports can reference

**Query:**
```sql
SELECT DISTINCT
  players.id AS player_id,
  players.created_at AS registration_ts,
  players.email_verified,
  players.company_id,
  players.country,
  players.os,
  players.browser,
  CONCAT(players.os, ' / ', players.browser) AS device,
  players.affiliate_id,
  players.is_test_account,
  companies.name AS brand_name,
  companies.currency AS company_currency
FROM players
LEFT JOIN companies ON companies.id = players.company_id
WHERE 1=1
  [[ AND {{brand}} ]]
  [[ AND players.country = {{ snippet: country_code_case }} ]]
  [[ AND {{ snippet: traffic_source_filter }} ]]
  [[ AND {{affiliate_id}} ]]
  [[ AND {{affiliate_name}} ]]
  [[ AND CONCAT(players.os, ' / ', players.browser) = {{registration_launcher}} ]]
  [[ AND {{is_test_account}} ]]
```

**Metadata to Define:**
- `player_id` → ID (Entity Key)
- `registration_ts` → Creation Timestamp
- `brand_name` → Category
- `country` → Category (with display name mapping)
- `device` → Category
- All boolean fields → Yes/No

**Usage in Reports:**
```sql
-- Instead of defining filtered_players CTE every time
WITH player_base AS (
  SELECT * FROM {{#filtered_players_base}}
),
...
```

**Benefit:**
- Eliminates ~100 lines per query
- Ensures 100% consistency in player filtering
- Single place to update filter logic

---

#### Model 2: player_daily_metrics

**Purpose:** Pre-aggregated daily transaction metrics per player (for performance)

**Implementation Strategy:**

**Option A: Metabase Model (Easier)**
```sql
-- Save as model: player_daily_metrics
SELECT
  t.player_id,
  DATE_TRUNC('day', t.created_at)::date AS activity_date,

  -- Deposits
  COUNT(*) FILTER (
    WHERE t.transaction_category='deposit'
      AND t.transaction_type='credit'
      AND t.status='completed'
      AND t.balance_type='withdrawable'
  ) AS deposits_count,
  COALESCE(SUM(t.amount) FILTER (
    WHERE t.transaction_category='deposit'
      AND t.transaction_type='credit'
      AND t.status='completed'
      AND t.balance_type='withdrawable'
  ), 0) AS deposit_amount,

  -- Withdrawals
  COUNT(*) FILTER (
    WHERE t.transaction_category='withdrawal'
      AND t.transaction_type='debit'
      AND t.status='completed'
      AND t.balance_type='withdrawable'
  ) AS withdrawals_count,
  COALESCE(SUM(ABS(t.amount)) FILTER (
    WHERE t.transaction_category='withdrawal'
      AND t.transaction_type='debit'
      AND t.status='completed'
      AND t.balance_type='withdrawable'
  ), 0) AS withdrawal_amount,

  -- Gaming activity
  COALESCE(SUM(t.amount) FILTER (
    WHERE t.transaction_type='debit'
      AND t.transaction_category='game_bet'
      AND t.balance_type='withdrawable'
      AND t.status='completed'
  ), 0) AS cash_bet,
  COALESCE(SUM(t.amount) FILTER (
    WHERE t.transaction_type='credit'
      AND t.transaction_category='game_bet'
      AND t.balance_type='withdrawable'
      AND t.status='completed'
  ), 0) AS cash_win,

  -- Bonus activity
  COALESCE(SUM(t.amount) FILTER (
    WHERE t.transaction_type='debit'
      AND t.transaction_category='bonus'
      AND t.balance_type='non-withdrawable'
      AND t.status='completed'
  ), 0) AS promo_bet,
  COALESCE(SUM(t.amount) FILTER (
    WHERE t.transaction_type='credit'
      AND t.status='completed'
      AND t.balance_type='non-withdrawable'
      AND t.transaction_category = 'bonus'
  ), 0) AS promo_win,

  -- Bonus cost
  COALESCE(SUM(t.amount) FILTER (
    WHERE t.transaction_type='credit'
      AND t.balance_type='withdrawable'
      AND t.status='completed'
      AND t.transaction_category='bonus_completion'
  ), 0) AS bonus_cost

FROM transactions t
INNER JOIN {{#filtered_players_base}} fp ON t.player_id = fp.player_id
GROUP BY t.player_id, DATE_TRUNC('day', t.created_at)::date
```

**Option B: Materialized View (Best Performance)**
```sql
-- Run this in database directly (not in Metabase)
CREATE MATERIALIZED VIEW mv_player_daily_metrics AS
SELECT
  -- ... (same as Option A) ...
FROM transactions t
GROUP BY t.player_id, DATE_TRUNC('day', t.created_at)::date;

-- Create indexes
CREATE INDEX idx_pdm_player_date ON mv_player_daily_metrics(player_id, activity_date);
CREATE INDEX idx_pdm_date ON mv_player_daily_metrics(activity_date);

-- Schedule refresh (via cron or DB scheduler)
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_player_daily_metrics;
```

**Refresh Strategy:**
- Hourly during business hours (8am - 8pm)
- Every 4 hours overnight
- Manual refresh on-demand for urgent reports

**Usage in KPI Reports:**
```sql
-- Instead of scanning transactions table multiple times
WITH daily_metrics AS (
  SELECT
    ds.report_date,
    SUM(pdm.deposits_count) as total_deposits_count,
    SUM(pdm.deposit_amount) as total_deposit_amount,
    -- ... etc ...
  FROM date_series ds
  LEFT JOIN mv_player_daily_metrics pdm
    ON pdm.activity_date = ds.report_date
  INNER JOIN {{#filtered_players_base}} fp
    ON pdm.player_id = fp.player_id
  GROUP BY ds.report_date
)
SELECT * FROM daily_metrics;
```

**Performance Improvement:**
- Before: 5-10 full table scans on transactions (can take 30-120 seconds)
- After: 1 scan on pre-aggregated daily metrics (can take 1-3 seconds)
- **Expected speedup: 10-40x**

**Time:** 6 hours
- Design and test queries: 3 hours
- Implement as models in Metabase: 1 hour
- Update 2-3 reports to use models: 1 hour
- Test and validate: 1 hour

---

### Task 3: Database Performance Optimization

#### Add Strategic Indexes

**Current bottlenecks:**
- Full table scans on `transactions` table
- Player lookups without indexes on compound keys
- Filtering by company and country without covering indexes

**Indexes to Add:**
```sql
-- Transaction indexes
CREATE INDEX CONCURRENTLY idx_transactions_player_created
  ON transactions(player_id, created_at);

CREATE INDEX CONCURRENTLY idx_transactions_category_status_balance
  ON transactions(transaction_category, status, balance_type)
  INCLUDE (player_id, created_at, amount, transaction_type);

CREATE INDEX CONCURRENTLY idx_transactions_created_category
  ON transactions(created_at, transaction_category)
  WHERE status = 'completed';

-- Player indexes
CREATE INDEX CONCURRENTLY idx_players_company_country
  ON players(company_id, country)
  INCLUDE (id, created_at, os, browser);

CREATE INDEX CONCURRENTLY idx_players_affiliate
  ON players(affiliate_id)
  WHERE affiliate_id IS NOT NULL;

CREATE INDEX CONCURRENTLY idx_players_created
  ON players(created_at)
  INCLUDE (id, company_id, country);

-- Company index
CREATE INDEX CONCURRENTLY idx_companies_name
  ON companies(name);
```

**Implementation:**
- Use `CREATE INDEX CONCURRENTLY` to avoid locking tables
- Run during low-traffic hours
- Monitor index usage after 1 week
- Drop unused indexes

**Expected Impact:**
- 30-50% faster query execution
- Reduced database CPU usage
- Better support for concurrent dashboard users

**Time:** 2 hours (mostly waiting for indexes to build)

---

### Task 4: Consolidate KPI Queries

**Problem:**
Daily and Monthly KPI queries are 95% identical, causing massive duplication.

**Solution Approach:**

**Option A: Create Single Parameterized Query**
```sql
-- Add parameter for granularity
[[ AND {{time_granularity}} ]]  -- 'day' or 'month'

-- Use in date series generation
series AS (
  SELECT
    CASE
      WHEN {{time_granularity}} = 'month'
        THEN DATE_TRUNC('month', d)::date
      ELSE d::date
    END AS report_period,
    -- ... etc
  FROM generate_series(
    (SELECT start_date FROM bounds),
    (SELECT end_date FROM bounds),
    CASE
      WHEN {{time_granularity}} = 'month' THEN INTERVAL '1 month'
      ELSE INTERVAL '1 day'
    END
  ) AS d
)
```

**Option B: Create Base Model + 2 Simple Queries**
1. Create comprehensive player metrics model (player_id, date, all metrics)
2. Daily query: SELECT * FROM model WHERE date IN (date_series) GROUP BY date
3. Monthly query: SELECT * FROM model WHERE date IN (date_series) GROUP BY month

**Recommendation:** Option A for short-term, Option B for long-term

**Time:** 2 hours

---

## Phase 4: Governance & Documentation (ONGOING - 6 Hours/Month)

### Priority: 🟢 MEDIUM (Foundational)

### Task 1: Create SQL Standards Document

**Content:**

1. **File Structure Standards**
   - Header comment with description, dependencies, variables
   - CTE naming conventions
   - Ordering: inputs → bounds → filtering → metrics → aggregation → output
   - Comment frequency and detail level

2. **Naming Conventions**
   - CTEs: descriptive_snake_case
   - Columns: metric_type_modifier
   - Variables: {{snake_case}}
   - Tables/Models: plural_nouns

3. **Filter Implementation**
   - Always use Field Filters for dashboard compatibility
   - Standard variable names across all reports
   - Currency filter cascade pattern
   - Device filter format: `CONCAT(os, ' / ', browser)`

4. **Query Performance Guidelines**
   - Use FILTER clauses over CASE WHEN in aggregations
   - Apply filters in WHERE before aggregations
   - Reuse CTEs instead of repeating subqueries
   - Reference models/snippets over copying code

5. **Code Review Checklist**
   - [ ] All filters match standard patterns
   - [ ] Column names follow naming convention
   - [ ] Currency resolution uses snippet or standard cascade
   - [ ] TOTAL row present where appropriate
   - [ ] Comments explain WHY not just WHAT
   - [ ] Tested with all filter combinations
   - [ ] Performance checked with EXPLAIN

**Deliverable:** `SQL_STANDARDS.md` in repository

**Time:** 2 hours

---

### Task 2: Create Data Dictionary

**Purpose:** Single source of truth for all metric definitions

**Format:**

| Metric Name | Display Name | Calculation | Business Definition | Data Source | Owner | Notes |
|-------------|--------------|-------------|---------------------|-------------|-------|-------|
| `registrations_count` | Registrations | COUNT(DISTINCT players.id) | Total new player accounts created | players table | Product | Includes unverified emails |
| `ftd_count` | First-Time Depositors | COUNT(DISTINCT player_id FROM first_deposits) | Players who made first deposit | transactions table | Finance | Deposit must be completed & withdrawable |
| `conversion_pct_total_reg` | Conversion Rate | (FTDs / Registrations) * 100 | % of registrations becoming depositors | Calculated | Product | Includes unverified emails in denominator |
| ... | ... | ... | ... | ... | ... | ... |

**Sections:**
1. Acquisition Metrics (registrations, FTDs, conversion)
2. Financial Metrics (deposits, withdrawals, cashflow)
3. Gaming Metrics (bets, wins, GGR, turnover)
4. Bonus Metrics (bonus cost, bonus converted, ratios)
5. Retention Metrics (cohorts, LTV, active players)
6. Filters & Dimensions (brand, country, device, currency)

**Deliverable:** `DATA_DICTIONARY.md` + Metabase descriptions

**Time:** 3 hours

---

### Task 3: Document Metabase Models & Snippets

**Create README for each:**

**Snippets Documentation:**
```markdown
# SQL Snippets Reference

## currency_resolution
**Purpose:** Standard currency resolution logic
**Usage:** `{{ snippet: currency_resolution }}`
**Returns:** String (currency code)
**Dependencies:** transactions table must be aliased as 't'

## country_code_case
**Purpose:** Maps country names to ISO codes
**Usage:** `{{ snippet: country_code_case }}`
**Dependencies:** Requires {{country}} parameter
**Returns:** ISO country code (2 letters)
```

**Models Documentation:**
```markdown
# Metabase Models Reference

## filtered_players_base
**Purpose:** Pre-filtered player list based on dashboard filters
**Columns:**
- player_id (ID) - Primary key
- registration_ts (Timestamp) - Account creation
- brand_name (Category) - Company/brand
- device (Category) - OS / Browser combination
**Filters:** brand, country, traffic_source, device, test_account
**Usage:** `SELECT * FROM {{#filtered_players_base}}`
**Refresh:** On-demand (not cached)
```

**Deliverable:** `METABASE_REFERENCE.md`

**Time:** 1 hour

---

### Task 4: Establish Code Review Process

**Process:**

1. **All SQL changes require review**
   - Create pull request or Metabase draft
   - Fill out change description
   - Tag SQL reviewer

2. **Reviewer checks against checklist**
   - SQL Standards compliance
   - Filter consistency
   - Naming convention
   - Performance impact
   - Test coverage

3. **Testing requirements**
   - Run query with all filter combinations
   - Compare against existing reports
   - Check dashboard integration
   - Verify no performance regression

4. **Approval and deployment**
   - Reviewer approves
   - Deploy to production
   - Monitor for issues
   - Update documentation

**Deliverable:** `CODE_REVIEW_PROCESS.md`

**Time:** Regular ongoing process

---

## Phase 5: Break Down Business Overview File

### Priority: 🔵 ORGANIZATIONAL

**Task:** Split `Business Overview_full sql_BTB_11.md` into individual report files

**File Structure:**
```
/sql_reports/
├── kpi/
│   ├── daily_kpis.sql
│   └── monthly_kpis.sql
├── cohort/
│   ├── new_depositors_cohort.sql
│   ├── new_depositors_cohort_pct.sql
│   ├── depositors_cohort.sql
│   ├── depositors_cohort_pct.sql
│   ├── deposit_amounts_cohort.sql
│   ├── deposit_amounts_cohort_pct.sql
│   ├── ggr_cohort.sql
│   ├── ggr_cohort_pct.sql
│   ├── active_players_cohort.sql
│   └── active_players_cohort_pct.sql
├── ltv/
│   └── ltv_by_registration_month.sql
└── README.md
```

**File Header Template:**
```sql
/**
 * Report: [Report Name]
 * Category: [KPI / Cohort / LTV]
 * Description: [What this report shows]
 *
 * Parameters:
 * - {{start_date}} (Date) - Start of reporting period
 * - {{end_date}} (Date) - End of reporting period
 * - {{brand}} (Field Filter) - Companies.name
 * - {{country}} (Field Filter) - Players.country
 * - {{registration_launcher}} (Field Filter) - Players device
 * - {{currency_filter}} (Text) - Currency codes (comma-separated)
 * - {{traffic_source}} (Text) - Organic/Affiliate
 * - {{affiliate_id}} (Field Filter) - Players.affiliate_id
 * - {{is_test_account}} (Field Filter) - Players.is_test_account
 *
 * Dependencies:
 * - Models: filtered_players_base (optional)
 * - Snippets: currency_resolution, country_code_case, traffic_source_filter
 *
 * Output Columns:
 * - [column_name] ([type]) - [description]
 *
 * Last Updated: [Date]
 * Owner: [Team/Person]
 */
```

**Implementation:**
1. Read Business Overview file
2. Identify report boundaries (look for "# report_name" headers)
3. Extract each report to separate file
4. Add standard header to each file
5. Create README with report catalog
6. Organize by category (KPI, Cohort, LTV)

**Time:** 2 hours

---

## Success Metrics & KPIs

### Week 1 (Phase 1 Complete)
- ✅ Monthly KPIs device filter matches Daily KPIs (100% alignment)
- ✅ New Depositors date parameters work with dashboard filter
- ✅ All filters wired correctly
- ✅ Zero data discrepancies between reports

### Week 2-4 (Phase 2 Complete)
- ✅ All 14 reports use consistent column naming
- ✅ All cohort reports have TOTAL rows
- ✅ Support tickets related to data confusion decreased 50%
- ✅ Consistent presentation across all dashboards

### Month 1 (Phase 3 Complete)
- ✅ SQL snippets created and in use
- ✅ At least 1 model deployed (filtered_players_base)
- ✅ Database indexes added
- ✅ Query times improved 30-50%
- ✅ Team onboarding time reduced 30%

### Month 2-3 (Phase 4 Complete)
- ✅ SQL Standards document published
- ✅ Data Dictionary published and adopted
- ✅ Code review process active
- ✅ Zero data consistency incidents
- ✅ New reports deployable without major issues

### Ongoing
- ✅ Dashboard scales from 15 to 25+ reports
- ✅ Query performance maintained under 5 minutes
- ✅ Zero critical bugs in production
- ✅ Team satisfaction with analytics platform high

---

## Risk Mitigation

| Risk | Severity | Mitigation Strategy |
|------|----------|---------------------|
| Filter fix causes different data | HIGH | Test against manual player count before deploy; compare results with sample date range |
| Changes break Metabase dashboards | MEDIUM | Test in staging environment first; keep backup of working queries; document rollback plan |
| Snippet consolidation introduces discrepancies | HIGH | Detailed before/after comparison; test each snippet individually; phased rollout |
| Materialized view refresh fails silently | HIGH | Set up email alerts for failed refreshes; daily verification query; fallback to live data |
| Team resistance to new processes | MEDIUM | Involve team in design; clear communication of benefits; training sessions; gradual adoption |
| Performance doesn't improve as expected | MEDIUM | Benchmark before/after; identify remaining bottlenecks; iterate on optimization |
| Naming convention breaks existing dashboards | HIGH | Update dashboard cards immediately after query changes; test all cards; maintain mapping doc |

---

## Implementation Timeline

```
Week 1 (Nov 1-7):
└─ Phase 1: Critical Fixes
   ├─ Day 1: Fix device filter bug
   ├─ Day 2: Fix date parameter naming
   ├─ Day 3-4: Investigate bonus metrics
   └─ Day 5: Validation and testing

Week 2-3 (Nov 8-21):
└─ Phase 2: Standardization
   ├─ Week 2: Implement naming convention
   │  ├─ Mon-Wed: Update all SQL queries
   │  ├─ Thu: Update Metabase dashboards
   │  └─ Fri: Testing
   └─ Week 3: Add TOTAL rows to cohorts
      ├─ Mon-Thu: Update all cohort reports
      └─ Fri: Testing

Week 4 (Nov 22-28):
└─ Phase 3: Architecture (Part 1)
   ├─ Mon-Tue: Create SQL snippets
   ├─ Wed: Update 3-5 queries to use snippets
   ├─ Thu: Add database indexes
   └─ Fri: Testing and validation

Week 5-6 (Nov 29 - Dec 12):
└─ Phase 3: Architecture (Part 2)
   ├─ Week 5: Create Metabase models
   │  ├─ Mon-Tue: Build filtered_players_base
   │  ├─ Wed-Thu: Build player_daily_metrics
   │  └─ Fri: Test models
   └─ Week 6: Consolidate KPI queries
      └─ Refactor daily/monthly KPIs

Ongoing (Month 2-3):
└─ Phase 4: Governance
   ├─ Create SQL Standards doc
   ├─ Build Data Dictionary
   ├─ Document models/snippets
   └─ Establish code review process

Parallel Task:
└─ Phase 5: Break down Business Overview
   └─ Can be done anytime (2 hours)
```

---

## Resource Allocation

**Roles Required:**

| Role | Phase 1 | Phase 2 | Phase 3 | Phase 4 | Total |
|------|---------|---------|---------|---------|-------|
| SQL Developer | 2h | 10h | 14h | 2h | 28h |
| Metabase Admin | 0.5h | 3h | 2h | - | 5.5h |
| QA/Testing | - | 1h | 2h | - | 3h |
| Analytics Lead | 0.5h | 1h | - | 4h | 5.5h |
| **Total** | **2h** | **12h** | **16h** | **6h** | **38h** |

**Budget:**
- Assuming $100/hour blended rate
- Total investment: $3,800
- Expected savings: $500-1000/month
- ROI: 4-8x over 12 months
- Payback: 1.5 months

---

## Next Steps (Immediate Actions)

### Today
1. ⏰ Schedule Phase 1 execution (2-hour block)
2. 📋 Get analytics lead sign-off on action plan
3. 🔍 Identify which exact files need device filter fix
4. ✅ Execute Phase 1

### This Week
5. 📊 Conduct column naming audit (inventory all current names)
6. 📝 Draft naming convention document for team review
7. 🗓️ Schedule Phase 2 kickoff meeting
8. 🧪 Set up testing checklist

### Next 2 Weeks
9. 🚀 Deploy Phase 2 changes to production
10. 📈 Monitor dashboard usage and support tickets
11. 🏗️ Begin Phase 3 planning (snippets, models, indexes)

---

## Appendix A: Code Examples

### Before/After Comparison

**BEFORE (Current State):**
```sql
-- Duplicated in 14 queries (1400 lines total)
filtered_players AS (
  SELECT DISTINCT players.id AS player_id
  FROM players
  LEFT JOIN companies ON companies.id = players.company_id
  WHERE 1=1
    [[ AND {{brand}} ]]
    [[ AND players.country = CASE {{country}}
       WHEN 'Romania' THEN 'RO'
       -- ... 25 more lines ...
       WHEN 'Andorra' THEN 'AD'
    END ]]
    [[ AND CASE
         WHEN {{traffic_source}} = 'Organic'   THEN players.affiliate_id IS NULL
         WHEN {{traffic_source}} = 'Affiliate' THEN players.affiliate_id IS NOT NULL
         ELSE TRUE
       END ]]
    [[ AND {{affiliate_id}} ]]
    [[ AND {{affiliate_name}} ]]
    [[ AND CONCAT(players.os, ' / ', players.browser) = {{registration_launcher}} ]]
    [[ AND {{is_test_account}} ]]
),

-- Later in the same query
WHERE 1=1
  [[ AND UPPER(COALESCE(
         t.metadata->>'currency',
         t.cash_currency,
         players.wallet_currency,
         companies.currency
       )) IN ({{currency_filter}}) ]]
-- This appears 30+ times across all queries
```

**AFTER (Optimized):**
```sql
-- Option 1: Using Model
WITH player_base AS (
  SELECT * FROM {{#filtered_players_base}}
),

-- Option 2: Using Snippets
filtered_players AS (
  SELECT DISTINCT players.id AS player_id
  FROM players
  {{ snippet: player_filter_joins }}
  WHERE 1=1
    [[ AND {{brand}} ]]
    [[ AND players.country = {{ snippet: country_code_case }} ]]
    [[ AND {{ snippet: traffic_source_filter }} ]]
    [[ AND {{affiliate_id}} ]]
    [[ AND {{affiliate_name}} ]]
    [[ AND CONCAT(players.os, ' / ', players.browser) = {{registration_launcher}} ]]
    [[ AND {{is_test_account}} ]]
),

-- Later in the same query
WHERE 1=1
  [[ AND {{ snippet: currency_resolution }} IN ({{currency_filter}}) ]]
```

**Reduction:** From ~100 lines to ~15 lines per query

---

## Appendix B: Testing Checklist

### Phase 1: Bug Fix Validation

**Device Filter Fix:**
- [ ] Daily KPIs filtered for "iOS / Safari" → Note player count
- [ ] Monthly KPIs with same filter → Compare player count (should match)
- [ ] Test with "Android / Chrome"
- [ ] Test with "Windows / Firefox"
- [ ] Test with no device filter (should show all)

**Date Parameter Fix:**
- [ ] Open dashboard
- [ ] Set date range filter to "Last 30 days"
- [ ] Verify New Depositors Cohort updates
- [ ] Change to "Last 90 days"
- [ ] Verify update again
- [ ] Test with custom date range

### Phase 2: Standardization Validation

**Naming Convention:**
- [ ] All dashboards render without errors
- [ ] No "Column not found" errors
- [ ] Filters still wire correctly
- [ ] Custom formatting preserved
- [ ] Column order unchanged (unless intentional)
- [ ] Values identical to before rename

**TOTAL Rows:**
- [ ] TOTAL appears first in all cohort reports
- [ ] TOTAL values = SUM of individual rows (counts/amounts)
- [ ] TOTAL percentages = overall percentage (not average)
- [ ] Filtering updates TOTAL row correctly
- [ ] Sorting works (TOTAL stays on top)

### Phase 3: Architecture Validation

**Snippets:**
- [ ] Each snippet tested individually in isolation
- [ ] Query results unchanged before/after snippet
- [ ] All filter combinations still work
- [ ] Performance not degraded
- [ ] No syntax errors

**Models:**
- [ ] Model returns expected columns
- [ ] Metadata correctly defined
- [ ] Filters work in model
- [ ] Queries using model return same results
- [ ] Model referenced correctly: `{{#model_name}}`

**Indexes:**
- [ ] Indexes created successfully
- [ ] Query plans show index usage (EXPLAIN)
- [ ] Query times improved
- [ ] No table locks during creation
- [ ] Disk space acceptable

---

*Document Version: 1.0*
*Last Updated: October 30, 2025*
*Owner: Analytics Team*
*Status: Ready for Implementation*
