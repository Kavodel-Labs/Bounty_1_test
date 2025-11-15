# Daily KPIs vs Monthly KPIs - Comprehensive Comparison

**Purpose:** Document all differences between Daily KPIs (CTO-approved version) and Monthly KPIs to ensure alignment.

**Status:** Daily KPIs = ✅ CTO-Approved | Monthly KPIs = ⚠️ Needs Alignment

**Date:** November 3, 2025

---

## 🚨 CRITICAL DIFFERENCES

### 1. FTD Calculation Logic - **MAJOR DIFFERENCE**

| Aspect | Daily KPIs (✅ APPROVED) | Monthly KPIs (⚠️ DIFFERENT) | Impact |
|--------|-------------------------|---------------------------|--------|
| **Data Source** | `transactions` table | `players.first_purchase_date` field | Monthly uses denormalized field |
| **Method** | `ROW_NUMBER() OVER (PARTITION BY player_id ORDER BY created_at ASC)` to find rank=1 | Direct field lookup: `p.first_purchase_date` | Daily ensures true first deposit |
| **Lines** | Daily: 123-148 | Monthly: 118-128 | - |
| **SQL (Daily)** | ```sql
ftd_all_deposits AS (
  SELECT
    t.player_id,
    t.created_at,
    t.currency_type,
    ROW_NUMBER() OVER (
      PARTITION BY t.player_id
      ORDER BY t.created_at ASC
    ) as deposit_rank
  FROM transactions t
  WHERE t.transaction_category = 'deposit'
    AND t.transaction_type = 'credit'
    AND t.status = 'completed'
),
ftd_first AS (
  SELECT player_id, created_at AS first_deposit_ts
  FROM ftd_all_deposits
  INNER JOIN filtered_players fp ON fad.player_id = fp.player_id
  WHERE deposit_rank = 1
    AND created_at >= (SELECT start_date FROM bounds)
    AND created_at < (SELECT end_date FROM bounds) + INTERVAL '1 day'
    [[ AND CASE
      WHEN {{currency_filter}} != 'EUR'
      THEN UPPER(currency_type) IN ({{currency_filter}})
      ELSE TRUE
    END ]]
)
``` | ```sql
ftd_first AS (
  SELECT
    p.id AS player_id,
    p.first_purchase_date::timestamp AS first_deposit_ts
  FROM players p
  INNER JOIN filtered_players fp ON p.id = fp.player_id
  WHERE p.first_purchase_date IS NOT NULL
    AND p.first_purchase_date >= (SELECT start_date FROM bounds)
    AND p.first_purchase_date < (SELECT end_date FROM bounds) + INTERVAL '1 day'
)
``` | - |
| **Currency Filter** | Applied in FTD calculation | NOT applied in FTD calculation | Monthly misses currency filtering for FTDs |
| **Risk** | ✅ Accurate | ⚠️ **Relies on denormalized field accuracy** | If `players.first_purchase_date` is stale/incorrect, FTD counts will be wrong |

**Recommendation:** Monthly should use same ROW_NUMBER() approach as Daily for consistency.

---

### 2. "New FTDs" Definition - **MAJOR BUSINESS LOGIC DIFFERENCE**

| Aspect | Daily KPIs (✅ APPROVED) | Monthly KPIs (⚠️ DIFFERENT) | Impact |
|--------|-------------------------|---------------------------|--------|
| **Definition** | FTDs where player **registered within the reporting window** | FTDs where player **deposited in SAME MONTH as registration** | Completely different business meaning |
| **Lines** | Daily: 164 | Monthly: 144 | - |
| **SQL (Daily)** | ```sql
COUNT(*) FILTER (
  WHERE f.registration_ts >= (SELECT start_date FROM bounds)
) AS new_ftds
``` | ```sql
COUNT(*) FILTER (
  WHERE DATE_TRUNC('month', f.registration_ts)
      = DATE_TRUNC('month', f.first_deposit_ts)
) AS new_ftds
``` | - |
| **Example** | Player registers Jan 15, deposits Jan 20. <br/>**Daily report (Jan):** Counted as "New FTD" ✅<br/>**Monthly report (March viewing Jan-March):** NOT counted as "New FTD" ❌ | Player registers Jan 15, deposits Jan 20. <br/>**Both count as "New FTD"** because reg month = deposit month | Daily definition changes based on date filter |
| **Risk** | ⚠️ **Different meaning** across reports | ✅ **Consistent business logic** | Users will be confused by different "New FTDs" counts |

