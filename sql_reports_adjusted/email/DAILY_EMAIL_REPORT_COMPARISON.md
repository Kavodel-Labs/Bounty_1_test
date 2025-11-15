# Daily Email Report - Version Comparison

## Overview

This document compares the **ORIGINAL** Daily Email Report (V4) with the **CTO-APPROVED** adjusted version (V5) aligned with STAKEHOLDER GUIDE V2 formulas.

---

## 📊 Key Difference: NGR Calculation

### ORIGINAL V4 Formula:
```
NGR = Cash GGR - Bonus Cost
```

### CTO-APPROVED V5 Formula:
```
NGR = Cash GGR - Provider Fee - Payment Fee - Platform Fee - Bonus Cost

Where:
- Provider Fee = Cash GGR × 0.09 (9%)
- Payment Fee = (Deposits + Withdrawals) × 0.08 (8%)
- Platform Fee = Cash GGR × 0.01 (1%)
```

---

## ⚠️ Critical Issue in Original

The **ORIGINAL version is missing 3 fee deductions** from NGR calculation:

| Fee | Calculation | Impact |
|-----|-------------|--------|
| **Provider Fee** | Cash GGR × 0.09 | -9% of Cash GGR |
| **Payment Fee** | (Deposits + Withdrawals) × 0.08 | -8% of transaction volume |
| **Platform Fee** | Cash GGR × 0.01 | -1% of Cash GGR |

**Result:** Original NGR is **over-reported** by approximately 10-20% depending on transaction volumes.

---

## 🔄 What Changed in V5

### 1. Added Fee Calculation CTE
**New Section:** `fee_calculations` CTE added between `calculated_metrics` and `final_calculations`

Calculates all 3 fees for:
- Yesterday
- Month-to-Date (MTD)
- Previous Month
- Estimation (projected month-end)

### 2. Updated NGR Formula
**Old:**
```sql
(cash_ggr_yesterday - bonus_cost_yesterday) as ngr_yesterday
```

**New:**
```sql
(cash_ggr_yesterday - provider_fee_yesterday - payment_fee_yesterday - platform_fee_yesterday - bonus_cost_yesterday) as ngr_yesterday
```

Applied to all time periods (yesterday, MTD, prev month, estimation)

### 3. Added Fee Rows to Report Output
**New Rows Added:**
- Row 6: PROVIDER FEE (9%)
- Row 7: PAYMENT FEE (8%)
- Row 8: PLATFORM FEE (1%)

**Row Numbers Shifted:**
- BONUS COST: Row 7 → Row 9
- NGR: Row 6 → Row 10
- HOLD % (CASH): Row 9 → Row 11

### 4. Removed "TOTAL REVENUE" Row
- Original had duplicate row showing NGR as "TOTAL REVENUE" (Row 8)
- Removed in V5 to avoid confusion

---

## 📋 Report Output Comparison

### ORIGINAL V4 Output (9 rows):
1. DEPOSITS
2. PAID WITHDRAWALS
3. CASHFLOW
4. CASH TURNOVER
5. CASH GGR
6. NGR ❌ (incorrect - missing fees)
7. BONUS COST
8. TOTAL REVENUE (duplicate of NGR)
9. HOLD % (CASH)

### CTO-APPROVED V5 Output (11 rows):
1. DEPOSITS
2. PAID WITHDRAWALS
3. CASHFLOW
4. CASH TURNOVER
5. CASH GGR
6. **PROVIDER FEE (9%)** ⭐ NEW
7. **PAYMENT FEE (8%)** ⭐ NEW
8. **PLATFORM FEE (1%)** ⭐ NEW
9. BONUS COST
10. NGR ✅ (correct - includes all fees)
11. HOLD % (CASH)

---

## 💰 Impact Example

**Scenario:** A typical day with:
- Cash GGR: €10,000
- Deposits: €8,000
- Withdrawals: €5,000
- Bonus Cost: €500

### ORIGINAL V4 Calculation:
```
NGR = €10,000 - €500 = €9,500
```

