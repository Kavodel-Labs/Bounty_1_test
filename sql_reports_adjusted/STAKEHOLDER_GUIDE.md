# BTB Gaming Analytics - Stakeholder Guide
## Understanding Your Dashboard Metrics & Filters

**Version:** 1.0
**Date:** October 31, 2025
**Audience:** Business Stakeholders, Product Managers, Executives

---

## 📊 What This Dashboard Shows

The BTB Gaming Analytics Dashboard tracks player behavior, financial performance, and business health across your gaming platform. It helps answer questions like:

- How many players are registering and making their first deposit?
- What's our revenue and profitability?
- Are players staying engaged over time?
- Which acquisition channels work best?

---

## 🎯 Available Reports (15 Total)

### Performance Reports (2)
1. **Daily KPIs** - Day-by-day performance tracking
2. **Monthly KPIs** - Month-by-month performance trends

### Player Behavior Reports (12 Cohorts)
3. **Depositors Cohort** - How many depositors stay active
4. **Depositors Cohort (%)** - Retention rates as percentages
5. **Deposit Amounts Cohort** - How much money depositors bring over time
6. **Deposit Amounts Cohort (%)** - Deposit trends vs. first month
7. **Cash Players Cohort** - Players using real money to play
8. **Cash Players Cohort (%)** - Cash player retention rates
9. **Cash Bet Amounts Cohort** - How much players bet over time
10. **Cash Bet Amounts Cohort (%)** - Betting trends vs. first month
11. **New Depositors Cohort** - First-time depositors by registration month
12. **New Depositors Cohort (%)** - Conversion rates by registration cohort
13. **Existing Depositors Cohort** - Players making repeat deposits
14. **Existing Depositors Cohort (%)** - Repeat deposit rates
15. **Cohort LTV Lifetime** - Complete profitability view by player cohort

---

## 🔍 How to Use the Filters

Every report can be filtered to show exactly what you need to see. Here's what each filter does:

### Geographic & Business Filters

**Brand**
- **What it does:** Shows data for specific casino brands/companies
- **Example:** Filter to see only "Casino Royal" performance
- **Data source:** `companies` table
- **Use when:** Comparing performance across multiple brands

**Country**
- **What it does:** Shows players from specific countries
- **Example:** Filter to "Romania" or "Germany"
- **Data source:** `players` table → `country` field
- **Use when:** Analyzing regional performance, compliance reporting
- **Note:** Shows full country names but filters using ISO codes (RO, DE, FR, etc.)

### Time Period Filters

**Start Date & End Date**
- **What it does:** Sets the date range for analysis
- **Example:** See January 2025 to March 2025 performance
- **Default:**
  - Daily KPIs: Last 31 days
  - Monthly KPIs: Last 12 months
  - Cohort reports: Last 12 months of cohorts
- **Use when:** Analyzing specific time periods, creating reports for meetings

### Player Acquisition Filters

**Traffic Source**
- **What it does:** Separates organic vs. affiliate-driven players
- **Options:**
  - **Organic** = Players who found you directly
  - **Affiliate** = Players referred by partners
- **Data source:** `players` table → `affiliate_id` (NULL = Organic)
- **Use when:** Measuring marketing channel effectiveness

**Affiliate ID**
- **What it does:** Shows performance for a specific affiliate partner
- **Example:** See results from Affiliate #12345
- **Data source:** `players` table → `affiliate_id`
- **Use when:** Evaluating individual affiliate performance

**Affiliate Name**
- **What it does:** Search/filter by affiliate partner name
- **Example:** Filter to "PartnerCasino"
- **Data source:** `affiliates` table → `name`
- **Use when:** Finding affiliates by name instead of ID

### Technical Filters

**Device (Registration Launcher)**
- **What it does:** Shows which device/browser players used to register
- **Example:** "iOS / Safari" or "Android / Chrome"
- **Format:** "Operating System / Browser"
- **Data source:** `players` table → `os` and `browser` fields
- **Use when:** Optimizing mobile vs desktop experience

**Currency**
- **What it does:** Shows transactions in specific currencies
- **Example:** Filter to EUR, USD, or GBP
- **Data source:** Multiple sources (see Currency Logic below)
- **Use when:** Financial reporting, regional analysis

**Test Accounts**
- **What it does:** Includes or excludes test/demo accounts
- **Options:**
  - Include test accounts
  - Exclude test accounts (recommended for business reports)
- **Data source:** `players` table → `is_test_account`
- **Use when:** Always exclude for real business metrics

---

## 🛠️ Filters SQL Configuration Reference

This section shows the exact SQL code behind each filter for visual debugging and technical reference.

### Complete Filters Table