**Business Question:** Which definition is correct?
- **Daily definition:** "New FTDs" = players who JUST registered (in this period) and deposited
- **Monthly definition:** "New FTDs" = players who deposited IMMEDIATELY (same month as registration)

**Recommendation:** Clarify with stakeholders which definition to use. Monthly's definition seems more intuitive (immediate depositors).

---

### 3. Currency Filter Implementation - **CRITICAL TECHNICAL DIFFERENCE**

| Aspect | Daily KPIs (✅ APPROVED) | Monthly KPIs (⚠️ DIFFERENT) | Impact |
|--------|-------------------------|---------------------------|--------|
| **Method** | Direct field reference: `t.currency_type` | 4-level COALESCE cascade | Monthly is more complex |
| **FTD CTE** | Lines 143-147 | NO CURRENCY FILTER | Monthly FTDs ignore currency |
| **Deposit CTE** | Lines 206-210 | Lines 188-193 | Different approaches |
| **Withdrawal CTE** | Lines 254-258 | Lines 237-242 | Different approaches |
| **Active Players CTE** | Lines 274-278 | Lines 260-265 | Different approaches |
| **Betting CTE** | Lines 336-340 | Lines 321-326 | Different approaches |
| **Bonus CTEs** | Lines 365-369, 393-397 | Lines 352-357, 382-387 | Different approaches |
| **SQL (Daily)** | ```sql
[[ AND CASE
  WHEN {{currency_filter}} != 'EUR'
  THEN UPPER(t.currency_type) IN ({{currency_filter}})
  ELSE TRUE
END ]]
``` | ```sql
[[ AND UPPER(COALESCE(
  t.metadata->>'currency',
  t.cash_currency,
  players.wallet_currency,
  companies.currency
)) IN ({{currency_filter}}) ]]
``` | - |
| **Assumption** | Assumes `t.currency_type` exists and is populated | Falls back through 4 fields | Daily cleaner but requires field |
| **Risk** | ⚠️ **Fails if currency_type doesn't exist** | ✅ **More robust fallback** | Need to verify currency_type field exists |

**Recommendation:** Verify if `transactions.currency_type` field exists. If not, Daily needs to revert to COALESCE approach.

---

### 4. EUR Amount Conversion - **MINOR DIFFERENCE**

| Aspect | Daily KPIs (✅ APPROVED) | Monthly KPIs (⚠️ DIFFERENT) | Impact |
|--------|-------------------------|---------------------------|--------|
| **Deposit EUR** | `COALESCE(t.eur_amount, 0)` | `COALESCE(t.eur_amount, t.amount)` | Daily returns 0 if NULL |
| **Lines** | Daily: 196 | Monthly: 176 | - |
| **SQL (Daily)** | ```sql
CASE
  WHEN {{currency_filter}} = 'EUR'
  THEN COALESCE(t.eur_amount, 0)
  ELSE t.amount
END
``` | ```sql
CASE
  WHEN {{currency_filter}} = 'EUR'
  THEN COALESCE(t.eur_amount, t.amount)
  ELSE t.amount
END
``` | - |
| **Behavior** | If eur_amount is NULL, use 0 | If eur_amount is NULL, use original amount | Daily more conservative |
| **Risk** | ⚠️ **May undercount** if EUR amounts not populated | ⚠️ **May double-count** if amount already in EUR | Need to verify eur_amount population |

**Recommendation:** Clarify if `eur_amount` is always populated. Monthly's fallback to `amount` is safer.

---

### 5. Transaction CTE Joins - **PERFORMANCE DIFFERENCE**

| Aspect | Daily KPIs (✅ APPROVED) | Monthly KPIs (⚠️ DIFFERENT) | Impact |
|--------|-------------------------|---------------------------|--------|
| **Joins** | Only `filtered_players` | `filtered_players + players + companies` | Monthly has extra joins |
| **Lines** | Daily: 204 | Monthly: 184-186 | - |
| **SQL (Daily)** | ```sql
LEFT JOIN transactions t ON ...
INNER JOIN filtered_players fp ON t.player_id = fp.player_id
``` | ```sql
LEFT JOIN transactions t ON ...
INNER JOIN filtered_players fp ON t.player_id = fp.player_id
JOIN players ON players.id = t.player_id
JOIN companies ON companies.id = players.company_id
``` | - |
| **Reason** | Currency filter uses `t.currency_type` directly | Currency filter needs `players.wallet_currency` and `companies.currency` for COALESCE | Monthly needs extra data |
| **Performance** | ✅ Faster (fewer joins) | ⚠️ Slower (more joins) | Monthly may be slower |
| **Applied To** | All transaction CTEs: deposit_metrics, withdrawal_metrics, active_players, betting_metrics, bonus_converted, bonus_cost | Same CTEs | - |