### CTO-APPROVED V5 Calculation:
```
Provider Fee = €10,000 × 0.09 = €900
Payment Fee = (€8,000 + €5,000) × 0.08 = €1,040
Platform Fee = €10,000 × 0.01 = €100
Total Fees = €900 + €1,040 + €100 + €500 = €2,540

NGR = €10,000 - €2,540 = €7,460
```

**Difference:** €9,500 - €7,460 = **€2,040 over-reported** (27% higher)

---

## ✅ Formula Verification

All calculations in V5 match STAKEHOLDER GUIDE V2:

| Metric | V5 Formula | Stakeholder Guide V2 | Status |
|--------|------------|----------------------|--------|
| Cash GGR | `cash_bet - cash_win` | ✓ | ✅ Match |
| Provider Fee | `Cash GGR × 0.09` | ✓ | ✅ Match |
| Payment Fee | `(Deposits + Withdrawals) × 0.08` | ✓ | ✅ Match |
| Platform Fee | `Cash GGR × 0.01` | ✓ | ✅ Match |
| NGR | `Cash GGR - all fees - bonus` | ✓ | ✅ Match |
| Hold % | `(Cash GGR / Cash Turnover) × 100` | ✓ | ✅ Match |

---

## 📁 File Locations

| File | Purpose | Status |
|------|---------|--------|
| `daily_email_report_ORIGINAL.sql` | Original V4 version (reference only) | ❌ Do not use |
| `daily_email_report.sql` | CTO-approved V5 (aligned with V2 formulas) | ✅ Use this |
| `DAILY_EMAIL_REPORT_COMPARISON.md` | This comparison document | 📄 Reference |

---

## 🎯 Recommendation

**Use `daily_email_report.sql` (V5) for all production reporting.**

The original version significantly over-reports NGR by missing critical fee deductions. V5 provides accurate profitability metrics aligned with your company's standard calculations.

---

## 📊 Report Columns Explained

All reports show 5 columns:

| Column | Description |
|--------|-------------|
| **Yesterday Value** | Actual value for yesterday (CURRENT_DATE - 1) |
| **MTD Value** | Month-to-date total (1st of month through today) |
| **Estimation Value** | Linear projection to month-end based on MTD performance |
| **Actual Prev Month** | Full previous month total (for comparison) |
| **Percentage Difference** | % change: (Estimation - Prev Month) / Prev Month × 100 |

**Estimation Method:**
```
Estimated Month Total = (MTD Value / Days Elapsed) × Total Days in Month
```

---

## 🔧 Technical Notes

### Unchanged Elements (Same in both versions):
✅ Date range calculations
✅ Transaction filters (status, balance_type, category)
✅ Estimation methodology (linear projection)
✅ Currency formatting (EUR with € symbol)
✅ Percentage calculations
✅ Hold % calculation

### Changed Elements (V4 → V5):
🔄 NGR formula (added 3 fees)
🔄 CTE structure (added fee_calculations)
🔄 Report output (added 3 fee rows)
🔄 Row numbering (shifted due to new rows)

---

## 📞 Questions?

**Q: Can I still use the original version?**
A: No. The original significantly over-reports profitability. Use V5 only.

**Q: Will my NGR numbers decrease?**
A: Yes, by 10-20% typically. This is accurate - the original was over-reporting.

**Q: Do I need to update historical reports?**
A: Recommended. Historical data using V4 should be recalculated with V5 for accurate comparisons.

**Q: Are fees always the same percentages?**
A: Current rates: Provider 9%, Payment 8%, Platform 1%. If these change, update the SQL constants.

**Q: Why was "TOTAL REVENUE" removed?**
A: It was a duplicate of NGR. Having both was confusing. NGR is the correct term.

---

**Document Version:** 1.0
**Last Updated:** November 2025
**Related Documents:** STAKEHOLDER_GUIDE_V2.md, TECHNICAL_REFERENCE_TABLE.md