| Filter Name | Business Purpose | SQL Configuration | Metabase Type | Technical Notes |
|-------------|------------------|-------------------|---------------|-----------------|
| **brand** | Filter by specific casino/company | `[[ AND {{brand}} ]]`<br/>Maps to: `companies.name` | Field Filter | Direct match on company name |
| **country** | Filter by player country | `[[ AND players.country = CASE {{country}}`<br/>`  WHEN 'Romania' THEN 'RO'`<br/>`  WHEN 'France' THEN 'FR'`<br/>`  WHEN 'Germany' THEN 'DE'`<br/>`  ... (30+ countries)`<br/>`END ]]` | Field Filter | Converts full name → ISO code |
| **start_date** | Analysis period start | `start_input AS (`<br/>`  SELECT NULL::date WHERE FALSE`<br/>`  [[ UNION ALL SELECT {{start_date}}::date ]]`<br/>`)` | Date | Default: 31 days ago (daily)<br/>12 months ago (monthly) |
| **end_date** | Analysis period end | `end_input AS (`<br/>`  SELECT NULL::date WHERE FALSE`<br/>`  [[ UNION ALL SELECT {{end_date}}::date ]]`<br/>`)` | Date | Default: today (CURRENT_DATE) |
| **traffic_source** | Organic vs Affiliate players | `[[ AND CASE`<br/>`  WHEN {{traffic_source}} = 'Organic'`<br/>`    THEN players.affiliate_id IS NULL`<br/>`  WHEN {{traffic_source}} = 'Affiliate'`<br/>`    THEN players.affiliate_id IS NOT NULL`<br/>`  ELSE TRUE`<br/>`END ]]` | Text | NULL affiliate_id = Organic |
| **affiliate_id** | Specific affiliate partner | `[[ AND {{affiliate_id}} ]]`<br/>Maps to: `players.affiliate_id` | Field Filter | Direct ID match |
| **affiliate_name** | Affiliate name search | `[[ AND {{affiliate_name}} ]]`<br/>Maps to: `affiliates.name` | Field Filter | Name-based lookup |
| **registration_launcher** | Device (OS / Browser) | `[[ AND CONCAT(players.os, ' / ',`<br/>`  players.browser) = {{registration_launcher}} ]]` | Field Filter | Format: "iOS / Safari"<br/>"Android / Chrome" |
| **currency_filter** | Transaction currency | `[[ AND UPPER(COALESCE(`<br/>`  t.metadata->>'currency',`<br/>`  t.cash_currency,`<br/>`  players.wallet_currency,`<br/>`  companies.currency`<br/>`)) IN ({{currency_filter}}) ]]` | Text | Comma-separated: 'EUR','USD'<br/>Uses 4-level cascade |
| **is_test_account** | Include/exclude test accounts | `[[ AND {{is_test_account}} ]]`<br/>Maps to: `players.is_test_account` | Field Filter | TRUE = include tests<br/>FALSE = exclude tests |

### Filtered Players Pattern (Used in All Reports)

```sql
-- Core pattern: filtered_players CTE
filtered_players AS (
  SELECT DISTINCT players.id AS player_id
  FROM players
  LEFT JOIN companies ON companies.id = players.company_id
  WHERE 1=1
    -- Brand filter
    [[ AND {{brand}} ]]

    -- Country filter with ISO code mapping
    [[ AND players.country = CASE {{country}}
      WHEN 'Romania' THEN 'RO'
      WHEN 'France' THEN 'FR'
      WHEN 'Germany' THEN 'DE'
      WHEN 'Cyprus' THEN 'CY'
      WHEN 'Poland' THEN 'PL'
      -- ... 25+ more countries
    END ]]

    -- Traffic source: Organic (NULL affiliate_id) vs Affiliate (NOT NULL)
    [[ AND CASE
      WHEN {{traffic_source}} = 'Organic' THEN players.affiliate_id IS NULL
      WHEN {{traffic_source}} = 'Affiliate' THEN players.affiliate_id IS NOT NULL
      ELSE TRUE
    END ]]

    -- Specific affiliate filters
    [[ AND {{affiliate_id}} ]]
    [[ AND {{affiliate_name}} ]]

    -- Device filter: OS + Browser concatenated
    [[ AND CONCAT(players.os, ' / ', players.browser) = {{registration_launcher}} ]]

    -- Test account filter
    [[ AND {{is_test_account}} ]]
)
```

**How it's used:**
```sql
-- Every metric query joins to filtered_players
FROM transactions t
INNER JOIN filtered_players fp ON t.player_id = fp.player_id
```

This ensures ALL metrics respect the user's filter selections.

---

## 📈 Understanding the Metrics

### Registration & Acquisition Metrics

**#Registrations (REG)**
- **What it means:** Total new player accounts created
- **Includes:** All registrations (verified and unverified emails)
- **Why it matters:** Top of the acquisition funnel
- **Data source:** `players` table

**#FTDs (First-Time Depositors)**
- **What it means:** Players who made their first-ever deposit
- **Calculation:** Count of players with first `deposit` transaction
- **Why it matters:** Conversion from free to paying player
- **Data source:** `transactions` table (first deposit per player)

**#New FTDs**
- **What it means:** Players who deposited in same month they registered
- **Why it matters:** Immediate conversion quality
- **Good benchmark:** 20-40% of FTDs should be "new"

**#Old FTDs**
- **What it means:** Players who deposited after their registration month
- **Why it matters:** Shows delayed conversion value

