# Changelog

All notable changes to the SQL Reports - Gaming Platform Analytics project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2025-11-15

### 🎉 Initial Production Release

This marks the first production-ready release of the SQL Reports system with fully aligned calculations, comprehensive documentation, and clean repository structure.

### ✨ Added

#### SQL Reports (18 Total)
- **KPI Reports (2)**
  - `sql_reports_adjusted/kpi/daily_kpis.sql` - Daily key performance indicators
  - `sql_reports_adjusted/kpi/monthly_kpis.sql` - Monthly key performance indicators

- **Email Reports (1)**
  - `sql_reports_adjusted/email/daily_email_report.sql` - Executive daily summary with estimations

- **LTV Reports (1)**
  - `sql_reports_adjusted/ltv/cohort_ltv_lifetime.sql` - Lifetime value cohort analysis

- **Bonus Reports (1)**
  - `sql_reports_adjusted/bonus/bonus_report_dashboard.sql` - Bonus campaign performance tracking

- **Cohort Reports (12)**
  - Cash bet amount tracking (2 reports: absolute and percentage)
  - Cash players tracking (2 reports: absolute and percentage)
  - Deposit amounts tracking (2 reports: absolute and percentage)
  - Depositors tracking (2 reports: absolute and percentage)
  - Existing depositors tracking (2 reports: absolute and percentage)
  - New depositors tracking (2 reports: absolute and percentage)

#### Documentation
- **Stakeholder Guides (7 files)**
  - `docs/reports/README.md` - Master documentation index
  - `docs/reports/kpi/daily_kpis.md` - Daily KPI user guide
  - `docs/reports/kpi/monthly_kpis.md` - Monthly KPI user guide
  - `docs/reports/email/daily_email_report.md` - Email report user guide
  - `docs/reports/ltv/cohort_ltv_lifetime.md` - LTV report user guide
  - `docs/reports/bonus/bonus_report_dashboard.md` - Bonus report user guide
  - `docs/reports/cohort/README.md` - Cohort reports master guide

- **Technical Documentation (6 files)**
  - `sql_reports_adjusted/STAKEHOLDER_GUIDE.md` - Comprehensive business user guide
  - `sql_reports_adjusted/STAKEHOLDER_GUIDE_V2.md` - Enhanced stakeholder guide
  - `sql_reports_adjusted/QUICK_REFERENCE.md` - Quick reference for all reports
  - `sql_reports_adjusted/TECHNICAL_REFERENCE_TABLE.md` - Technical specifications
  - `sql_reports_adjusted/COHORT_AUDIT_REPORT.md` - Cohort report audit documentation
  - `sql_reports_adjusted/CORRECTIONS_SUMMARY.md` - Summary of calculation corrections
  - `sql_reports_adjusted/DAILY_VS_MONTHLY_COMPARISON.md` - Daily vs monthly comparison guide
  - `sql_reports_adjusted/email/DAILY_EMAIL_REPORT_COMPARISON.md` - Email report comparison

- **Repository Documentation**
  - `README.md` - Complete repository overview and quick start guide

### 🔄 Changed

#### Promo Bet/Win Calculation Alignment
**Previous Logic:**
```sql
WHERE balance_type = 'non-withdrawable'
```

**New Aligned Logic (Applied to ALL reports):**
```sql
WHERE external_transaction_id IS NOT NULL
```

**Impact:** Consistent promo bet/win tracking across:
- `daily_kpis.sql`
- `monthly_kpis.sql`
- `daily_email_report.sql`
- `cohort_ltv_lifetime.sql`

**Rationale:** The `external_transaction_id IS NOT NULL` filter more accurately identifies promotional transactions by checking for external bonus system references rather than balance type.

---

#### Granted Bonus Tracking
**Added to ALL reports:**
```sql
-- Granted Bonus (Bonus Cost)
COALESCE(SUM(CASE
  WHEN player_bonus_id IS NOT NULL
  AND transaction_category = 'bonus'
  AND transaction_type = 'credit'
  AND status = 'completed'
  THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as granted_bonus_[period]
```

**Impact:** New metric added to:
- `daily_kpis.sql` - Granted bonus yesterday, MTD, previous month
- `monthly_kpis.sql` - Granted bonus by month
- `daily_email_report.sql` - Granted bonus yesterday, MTD, previous month, estimation
- `cohort_ltv_lifetime.sql` - Granted bonus by cohort

**Rationale:** Provides accurate tracking of bonus costs by filtering for transactions with player bonus IDs.

---

#### NGR Calculation Alignment
**Formula Applied Consistently:**
```
NGR = Cash GGR - Provider Fee (9%) - Payment Fee (8%) - Platform Fee (1%) - Bonus Cost
```

**Components:**
- **Provider Fee:** 9% of Cash GGR
- **Payment Fee:** 8% of (Deposits + Withdrawals)
- **Platform Fee:** 1% of Cash GGR
- **Bonus Cost:** Granted bonus amounts

**Impact:** Aligned NGR calculations between:
- `daily_email_report.sql` (updated to match LTV)
- `cohort_ltv_lifetime.sql` (source of truth)

**Rationale:** Ensures consistent NGR reporting across executive summaries and cohort analysis.

---

#### Daily Email Report Estimations
**Formula Applied:**
```
Estimation = (MTD Value / Days Elapsed MTD) × Total Days in Month
```

**Applied to ALL metrics:**
- Base metrics: Registrations, FTDs, Deposits, Withdrawals, Cash Bets, Promo Bets, etc.
- Derived metrics: Cash GGR, Provider Fee, Payment Fee, Platform Fee, NGR, etc.

**Rationale:** Provides linear projection for end-of-month forecasting based on month-to-date performance.

