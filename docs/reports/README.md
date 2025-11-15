# SQL Reports Documentation

## 📊 Overview

This documentation provides comprehensive guidance for stakeholders on how to use, configure, and interpret the SQL reports in the `sql_reports_adjusted` directory.

**Last Updated:** November 2025
**Version:** Aligned with Daily/Email/LTV Report Updates

---

## 📑 Report Categories

### 1. **KPI Reports** (2 reports)
Core performance metrics for daily and monthly analysis.

- [Daily KPIs Report](kpi/daily_kpis.md)
- [Monthly KPIs Report](kpi/monthly_kpis.md)

### 2. **Email Reports** (1 report)
Automated daily summary reports for email distribution.

- [Daily Email Report](email/daily_email_report.md)

### 3. **LTV Reports** (1 report)
Lifetime value analysis by player cohorts.

- [Cohort LTV Lifetime Report](ltv/cohort_ltv_lifetime.md)

### 4. **Bonus Reports** (1 report)
Bonus campaign performance and metrics.

- [Bonus Dashboard Report](bonus/bonus_report_dashboard.md)

### 5. **Cohort Reports** (14 reports)
Player behavior analysis across registration cohorts.

- [Cash Bet Amount Cohort](cohort/cash_bet_amount_cohort.md)
- [Cash Bet Amount Cohort (Percentage)](cohort/cash_bet_amounts_cohort_pct.md)
- [Cash Players Cohort](cohort/cash_players_cohort.md)
- [Cash Players Cohort (Percentage)](cohort/cash_players_cohort_pct.md)
- [Deposit Amounts Cohort](cohort/deposit_amounts_cohort.md)
- [Deposit Amounts Cohort (Percentage)](cohort/deposit_amounts_cohort_pct.md)
- [Depositors Cohort](cohort/depositors_cohort.md)
- [Depositors Cohort (Percentage)](cohort/depositors_cohort_pct.md)
- [Existing Depositors Cohort](cohort/existing_depositors_cohort.md)
- [Existing Depositors Cohort (Percentage)](cohort/existing_depositors_cohort_pct.md)
- [New Depositors Cohort](cohort/new_depositors_cohort.md)
- [New Depositors Cohort (Percentage)](cohort/new_depositors_cohort_pct.md)

---

## 🔑 Key Updates (November 2025)

### **Calculation Alignment**
All reports have been aligned to ensure consistent metrics across the platform:

1. **Promo Bet/Win Logic:** Now uses `external_transaction_id IS NOT NULL` (CTO-approved)
2. **Granted Bonus Logic:** Filters by `player_bonus_id IS NOT NULL` for campaign-specific bonuses
3. **NGR Formula:** Standardized across LTV and Email reports:
   - `NGR = Cash GGR - Provider Fee (9%) - Payment Fee (8%) - Platform Fee (1%) - Bonus Cost`

### **Currency Handling**
- All monetary calculations support EUR conversion with NULL safety
- Use `{{currency_filter}}` parameter to select specific currencies

---

## 🎯 Common Filters Across Reports

Most reports support the following filters:

| Filter | Description | Options |
|--------|-------------|---------|
| `{{start_date}}` | Report start date | Date picker |
| `{{end_date}}` | Report end date | Date picker |
| `{{brand}}` | Company/brand filter | Dropdown (from companies table) |
| `{{country}}` | Player country | Dropdown (country names) |
| `{{currency_filter}}` | Currency type | EUR, USD, CAD, etc. |
| `{{traffic_source}}` | Acquisition channel | Organic, Affiliate, All |
| `{{affiliate_id}}` | Specific affiliate ID | Numeric input |
| `{{affiliate_name}}` | Affiliate name | Text input |
| `{{registration_launcher}}` | Device/browser combo | OS / Browser format |
| `{{is_test_account}}` | Include test accounts | Boolean |

---

## 💡 How to Use This Documentation

Each report documentation includes:

1. **Report Purpose:** What the report measures and when to use it
2. **Key Metrics:** Detailed explanation of each metric
3. **Available Filters:** How to configure the report
4. **Calculation Logic:** Business-friendly explanation of formulas
5. **How to Interpret Results:** Guidance on reading the output
6. **Important Notes:** Caveats and considerations

---

## 📞 Support

For questions or clarifications about these reports, please contact:
- **Technical Team:** For calculation logic and data accuracy questions
- **Analytics Team:** For interpretation and business insights
- **CTO:** For strategic metric definition changes

---

## 🔄 Report Maintenance

These reports are maintained in the `sql_reports_adjusted` directory. All updates follow a review process to ensure data consistency and accuracy across the platform.