**#D0 FTDs (Same-Day FTDs)**
- **What it means:** Players who deposited on the same day they registered
- **Why it matters:** Indicates strong initial engagement
- **Good benchmark:** 60-80% of New FTDs should be D0

**Conversion Rate**
- **Formula:** (FTDs ÷ Registrations) × 100
- **What it means:** Percentage of registrations that become paying players
- **Good benchmark:** 5-15% depending on market
- **Why it matters:** Core acquisition efficiency metric

### Financial Metrics

**Deposits Amount**
- **What it means:** Total money deposited by players
- **Currency:** EUR (all converted to EUR)
- **Data source:** `transactions` → category='deposit', type='credit'
- **Why it matters:** Money coming into platform

**Withdrawals Amount (WD)**
- **What it means:** Total money withdrawn by players
- **Currency:** EUR (all converted to EUR)
- **Data source:** `transactions` → category='withdrawal', type='debit'
- **Why it matters:** Money leaving platform

**CashFlow**
- **Formula:** Deposits - Withdrawals
- **What it means:** Net money movement
- **Positive = more deposits than withdrawals** (good)
- **Negative = more withdrawals than deposits** (review needed)

**Unique Depositors**
- **What it means:** Count of distinct players who deposited
- **Different from:** Total number of deposit transactions
- **Why it matters:** Shows breadth of paying player base

**#Deposits**
- **What it means:** Total count of deposit transactions
- **Different from:** Unique depositors (one player can deposit multiple times)
- **Use case:** Understanding deposit frequency

### Gaming Activity Metrics

**Active Players**
- **What it means:** Players who placed at least one bet
- **Includes:** Cash bets and promo bets
- **Data source:** `transactions` → category='game_bet'
- **Why it matters:** Core engagement metric

**Real Active Players**
- **What it means:** Players who bet with real cash (not bonuses)
- **Calculation:** Players with `balance_type='withdrawable'` bets
- **Why it matters:** Measures true monetary engagement

**Cash Bet**
- **What it means:** Total bets placed using real money
- **Currency:** EUR
- **Data source:** `transactions` → category='game_bet', balance_type='withdrawable', type='debit'
- **Why it matters:** Total real money wagered

**Cash Win**
- **What it means:** Total winnings paid out from real money bets
- **Currency:** EUR
- **Data source:** `transactions` → category='game_bet', balance_type='withdrawable', type='credit'
- **Why it matters:** What players won back

**Promo Bet**
- **What it means:** Total bets placed using bonus money
- **Currency:** EUR
- **Data source:** `transactions` → category='bonus', balance_type='non-withdrawable', type='debit'
- **Why it matters:** Tracks bonus utilization

**Promo Win**
- **What it means:** Winnings from bonus money bets
- **Currency:** EUR
- **Data source:** `transactions` → category='bonus', balance_type='non-withdrawable', type='credit'
- **Why it matters:** Bonus play outcomes

**Turnover**
- **Formula:** Cash Bet + Promo Bet
- **What it means:** Total wagering activity (real + bonus)
- **Why it matters:** Overall platform engagement

### Revenue Metrics

**GGR (Gross Gaming Revenue)**
- **Formula:** (Cash Bet + Promo Bet) - (Cash Win + Promo Win)
- **What it means:** Profit from gaming before bonus costs
- **Currency:** EUR
- **Why it matters:** Core gaming profitability
- **Note:** Positive GGR = house won more than paid out

**Cash GGR**
- **Formula:** Cash Bet - Cash Win
- **What it means:** Profit from real money gaming only
- **Why it matters:** True cash profit before bonuses

**NGR (Net Gaming Revenue)**
- **What it means:** Same as GGR in this platform
- **Note:** Some platforms subtract taxes/fees here, but yours calculates that separately
- **Currency:** EUR

**Bonus Converted**
- **What it means:** Bonus money that became withdrawable cash
- **Data source:** `transactions` → category='bonus_completion', type='credit'
- **Why it matters:** Cost of bonus promotions

**Bonus Cost**
- **What it means:** Total cost of bonuses that converted to cash
- **Same as:** Bonus Converted (in current implementation)
- **Currency:** EUR
- **Why it matters:** Marketing/promotion expense

**Bonus Ratio (GGR)**
- **Formula:** (Bonus Cost ÷ GGR) × 100
- **What it means:** Bonus cost as % of revenue
- **Good benchmark:** 10-25% depending on market
- **Why it matters:** Bonus efficiency measure

**Bonus Ratio (Deposits)**
- **Formula:** (Bonus Cost ÷ Deposits) × 100
- **What it means:** Bonus cost as % of deposits
- **Why it matters:** Alternative bonus efficiency view

**Payout %**
- **Formula:** (Cash Win ÷ Cash Bet) × 100
- **What it means:** How much players win back
- **Good benchmark:** 92-97% (varies by game type)
- **Why it matters:** Player experience and regulatory compliance

**%CashFlow to GGR**
- **Formula:** (CashFlow ÷ GGR) × 100
- **What it means:** How much of revenue is net cash movement
- **Why it matters:** Cash flow health indicator