---

### 🗑️ Removed

#### Deprecated Metrics
- **From `daily_email_report.sql`:**
  - `cash_ggr_casino` (replaced by `cash_ggr`)
  - `total_ggr_casino` (consolidated into `cash_ggr`)
  - `platform_fee` displayed separately (now included in NGR calculation only)
  - `turnover_casino` (removed per stakeholder request)

#### Cleanup - Deleted Files
- `ACTION_PLAN.md` (40KB) - Obsolete planning document
- `Business Overview_full sql_BTB_11.md` (168KB) - Outdated business overview
- `claude review.md` (10KB) - Development notes
- `gai.md` (16KB) - Research notes
- `research.md` (20KB) - Research notes
- `sql_reports/` folder (196KB, 17 files) - Duplicate/outdated SQL files
- `sql_reports_adjusted/email/daily_email_report_ORIGINAL.sql` - Pre-alignment backup

#### Cleanup - Deleted Branches
**Local branches:**
- `claude/bonus-report-structure-mismatch-011CV4iL6FyY1jcXVgmhGLZe`
- `claude/explore-repo-contents-011CUcaASLvw2dzXu5c94Dgu`
- `claude/ltv-ngr-calculation-fix-011CV4mbCVgMWNp25zxRN61f`

**Remote branches:**
- `origin/claude/bonus-report-structure-mismatch-011CV4iL6FyY1jcXVgmhGLZe`
- `origin/claude/explore-repo-contents-011CUcaASLvw2dzXu5c94Dgu`
- `origin/claude/ltv-ngr-calculation-fix-011CV4mbCVgMWNp25zxRN61f`

### 🏷️ Tagged
- **v1.0** - Production release tag (local)

---

## Calculation Reference

### Key Formulas

#### Deposits
```sql
WHERE transaction_category = 'deposit'
  AND transaction_type = 'credit'
  AND status = 'completed'
  AND balance_type = 'withdrawable'
```

#### Withdrawals
```sql
WHERE transaction_category = 'withdrawal'
  AND transaction_type = 'debit'
  AND status = 'completed'
  AND balance_type = 'withdrawable'
```

#### Cash Bets
```sql
WHERE transaction_category = 'bet'
  AND external_transaction_id IS NULL
```

#### Promo Bets
```sql
WHERE transaction_category = 'bet'
  AND external_transaction_id IS NOT NULL
```

#### Cash Wins
```sql
WHERE transaction_category = 'win'
  AND external_transaction_id IS NULL
```

#### Promo Wins
```sql
WHERE transaction_category = 'win'
  AND external_transaction_id IS NOT NULL
```

#### Granted Bonus
```sql
WHERE transaction_category = 'bonus'
  AND transaction_type = 'credit'
  AND status = 'completed'
  AND player_bonus_id IS NOT NULL
```

#### Cash GGR
```
Cash GGR = Cash Bets - Cash Wins
```

#### NGR (Net Gaming Revenue)
```
NGR = Cash GGR - Provider Fee - Payment Fee - Platform Fee - Granted Bonus

Where:
  Provider Fee = Cash GGR × 0.09
  Payment Fee = (Deposits + Withdrawals) × 0.08
  Platform Fee = Cash GGR × 0.01
  Granted Bonus = Sum of granted bonus transactions
```

---

## Repository Structure (v1.0)

```
.
├── CHANGELOG.md                 # This file
├── README.md                    # Repository overview
├── sql_reports_adjusted/        # Production SQL reports
│   ├── kpi/                     # KPI reports (2)
│   ├── email/                   # Email reports (1)
│   ├── ltv/                     # LTV reports (1)
│   ├── bonus/                   # Bonus reports (1)
│   └── cohort/                  # Cohort reports (12)
└── docs/
    └── reports/                 # Stakeholder documentation
        ├── README.md            # Documentation index
        ├── kpi/                 # KPI guides
        ├── email/               # Email report guides
        ├── ltv/                 # LTV guides
        ├── bonus/               # Bonus guides
        └── cohort/              # Cohort guides
```

---

## Migration Guide

### For Existing Users

If you were using the previous versions of these reports, please note the following breaking changes:

1. **Promo Bet/Win calculations have changed** - Results may differ from previous reports
2. **Granted Bonus is a new metric** - Now tracked separately from other bonus metrics
3. **NGR calculation includes Granted Bonus** - NGR values will be lower than previous calculations
4. **Daily Email Report removed metrics** - `turnover_casino`, `cash_ggr_casino`, `total_ggr_casino` no longer available

### Action Items
- ✅ Review new calculation logic in stakeholder documentation
- ✅ Update any downstream reports or dashboards that depend on removed metrics
- ✅ Validate NGR values with finance team
- ✅ Update any automated processes that reference old file paths

---

## Future Versions

### Versioning Scheme
- **Major version (X.0.0):** Breaking changes to calculations or data structure
- **Minor version (1.X.0):** New reports or metrics added (backward compatible)
- **Patch version (1.0.X):** Bug fixes, documentation updates, performance improvements

### Planned Features (Future Releases)
- [ ] Additional cohort analysis dimensions
- [ ] Real-time dashboard integration
- [ ] Automated data quality checks
- [ ] Historical trend analysis reports

---

## Contributors

- Initial development and calculation alignment: Claude AI Agent
- Stakeholder requirements: Kavodel Labs Team

---

## Support

For questions or issues:
- **Technical Issues:** Create an issue in the repository
- **Business Questions:** Contact analytics team
- **Documentation:** Refer to `docs/reports/` for detailed guides

---

**Note:** This changelog will be updated with each release to track all changes to the SQL reporting system.
