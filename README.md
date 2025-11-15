# SQL Reports - Gaming Platform Analytics

## 📊 Overview

This repository contains production-ready SQL reports for a gaming/casino platform analytics system. All reports are optimized for Metabase and provide comprehensive business intelligence across player behavior, revenue metrics, and campaign performance.

**Last Updated:** November 2025
**Version:** 1.0

---

## 📁 Repository Structure

```
.
├── sql_reports_adjusted/    # Production SQL reports (18 reports)
│   ├── kpi/                 # Daily and Monthly KPI reports
│   ├── email/               # Daily email summary report
│   ├── ltv/                 # Lifetime value cohort analysis
│   ├── bonus/               # Bonus campaign performance
│   └── cohort/              # Player cohort retention reports (14 reports)
│
└── docs/                    # Stakeholder documentation
    └── reports/             # Comprehensive user guides for all reports
```

---

## 🎯 Available Reports

### **KPI Reports** (2)
- `daily_kpis.sql` - Comprehensive daily performance metrics
- `monthly_kpis.sql` - Monthly aggregated KPI metrics

### **Email Reports** (1)
- `daily_email_report.sql` - Executive summary for automated distribution

### **LTV Reports** (1)
- `cohort_ltv_lifetime.sql` - Player lifetime value by registration cohort

### **Bonus Reports** (1)
- `bonus_report_dashboard.sql` - Campaign performance and ROI analysis

### **Cohort Reports** (14)
- Player retention and engagement analysis across various metrics
- Both absolute values and percentage-based views

---

## 🔑 Key Features

### **Calculation Alignment (November 2025)**
All reports use consistent calculation logic:
- **Promo Bet/Win:** `external_transaction_id IS NOT NULL` (CTO-approved)
- **Granted Bonus:** `player_bonus_id IS NOT NULL` (campaign-specific)
- **NGR Formula:** `Cash GGR - Provider Fee (9%) - Payment Fee (8%) - Platform Fee (1%) - Bonus Cost`

### **Currency Handling**
- All monetary calculations support multi-currency with EUR conversion
- NULL-safe formulas: `COALESCE(eur_amount, amount)`

### **Comprehensive Filtering**
- Date ranges, brands, countries, currencies
- Traffic sources (Organic/Affiliate)
- Device/browser combinations
- Test account exclusions

---

## 📖 Documentation

Comprehensive stakeholder-facing documentation is available in the `docs/reports/` directory:

- **Master Index:** `docs/reports/README.md`
- **Individual Report Guides:** Detailed documentation for each report including:
  - Purpose and use cases
  - Metric definitions
  - Filter configurations
  - Interpretation guidelines
  - Common scenarios

---

## 🚀 Quick Start

1. **Access Reports:** Navigate to `sql_reports_adjusted/` directory
2. **Read Documentation:** Start with `docs/reports/README.md`
3. **Choose Report:** Select appropriate report for your analysis needs
4. **Configure Filters:** Use Metabase parameters for filtering
5. **Run & Analyze:** Execute report and interpret results using documentation

---

## 📊 Report Categories

| Category | Purpose | Reports |
|----------|---------|---------|
| **KPI** | Daily/monthly operational metrics | 2 |
| **Email** | Executive summaries | 1 |
| **LTV** | Customer lifetime value | 1 |
| **Bonus** | Campaign performance | 1 |
| **Cohort** | Retention analysis | 14 |

---

## 🔄 Version History

### **v1.0 (November 2025)**
- Aligned promo bet/win logic across all reports
- Standardized NGR calculations (LTV & Email reports)
- Updated granted bonus filtering logic
- Added comprehensive stakeholder documentation
- Repository cleanup and organization

---

## 📞 Support

**For Technical Issues:** Contact Technical Team
**For Business Interpretation:** Contact Analytics Team
**For Metric Definitions:** See documentation in `docs/reports/`
**For Formula Changes:** Requires CTO approval

---

## 📝 Notes

- All reports are production-ready and tested
- Metrics aligned across platform for consistency
- Documentation maintained alongside code
- Filter logic standardized across all reports

---

**Repository:** Bounty_1_test
**Branch:** claude/fix-promo-metrics-add-granted-bonus-011CV4mgEfvPe41T14Cif3Qz
**Status:** Production Ready ✅