**Revenue (Net Revenue)**
- **Formula:** GGR - Bonus Cost
- **What it means:** Final profit after bonus costs
- **Currency:** EUR
- **Why it matters:** Bottom line profitability

### Cohort-Specific Metrics

**LTV (Lifetime Value)**
- **Formula:** Total Deposits ÷ FTD Count
- **What it means:** Average money brought in per depositor
- **Currency:** EUR
- **Why it matters:** Player value assessment
- **Use case:** Compare acquisition cost vs. LTV

**Retention Rate**
- **What it means:** % of cohort still active after X months
- **Example:** If Month 0 = 100 players, Month 3 = 40 players → 40% retention
- **Why it matters:** Long-term engagement health

**Cohort Month**
- **What it means:** The month a player first deposited (or registered)
- **Example:** "January 2025" cohort = all players who first deposited in Jan 2025
- **Why it matters:** Groups players by acquisition period

---

## 🧮 Metrics SQL Configuration Reference

This section shows the exact SQL formulas behind each metric for visual debugging and technical modifications.

### Registration & Acquisition Metrics - SQL Details

| Metric | Business Formula | SQL Implementation | Data Sources | Filters Applied |
|--------|------------------|-------------------|--------------|-----------------|
| **#Registrations** | Count of new accounts | ```sql
COUNT(DISTINCT players.id) FILTER (
  WHERE players.created_at >= report_date
    AND players.created_at < report_date + INTERVAL '1 day'
)
``` | `players.id`<br/>`players.created_at` | filtered_players,<br/>date range |
| **Complete Registrations** | Verified email accounts | ```sql
COUNT(DISTINCT players.id) FILTER (
  WHERE players.email_verified = TRUE
    AND players.created_at >= report_date
)
``` | `players.email_verified` | filtered_players,<br/>date range |
| **#FTDs (First-Time Depositors)** | Players with first deposit | ```sql
-- Step 1: Find first deposit per player
ftd_first AS (
  SELECT player_id, MIN(created_at) AS first_deposit_ts
  FROM transactions
  WHERE transaction_category = 'deposit'
    AND transaction_type = 'credit'
    AND status = 'completed'
    AND balance_type = 'withdrawable'
  GROUP BY player_id
)
-- Step 2: Count by date
COUNT(DISTINCT player_id)
  WHERE DATE_TRUNC('day', first_deposit_ts) = report_date
``` | `transactions` table<br/>Category: deposit<br/>Type: credit<br/>Status: completed | filtered_players,<br/>currency_filter,<br/>date range |
| **#New FTDs** | FTDs in registration month | ```sql
COUNT(DISTINCT player_id) FILTER (
  WHERE DATE_TRUNC('month', first_deposit_ts)
      = DATE_TRUNC('month', registration_ts)
)
``` | `players.created_at`<br/>`ftd_first.first_deposit_ts` | Same as FTDs +<br/>month match |
| **#Old FTDs** | FTDs after registration month | ```sql
COUNT(DISTINCT player_id) FILTER (
  WHERE DATE_TRUNC('month', first_deposit_ts)
      > DATE_TRUNC('month', registration_ts)
)
``` | Same as New FTDs | Same as New FTDs |
| **#D0 FTDs** | Same-day deposits | ```sql
COUNT(DISTINCT player_id) FILTER (
  WHERE first_deposit_ts::date = registration_ts::date
)
``` | Both timestamps cast to date | Same as FTDs +<br/>date match |
| **Conversion Rate** | FTD / Registrations × 100 | ```sql
CASE
  WHEN total_registrations > 0
  THEN ROUND((ftd_count::numeric / total_registrations) * 100, 2)
  ELSE NULL