**Recommendation:** If Daily's `currency_type` approach works, it's more efficient.

---

## 📊 IDENTICAL CALCULATIONS (Same in Both)

These metrics use the same logic in both Daily and Monthly:

✅ **Registrations**
- Total registrations: `COUNT(pr.*)`
- Complete registrations: `COUNT(CASE WHEN pr.email_verified = TRUE THEN 1 END)`

✅ **FTD Breakdowns** (after FTD list is determined)
- Old FTDs: `COUNT(*) FILTER (WHERE registration month < deposit month)` (Monthly) vs `registration_ts < bounds.start_date` (Daily - different!)
- D0 FTDs: `COUNT(*) FILTER (WHERE registration day = deposit day)`
- Late FTDs: `COUNT(*) FILTER (WHERE registration day != deposit day)`

✅ **Deposit Metrics** (amount calculation)
- Same EUR conversion logic (except NULL handling)
- Same transaction filters: category='deposit', type='credit', status='completed', balance_type='withdrawable'

✅ **Withdrawal Metrics**
- Same EUR conversion logic
- Same transaction filters: category='withdrawal', type='debit', status='completed'/'cancelled', balance_type='withdrawable'

✅ **Active Players**
- Active Players: `COUNT(DISTINCT CASE WHEN t.transaction_category='game_bet' THEN t.player_id END)`
- Real Active Players: `COUNT(DISTINCT CASE WHEN t.transaction_category='game_bet' AND t.balance_type='withdrawable' THEN t.player_id END)`

✅ **Betting Metrics**
- Cash Bet: category='game_bet', type='debit', balance_type='withdrawable'
- Cash Win: category='game_bet', type='credit', balance_type='withdrawable'
- Promo Bet: category='bonus', type='debit', balance_type='non-withdrawable'
- Promo Win: category='bonus', type='credit', balance_type='non-withdrawable'

✅ **Bonus Metrics**
- Bonus Converted: category='bonus_completion', type='credit', balance_type='withdrawable'
- Bonus Cost: Same as Bonus Converted

✅ **Calculated Metrics** (all derived metrics identical)
- Conversion rates, Bonus ratios, Payout %, CashFlow to GGR, etc.

---

## 🔧 OTHER DIFFERENCES (Non-Critical)

### 6. Default Date Range

| Report | Default Start Date | Default End Date | Window Size |
|--------|-------------------|------------------|-------------|
| **Daily KPIs** | `end_date - INTERVAL '31 day'` | `CURRENT_DATE` | 31 days |
| **Monthly KPIs** | `DATE_TRUNC('month', end_date - INTERVAL '12 months')` | Last day of end_date's month | 12 months |

**Lines:** Daily 28, Monthly 26

✅ **Expected** - different report types need different defaults.

---

### 7. Date Series Generation

| Report | Granularity | SQL |
|--------|-------------|-----|
| **Daily KPIs** | One row per day | `generate_series(..., INTERVAL '1 day')` |
| **Monthly KPIs** | One row per month | `generate_series(..., INTERVAL '1 month')` |

**Lines:** Daily 35-45, Monthly 32-42

✅ **Expected** - different report granularities.

---

### 8. Date Column Format

| Report | Column Name | Format |
|--------|-------------|--------|
| **Daily KPIs** | "Date" | `ds.report_date::text` (YYYY-MM-DD) |
| **Monthly KPIs** | "Month" | `TO_CHAR(ms.report_month, 'FMMonth YYYY')` (e.g., "January 2025") |

**Lines:** Daily 405, Monthly 395

✅ **Expected** - different display formats.

---

### 9. Bounds End Date Handling

| Report | End Date Logic |
|--------|----------------|
| **Daily KPIs** | Uses raw end_date |
| **Monthly KPIs** | Clamps to last day of end month: `DATE_TRUNC('month', end_date_raw) + INTERVAL '1 month' - INTERVAL '1 day'` |

**Lines:** Daily 24-31, Monthly 23-30

✅ **Expected** - ensures monthly report includes full month.

---

