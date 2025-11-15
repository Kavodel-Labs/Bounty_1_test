# Full Audit Report: ALL Cohort & LTV Reports Need Updates

**Date:** November 3, 2025
**Status:** 🚨 13 Reports Need Alignment with CTO-Approved Daily KPIs Logic

---

## 📊 Summary

After the FTD logic changes to Daily/Monthly KPIs, I've audited ALL cohort and LTV reports.

**Result:** **ALL 13 reports** use the OLD logic and need updates to match the CTO-approved approach.

| Report Type | Count | Status |
|-------------|-------|--------|
| Cohort Reports | 12 | ⚠️ Need Updates |
| LTV Report | 1 | ⚠️ Needs Updates |
| **TOTAL** | **13** | ⚠️ **ALL Need Updates** |

---

## 🔍 Issues Found (Same 3 Issues in ALL Reports)

### Issue #1: FTD Detection Method (🔴 CRITICAL)

**Current (OLD):** All cohort reports use `MIN(created_at) GROUP BY player_id`
```sql
-- CURRENT CODE (lines 80-103 in most cohort reports)
first_deposits AS (
  SELECT
    t.player_id,
    DATE_TRUNC('month', MIN(t.created_at)) as first_deposit_month,
    MIN(t.created_at) as first_deposit_date
  FROM transactions t
  INNER JOIN filtered_players fp ON t.player_id = fp.player_id
  WHERE t.transaction_category = 'deposit'
    AND t.transaction_type = 'credit'
    AND t.balance_type = 'withdrawable'
    AND t.status = 'completed'
  GROUP BY t.player_id
)
```

**Problem:** `MIN()` with GROUP BY doesn't guarantee true first deposit. If there are:
- Completed deposits
- Pending deposits with earlier timestamps
- Multiple transactions in same millisecond

The MIN() might pick wrong one.

**Should Be (CTO-Approved):**
```sql
-- NEW CODE (from Daily/Monthly KPIs)
ftd_all_deposits AS (
  SELECT
    t.player_id,
    t.created_at,
    t.currency_type,
    ROW_NUMBER() OVER (PARTITION BY t.player_id ORDER BY t.created_at ASC) as deposit_rank
  FROM transactions t
  WHERE t.transaction_category = 'deposit'
    AND t.transaction_type = 'credit'
    AND t.status = 'completed'
),
first_deposits AS (
  SELECT
    fad.player_id,
    DATE_TRUNC('month', fad.created_at) as first_deposit_month,
    fad.created_at AS first_deposit_date
  FROM ftd_all_deposits fad
  INNER JOIN filtered_players fp ON fad.player_id = fp.player_id
  WHERE fad.deposit_rank = 1
    AND fad.created_at >= (SELECT start_date FROM bounds)
    AND fad.created_at < (SELECT end_date FROM bounds) + INTERVAL '1 day'
)
```

---

### Issue #2: Currency Filter Method (🟡 MAJOR)

**Current (OLD):** All cohort reports use 4-level COALESCE cascade
```sql
-- CURRENT CODE (appears in all cohort reports)
[[ AND UPPER(COALESCE(
  t.metadata->>'currency',
  t.cash_currency,
  players.wallet_currency,
  companies.currency
)) IN ({{currency_filter}}) ]]
```

**Problem:**
- Complex, requires extra joins
- Slower performance
- Different from CTO-approved approach

**Should Be (CTO-Approved):**
```sql
-- NEW CODE (from Daily/Monthly KPIs)
[[ AND CASE
  WHEN {{currency_filter}} != 'EUR'
  THEN UPPER(t.currency_type) IN ({{currency_filter}})
  ELSE TRUE
END ]]
```

---

### Issue #3: Extra Table Joins (🟢 MINOR - Performance)

**Current (OLD):** All cohort reports join `players + companies` tables
```sql
-- CURRENT CODE (appears in every CTE)
FROM transactions t
INNER JOIN filtered_players fp ON t.player_id = fp.player_id
JOIN players ON players.id = t.player_id
JOIN companies ON companies.id = players.company_id
```

**Problem:**
- Unnecessary joins (filtered_players already has the filtering)
- Slower queries
- More complex

**Should Be (CTO-Approved):**
```sql
-- NEW CODE (from Daily/Monthly KPIs)
FROM transactions t
INNER JOIN filtered_players fp ON t.player_id = fp.player_id
```

---

## 📋 Complete List of Reports Needing Updates

### Cohort Reports (12 files)

| # | Report Name | File | First Deposit Logic Location | Currency Filter Locations | Extra Joins |
|---|-------------|------|------------------------------|---------------------------|-------------|
| 1 | Depositors Cohort | `depositors_cohort.sql` | Lines 80-103 | Lines 97-102, 131-136 | Lines 87-88, 123-124 |
| 2 | Depositors Cohort % | `depositors_cohort_pct.sql` | Lines 80-103 | Multiple | Multiple |
| 3 | Deposit Amounts Cohort | `deposit_amounts_cohort.sql` | Lines 80-103 | Multiple | Multiple |
| 4 | Deposit Amounts Cohort % | `deposit_amounts_cohort_pct.sql` | Lines 80-103 | Multiple | Multiple |
| 5 | Cash Players Cohort | `cash_players_cohort.sql` | Lines 80-103 (cash bets) | Lines 97-102, ~131-136 | Lines 87-88, ~123-124 |
| 6 | Cash Players Cohort % | `cash_players_cohort_pct.sql` | Lines 80-103 (cash bets) | Multiple | Multiple |
| 7 | Cash Bet Amounts Cohort | `cash_bet_amount_cohort.sql` | Lines 80-103 (cash bets) | Multiple | Multiple |
| 8 | Cash Bet Amounts Cohort % | `cash_bet_amounts_cohort_pct.sql` | Lines 80-103 (cash bets) | Multiple | Multiple |
| 9 | New Depositors Cohort | `new_depositors_cohort.sql` | Lines 80-103 | Multiple | Multiple |
| 10 | New Depositors Cohort % | `new_depositors_cohort_pct.sql` | Lines 80-103 | Multiple | Multiple |
| 11 | Existing Depositors Cohort | `existing_depositors_cohort.sql` | Lines 80-103 | Multiple | Multiple |
| 12 | Existing Depositors Cohort % | `existing_depositors_cohort_pct.sql` | Lines 80-103 | Multiple | Multiple |