END
``` | Calculated from above | Derived metric |

### Financial Metrics - SQL Details

| Metric | Business Formula | SQL Implementation | Transaction Filters | EUR Conversion |
|--------|------------------|-------------------|---------------------|----------------|
| **Deposits Amount** | Sum of deposit transactions | ```sql
SUM(
  CASE
    WHEN t.metadata->>'currency' = 'EUR'
      THEN t.amount
    WHEN t.metadata->>'currency' IS NOT NULL
      THEN t.amount / COALESCE(
        (t.metadata->>'exchange_rate')::numeric, 1
      )
    ELSE t.amount
  END
) FILTER (
  WHERE t.transaction_category = 'deposit'
    AND t.transaction_type = 'credit'
    AND t.status = 'completed'
    AND t.balance_type = 'withdrawable'
)
``` | Category: `deposit`<br/>Type: `credit`<br/>Status: `completed`<br/>Balance: `withdrawable` | All amounts → EUR<br/>Using exchange_rate<br/>from metadata |
| **Withdrawals Amount** | Sum of withdrawal transactions | ```sql
SUM(
  CASE
    WHEN t.metadata->>'currency' = 'EUR'
      THEN t.amount
    WHEN t.metadata->>'currency' IS NOT NULL
      THEN t.amount / COALESCE(
        (t.metadata->>'exchange_rate')::numeric, 1
      )
    ELSE t.amount
  END
) FILTER (
  WHERE t.transaction_category = 'withdrawal'
    AND t.transaction_type = 'debit'
    AND t.status = 'completed'
    AND t.balance_type = 'withdrawable'
)
``` | Category: `withdrawal`<br/>Type: `debit`<br/>Status: `completed`<br/>Balance: `withdrawable` | Same as Deposits |
| **CashFlow** | Deposits - Withdrawals | ```sql
(deposit_amount - withdrawal_amount)
``` | N/A (calculated) | Already in EUR |
| **Unique Depositors** | Distinct players with deposits | ```sql
COUNT(DISTINCT t.player_id) FILTER (
  WHERE t.transaction_category = 'deposit'
    AND t.status = 'completed'
)
``` | Same as Deposits Amount | N/A (count metric) |
| **#Deposits** | Count of deposit transactions | ```sql
COUNT(*) FILTER (
  WHERE t.transaction_category = 'deposit'
    AND t.status = 'completed'
)
``` | Same as Deposits Amount | N/A (count metric) |

### Gaming Activity Metrics - SQL Details

| Metric | Business Formula | SQL Implementation | Transaction Filters | Balance Type |
|--------|------------------|-------------------|---------------------|--------------|
| **Active Players** | Players with any bet | ```sql
COUNT(DISTINCT t.player_id) FILTER (
  WHERE t.transaction_category = 'game_bet'
    AND t.status = 'completed'
)
``` | Category: `game_bet`<br/>Status: `completed` | Any balance type |
| **Real Active Players** | Players with cash bets | ```sql
COUNT(DISTINCT t.player_id) FILTER (
  WHERE t.transaction_category = 'game_bet'
    AND t.balance_type = 'withdrawable'
    AND t.status = 'completed'
)
``` | Category: `game_bet`<br/>Balance: `withdrawable`<br/>Status: `completed` | withdrawable only |
| **Cash Bet** | Sum of real money bets | ```sql
SUM(
  CASE
    WHEN t.metadata->>'currency' = 'EUR' THEN t.amount
    ELSE t.amount / COALESCE(
      (t.metadata->>'exchange_rate')::numeric, 1
    )
  END
) FILTER (
  WHERE t.transaction_category = 'game_bet'
    AND t.transaction_type = 'debit'
    AND t.balance_type = 'withdrawable'
    AND t.status = 'completed'
)
``` | Category: `game_bet`<br/>Type: `debit`<br/>Balance: `withdrawable`<br/>Status: `completed` | withdrawable<br/>(real money) |
| **Cash Win** | Sum of cash winnings | ```sql
SUM(
  CASE
    WHEN t.metadata->>'currency' = 'EUR' THEN t.amount
    ELSE t.amount / COALESCE(
      (t.metadata->>'exchange_rate')::numeric, 1
    )
  END
) FILTER (
  WHERE t.transaction_category = 'game_bet'
    AND t.transaction_type = 'credit'
    AND t.balance_type = 'withdrawable'
    AND t.status = 'completed'
)
``` | Category: `game_bet`<br/>Type: `credit`<br/>Balance: `withdrawable`<br/>Status: `completed` | withdrawable<br/>(real money) |
| **Promo Bet** | Sum of bonus money bets | ```sql
SUM(
  CASE
    WHEN t.metadata->>'currency' = 'EUR' THEN t.amount
    ELSE t.amount / COALESCE(
      (t.metadata->>'exchange_rate')::numeric, 1
    )
  END
) FILTER (
  WHERE t.transaction_category = 'bonus'
    AND t.transaction_type = 'debit'
    AND t.balance_type = 'non-withdrawable'
    AND t.status = 'completed'
)
``` | Category: `bonus`<br/>Type: `debit`<br/>Balance: `non-withdrawable`<br/>Status: `completed` | non-withdrawable<br/>(bonus money) |
| **Promo Win** | Sum of bonus winnings | ```sql
SUM(
  CASE
    WHEN t.metadata->>'currency' = 'EUR' THEN t.amount
    ELSE t.amount / COALESCE(
      (t.metadata->>'exchange_rate')::numeric, 1
    )
  END
) FILTER (
  WHERE t.transaction_category = 'bonus'
    AND t.transaction_type = 'credit'
    AND t.balance_type = 'non-withdrawable'
    AND t.status = 'completed'
)
``` | Category: `bonus`<br/>Type: `credit`<br/>Balance: `non-withdrawable`<br/>Status: `completed` | non-withdrawable<br/>(bonus money) |
| **Turnover** | Total wagering (cash + promo) | ```sql
(cash_bet + promo_bet)
``` | N/A (calculated) | Already in EUR |

### Revenue Metrics - SQL Details

| Metric | Business Formula | SQL Implementation | Calculation Logic | When to Use |
|--------|------------------|-------------------|-------------------|-------------|
| **GGR (Gross Gaming Revenue)** | (Bets - Wins) | ```sql
((cash_bet + promo_bet) - (cash_win + promo_win))
``` | House edge profit<br/>Before bonus costs | Core gaming profitability |
| **Cash GGR** | Cash Bet - Cash Win | ```sql
(cash_bet - cash_win)
``` | Real money only<br/>No bonus activity | True cash profit |
| **NGR (Net Gaming Revenue)** | Same as GGR | ```sql
-- Same calculation as GGR
((cash_bet + promo_bet) - (cash_win + promo_win))
``` | No difference in this platform<br/>(Some platforms subtract fees here) | Alternative name for GGR |
| **Bonus Converted** | Bonus → cash conversions | ```sql
SUM(
  CASE
    WHEN t.metadata->>'currency' = 'EUR' THEN t.amount
    ELSE t.amount / COALESCE(
      (t.metadata->>'exchange_rate')::numeric, 1
    )
  END
) FILTER (
  WHERE t.transaction_category = 'bonus_completion'
    AND t.transaction_type = 'credit'
    AND t.status = 'completed'
)
``` | Category: `bonus_completion`<br/>Type: `credit`<br/>Status: `completed` | Cost of successful bonuses |
| **Bonus Cost** | Total bonus expense | ```sql
-- Currently same as Bonus Converted
(bonus_converted)
``` | Same implementation<br/>for now | Marketing expense |
| **Bonus Ratio (GGR)** | Bonus cost % of revenue | ```sql
CASE
  WHEN ggr > 0
  THEN ROUND((bonus_cost / ggr) * 100, 2)
  ELSE NULL