## 📋 SUMMARY OF CRITICAL ISSUES

| Issue | Severity | Daily (Approved) | Monthly (Current) | Recommendation |
|-------|----------|------------------|-------------------|----------------|
| **1. FTD Data Source** | 🔴 CRITICAL | ROW_NUMBER() on transactions | players.first_purchase_date field | Align Monthly to use transactions with ROW_NUMBER() |
| **2. FTD Currency Filter** | 🔴 CRITICAL | Applied | NOT applied | Add currency filter to Monthly FTD CTE |
| **3. New FTDs Definition** | 🟡 MAJOR | Registered in window | Deposited same month as registration | **Business decision needed** - which definition is correct? |
| **4. Currency Filter Method** | 🟡 MAJOR | Direct currency_type field | 4-level COALESCE | **Verify currency_type field exists** - if not, Daily needs fix |
| **5. EUR Amount NULL Handling** | 🟠 MEDIUM | Falls back to 0 | Falls back to amount | **Verify eur_amount population** - Monthly safer |
| **6. Extra Joins** | 🟢 MINOR | Only filtered_players | +players +companies | Performance impact, tied to currency filter method |

---

## 🎯 RECOMMENDED ACTIONS

### Priority 1 - CRITICAL (Must Fix)

1. **Align FTD Calculation** (Issue #1)
   - Update Monthly KPIs lines 118-128 to use ROW_NUMBER() approach like Daily
   - Copy ftd_all_deposits CTE from Daily (lines 123-133)

2. **Add Currency Filter to Monthly FTDs** (Issue #2)
   - Monthly KPIs lines 118-128 need currency filter like Daily lines 143-147
   - Currently Monthly FTD ignores currency_filter parameter

### Priority 2 - MAJOR (Business Decision)

3. **Clarify "New FTDs" Definition** (Issue #3)
   - **Option A:** Keep Daily's definition (registered in window) - changes with date range
   - **Option B:** Keep Monthly's definition (deposited same month as registration) - consistent
   - **Recommended:** Use Monthly's definition (more intuitive) and update Daily to match

### Priority 3 - VERIFICATION NEEDED

4. **Verify Currency Field** (Issue #4)
   - Check if `transactions.currency_type` field exists
   - If NOT: Daily needs to revert to Monthly's COALESCE approach
   - If YES: Monthly should switch to Daily's simpler approach

5. **Verify EUR Amount Population** (Issue #5)
   - Check if `transactions.eur_amount` is always populated
   - If NOT: Use Monthly's fallback to `amount`
   - If YES: Daily's fallback to 0 is acceptable

---

## 🧪 TEST CASES FOR VALIDATION

After alignment, run these test cases:

### Test 1: FTD Count Matches
```sql
-- Daily KPIs: Count FTDs for January 2025
-- Monthly KPIs: Count FTDs for January 2025
-- Expected: Same count
```

### Test 2: Currency Filter Works
```sql
-- Set currency_filter = 'USD'
-- Daily KPIs: Should only show USD FTDs
-- Monthly KPIs: Should only show USD FTDs
-- Expected: Same counts
```

### Test 3: New FTDs Definition
```sql
-- Player registers Jan 15, deposits Jan 20
-- Run Daily for Jan 1-31: Should count as New FTD
-- Run Monthly for Jan: Should count as New FTD
-- Expected: Same result (after alignment)
```

### Test 4: EUR Conversion
```sql
-- Transaction with amount=100, eur_amount=NULL
-- Daily: Shows 0 (or amount if not EUR filter)
-- Monthly: Shows 100 (or amount if not EUR filter)
-- Expected: Define expected behavior
```

---

## 📝 CHANGE LOG

| Date | Change | Files |
|------|--------|-------|
| Nov 3, 2025 | Daily KPIs updated with ROW_NUMBER() FTD logic, currency_type filter | daily_kpis.sql |
| Nov 3, 2025 | Monthly KPIs still using old first_purchase_date approach | monthly_kpis.sql |
| **Pending** | Align Monthly to match Daily's approved logic | monthly_kpis.sql |

---

**Status:** 🔴 **MONTHLY KPIS NEEDS UPDATES**

**Next Steps:**
1. Get stakeholder approval on "New FTDs" definition
2. Verify database schema (currency_type, eur_amount fields)
3. Update Monthly KPIs to align with approved Daily KPIs logic
4. Run test cases to validate alignment

**Document Version:** 1.0
**Last Updated:** November 3, 2025