### LTV Report (1 file)

| # | Report Name | File | First Deposit Logic Location | Currency Filter Locations | Extra Joins |
|---|-------------|------|------------------------------|---------------------------|-------------|
| 13 | Cohort LTV Lifetime | `cohort_ltv_lifetime.sql` | Lines 65-73 | Lines 72, 92, 112 | Lines 69-70, 89-90, 109-110 |

---

## 🔧 What Needs to Change in Each Report

### For ALL 13 Reports:

**Change 1: Update First Deposit Detection**
- Replace `MIN(created_at) GROUP BY player_id`
- Use `ROW_NUMBER() OVER (PARTITION BY player_id ORDER BY created_at ASC)` with `WHERE deposit_rank = 1`
- Add currency filter to FTD CTE

**Change 2: Simplify Currency Filter**
- Replace 4-level COALESCE: `UPPER(COALESCE(t.metadata->>'currency', t.cash_currency, players.wallet_currency, companies.currency))`
- Use direct field: `UPPER(t.currency_type)`
- Update format: `[[ AND CASE WHEN {{currency_filter}} != 'EUR' THEN UPPER(t.currency_type) IN ({{currency_filter}}) ELSE TRUE END ]]`

**Change 3: Remove Extra Joins**
- Remove: `JOIN players ON players.id = t.player_id`
- Remove: `JOIN companies ON companies.id = players.company_id`
- Keep only: `INNER JOIN filtered_players fp ON t.player_id = fp.player_id`

---

## ⚠️ Special Considerations

### Cash Players Cohort Reports (4 reports)
- These track **first cash bet** not first deposit
- Same ROW_NUMBER() pattern applies
- Just use `transaction_category = 'game_bet'` instead of `'deposit'`

### New/Existing Depositors Cohort (4 reports)
- These segment by registration timing
- Still need FTD logic for cohort assignment
- Same updates apply

### LTV Report (1 report)
- Aggregates multiple metrics (deposits, withdrawals, GGR, bonuses)
- FTD used for cohort assignment
- ALL transaction CTEs need currency filter update
- ALL CTEs have extra joins to remove

---

## 📊 Impact Assessment

| Impact Area | Risk Level | Description |
|-------------|-----------|-------------|
| **Data Accuracy** | 🔴 HIGH | Current MIN() might assign wrong first deposits |
| **Currency Filtering** | 🔴 HIGH | Users can't properly filter by currency in cohorts |
| **Performance** | 🟡 MEDIUM | Extra joins slow down queries |
| **Consistency** | 🔴 HIGH | Cohorts use different logic than KPI reports |
| **User Trust** | 🔴 HIGH | Numbers won't match between KPI and Cohort reports |

---

## 🎯 Recommended Action Plan

### Option A: Update ALL 13 Reports Now (Recommended)
**Time:** ~2-3 hours
**Benefit:** Complete consistency across all reports
**Risk:** Low (following proven CTO-approved pattern)

**Steps:**
1. Update all 13 reports with 3 changes each
2. Test sample report against Daily KPIs
3. Commit all changes together
4. Update documentation

### Option B: Update in Batches
**Time:** Spread over multiple sessions
**Benefit:** Can test incrementally
**Risk:** Medium (inconsistency between reports during transition)

**Batch 1:** Depositors Cohort reports (2 files)
**Batch 2:** Deposit Amounts Cohort reports (2 files)
**Batch 3:** Cash Players/Bet Cohort reports (4 files)
**Batch 4:** New/Existing Depositors reports (4 files)
**Batch 5:** LTV report (1 file)

### Option C: Update Only Critical Ones First
**Time:** ~1 hour
**Benefit:** Quick fix for most-used reports
**Risk:** Medium (some reports still inconsistent)

**Priority Reports:**
1. Depositors Cohort + % (2 files)
2. LTV Report (1 file)
3. Deposit Amounts Cohort + % (2 files)

---

## ✅ Verification Checklist

After updates, verify:

- [ ] FTD counts match between Daily KPIs and Cohort reports
- [ ] Currency filter works in all cohort reports
- [ ] Performance improved (queries faster)
- [ ] Numbers consistent across all reports
- [ ] TOTAL rows calculate correctly
- [ ] All 13 reports tested with real data

---

## 📝 Next Steps

**Decision Needed:** Which option do you want?

1. **Update ALL 13 now** - I can do this systematically
2. **Update in batches** - Tell me which batch to start with
3. **Update priority reports first** - I'll do the top 5 most important

**Estimated Time:**
- Full update (all 13): ~2-3 hours total work
- Per report: ~10-15 minutes each
- Testing: ~30 minutes after all done

**My Recommendation:** Option A (Update ALL 13 now) - ensures complete consistency and you won't have to worry about which reports use which logic.

---

**Status:** ⚠️ AWAITING YOUR DECISION - Ready to update when you approve!

**Document Version:** 1.0
**Last Updated:** November 3, 2025
**Prepared By:** Claude (AI Assistant)