END
``` | Percentage calculation<br/>NULL if GGR = 0 | Bonus efficiency |
| **Bonus Ratio (Deposits)** | Bonus cost % of deposits | ```sql
CASE
  WHEN deposit_amount > 0
  THEN ROUND((bonus_cost / deposit_amount) * 100, 2)
  ELSE NULL
END
``` | Percentage calculation<br/>NULL if deposits = 0 | Alternative bonus view |
| **Payout %** | Win / Bet × 100 | ```sql
CASE
  WHEN cash_bet > 0
  THEN ROUND((cash_win / cash_bet) * 100, 2)
  ELSE NULL
END
``` | Player return rate<br/>Regulatory metric | RTP (Return to Player) |
| **%CashFlow to GGR** | CashFlow / GGR × 100 | ```sql
CASE
  WHEN ggr > 0
  THEN ROUND((cashflow / ggr) * 100, 2)
  ELSE NULL
END
``` | Cash efficiency<br/>Financial health | Cash flow analysis |
| **Revenue (Net Revenue)** | GGR - Bonus Cost | ```sql
(ggr - bonus_cost)
``` | Final bottom line<br/>After all costs | True profitability |

### Cohort-Specific Metrics - SQL Details

| Metric | Business Formula | SQL Implementation | Cohort Logic | Month Calculation |
|--------|------------------|-------------------|--------------|-------------------|
| **LTV (Lifetime Value)** | Total Deposits / FTD Count | ```sql
CASE
  WHEN ftd_count > 0
  THEN ROUND(total_deposits / ftd_count, 2)
  ELSE 0
END
``` | Lifetime = all activity<br/>since registration | N/A (summary metric) |
| **Retention Rate** | Active Month X / Active Month 0 × 100 | ```sql
-- Example: Depositors Cohort %
CASE
  WHEN "Month 0" > 0
  THEN ROUND(("Month 3"::numeric / "Month 0") * 100, 2)
  ELSE NULL
END
``` | Cohort = first deposit month<br/>Month 0 = 100% | Month X = X months<br/>after first deposit |
| **Cohort Size** | Players in cohort | ```sql
COUNT(DISTINCT player_id) FILTER (
  WHERE DATE_TRUNC('month', first_deposit_ts) = cohort_month
)
``` | Grouped by first action<br/>(deposit or registration) | `DATE_TRUNC('month', ...)` |
| **Month 0 Activity** | Activity in first month | ```sql
SUM(amount) FILTER (
  WHERE DATE_TRUNC('month', activity_ts)
      = DATE_TRUNC('month', first_deposit_ts)
)
``` | Same month as first deposit | Month difference = 0 |
| **Month X Activity** | Activity X months later | ```sql
SUM(amount) FILTER (
  WHERE DATE_TRUNC('month', activity_ts)
      = DATE_TRUNC('month', first_deposit_ts) + INTERVAL 'X month'
)
``` | Offset by X months | Month difference = X |

### Transaction Type Configuration Matrix

This table shows exactly which transaction attributes create each metric type:

| Metric Category | `transaction_category` | `transaction_type` | `balance_type` | `status` | EUR Conversion |
|-----------------|----------------------|-------------------|----------------|----------|----------------|
| **Deposits** | `deposit` | `credit` | `withdrawable` | `completed` | ✅ Yes |
| **Withdrawals** | `withdrawal` | `debit` | `withdrawable` | `completed` | ✅ Yes |
| **Cash Bet** | `game_bet` | `debit` | `withdrawable` | `completed` | ✅ Yes |
| **Cash Win** | `game_bet` | `credit` | `withdrawable` | `completed` | ✅ Yes |
| **Promo Bet** | `bonus` | `debit` | `non-withdrawable` | `completed` | ✅ Yes |
| **Promo Win** | `bonus` | `credit` | `non-withdrawable` | `completed` | ✅ Yes |
| **Bonus Converted** | `bonus_completion` | `credit` | ANY | `completed` | ✅ Yes |
| **FTD Deposits** | `deposit` + first per player | `credit` | `withdrawable` | `completed` | ✅ Yes |

### Currency Conversion SQL Pattern

**Used in all financial metrics:**

```sql
-- EUR Conversion Logic (applied to every amount field)
CASE
  -- Already EUR - no conversion needed
  WHEN t.metadata->>'currency' = 'EUR' THEN t.amount

  -- Has currency + exchange rate in metadata
  WHEN t.metadata->>'currency' IS NOT NULL THEN
    t.amount / COALESCE(
      (t.metadata->>'exchange_rate')::numeric,
      1  -- Fallback to 1:1 if rate missing
    )

  -- No metadata - assume already in EUR or use amount as-is
  ELSE t.amount
END
```

**4-Level Currency Resolution (for filtering):**

```sql
UPPER(COALESCE(
  t.metadata->>'currency',      -- 1. Transaction-specific (highest priority)
  t.cash_currency,              -- 2. Transaction default
  players.wallet_currency,      -- 3. Player account default
  companies.currency            -- 4. Company default (fallback)
))
```

### Common SQL Patterns for Debugging

**Pattern 1: Date Range Filtering**
```sql
-- Daily reports
WHERE t.created_at >= report_date
  AND t.created_at < report_date + INTERVAL '1 day'

-- Monthly reports
WHERE DATE_TRUNC('month', t.created_at) = cohort_month
```

**Pattern 2: First Transaction Detection**
```sql
-- Find first deposit per player
WITH ftd_first AS (
  SELECT
    player_id,
    MIN(created_at) AS first_deposit_ts
  FROM transactions
  WHERE transaction_category = 'deposit'
    AND transaction_type = 'credit'
    AND status = 'completed'
  GROUP BY player_id
)
```

**Pattern 3: Cohort Month Calculation**
```sql
-- Assign player to cohort
DATE_TRUNC('month', first_deposit_ts) AS cohort_month

-- Calculate months since cohort
DATE_PART('year', activity_ts) * 12 + DATE_PART('month', activity_ts)
  - (DATE_PART('year', first_deposit_ts) * 12 + DATE_PART('month', first_deposit_ts))
  AS months_since_first
```

**Pattern 4: NULL Safety in Calculations**
```sql
-- Always handle division by zero
CASE
  WHEN denominator > 0 THEN numerator / denominator
  ELSE NULL  -- or 0, depending on business logic
END

-- Always handle NULL amounts
COALESCE(SUM(amount), 0)
```

---

## 💡 How the Data Works

### Data Sources

All metrics come from your production database:

| Table | What It Stores | Used For |
|-------|----------------|----------|
| **players** | Player profiles & registration info | Registration metrics, filtering |
| **companies** | Brand/casino information | Brand filtering, currency defaults |
| **transactions** | All financial & gaming activity | Deposits, withdrawals, bets, wins, revenue |
| **affiliates** | Partner/affiliate details | Affiliate performance tracking |

### Currency Handling

**The Challenge:**
Players deposit in multiple currencies (EUR, USD, RON, etc.) but reports need one standard currency for comparison.

**The Solution: 4-Level Currency Resolution**

The system checks these sources in order:

1. **Transaction-specific currency** - Most accurate (transaction.metadata→'currency')
2. **Transaction default** - Second choice (transaction.cash_currency)
3. **Player wallet currency** - Third choice (players.wallet_currency)
4. **Company default** - Last resort (companies.currency)

All amounts are converted to **EUR** for reporting using real-time exchange rates.

**Why EUR:**
- Primary market currency
- Stable reference point
- Regulatory reporting standard

### Date & Time Handling

**Time Zone:** All times in UTC (Coordinated Universal Time)

**Date Buckets:**
- **Daily reports:** One row per calendar day
- **Monthly reports:** One row per calendar month
- **Cohorts:** Grouped by first deposit month or registration month

**Default Periods:**
- Daily KPIs → Last 31 days
- Monthly KPIs → Last 12 months
- Cohort reports → Last 12 months of cohorts

### What Makes a "Completed" Transaction

Only completed, valid transactions count in reports:

**Required:**
- `status = 'completed'` ✅
- `balance_type = 'withdrawable'` (for deposits/withdrawals/cash gaming)
- Correct category and type (e.g., deposit must be category='deposit' AND type='credit')

**Excluded:**
- Pending transactions ❌
- Failed transactions ❌
- Cancelled transactions ❌
- Test account transactions ❌ (if filter applied)

---

## 📊 Reading Cohort Reports

### What is a Cohort?

A **cohort** is a group of players who started at the same time (usually same month).

**Example:**
- **January 2025 Cohort** = All players who made first deposit in January 2025
- **Month 0** = January (their first month)
- **Month 1** = February (one month later)
- **Month 2** = March (two months later)

### Absolute vs. Percentage Cohort Reports

**Absolute Reports:**
- Show actual counts or amounts
- Example: "150 players still depositing in Month 3"

**Percentage Reports (%):**
- Show values as % of Month 0
- Example: "60% retention in Month 3" (if Month 0 had 250 players, Month 3 has 150)

**When to Use Each:**
- **Absolute:** Understanding raw numbers, planning capacity
- **Percentage:** Comparing cohorts of different sizes, identifying trends

### Reading the Retention Curve

**Good Retention Pattern:**
```
Month 0: 100%
Month 1: 40-60%
Month 2: 30-45%
Month 3: 25-35%
Month 6: 15-25%
Month 12: 10-20%
```

**Warning Signs:**
- Steep drop after Month 1 (>60% loss) → Onboarding issues
- Continuous steep decline → Engagement problems
- Month 3 < 20% → Player experience issues

---

## 🎨 Visual Debugging Guide

### When Numbers Don't Look Right

**Metric seems too high:**
1. Check if test accounts are excluded
2. Verify date range is correct
3. Confirm currency filter is applied
4. Check if filtering for specific brand

**Metric seems too low:**
1. Check if too many filters are applied
2. Verify date range includes expected period
3. Check device filter (mobile vs desktop)
4. Confirm country filter isn't too restrictive

**Numbers don't match between reports:**
1. Compare date ranges (daily vs monthly periods)
2. Check currency filters match
3. Verify same player filters applied
4. Check if one report includes bonuses, other doesn't

**Cohort retention looks strange:**
1. Ensure cohort date range is appropriate
2. Check if enough time has passed (Month 12 needs 13 months of data)
3. Verify players in cohort had opportunity to transact
4. Compare absolute vs percentage views

### Common Filter Combinations

**Executive Dashboard:**
- All brands (no brand filter)
- Exclude test accounts ✓
- All countries
- Last 12 months
- All currencies converted to EUR

**Regional Performance:**
- Specific country (e.g., "Romania")
- Exclude test accounts ✓
- Last 6 months
- EUR currency

**Affiliate Performance:**
- Traffic Source = "Affiliate"
- Specific Affiliate ID
- Exclude test accounts ✓
- Last 3 months
- All currencies

**Mobile vs Desktop:**
- Device: "iOS / Safari" vs "Windows / Chrome"
- Exclude test accounts ✓
- Last 30 days
- All brands

---

## 🔄 Report Refresh & Data Timing

### When Data Updates

- **Daily KPIs:** Updates every hour (shows yesterday fully, today partial)
- **Monthly KPIs:** Updates daily (current month updates continuously)
- **Cohort Reports:** Updates daily (historical months are final, current month updates)

### Data Delay

**Transaction Recording:**
- Deposit: Immediate (appears within 1 minute)
- Withdrawal: Immediate (appears within 1 minute)
- Game Bet: Real-time (appears within seconds)
- Bonus Conversion: Up to 5 minutes

**Report Calculation:**
- Most reports: Calculated on-demand when you open them
- Cached for 15-60 minutes (depends on report type)
- TOTAL rows: Calculated fresh each time

---

## ❓ FAQ for Stakeholders

**Q: Why do Daily and Monthly totals sometimes differ?**
A: Different date bucketing. Daily counts exact dates; Monthly groups by calendar month. A player active on Jan 31 and Feb 1 = 2 days but could be 1 or 2 months depending on view.

**Q: What's the difference between GGR and Revenue?**
A: GGR = gaming profit before bonuses. Revenue = GGR minus bonus costs. Revenue is your true bottom line.

**Q: Why does LTV show EUR when player deposited USD?**
A: All amounts are converted to EUR for standardization. Original currency is tracked but converted for reporting.

**Q: Can I see data older than 12 months?**
A: Yes! Use the Start Date and End Date filters to set any date range. Default is 12 months for performance.

**Q: What if a player is in multiple cohorts?**
A: Players appear in only one cohort based on their FIRST deposit date. They're locked to that cohort forever.

**Q: How often should I review these reports?**
A:
- Daily KPIs: Every morning for operational health
- Monthly KPIs: Weekly for trend monitoring
- Cohort reports: Monthly for strategic planning

**Q: What's a "good" conversion rate?**
A: Depends on market, but generally:
- Organic traffic: 8-15%
- Affiliate traffic: 5-12%
- Premium markets (UK, Germany): 10-20%
- Emerging markets: 3-8%

**Q: Why do some cohort cells show blank/null?**
A: Not enough time has passed yet. Example: March 2025 cohort can't show Month 12 data in April 2025.

---

## 📞 Need Help?

**For data questions:**
- Review this guide first
- Check filter settings
- Compare similar time periods
- Contact Analytics Team if numbers still unclear

**For technical issues:**
- Dashboard not loading → Contact IT Support
- Filters not working → Contact Analytics Team
- Need new metrics → Contact Product Team

---

*Last Updated: October 31, 2025*
*Document Version: 1.0*
*For: BTB Gaming Analytics Dashboard*
