# 📍 START HERE - Simple Guide

## Where Are My SQL Reports?

All your SQL reports are in **one folder**: `sql_reports_adjusted/`

### 🗂️ How to Find Your Reports

```
sql_reports_adjusted/
│
├── kpi/
│   ├── daily_kpis.sql          ← Daily performance report
│   └── monthly_kpis.sql         ← Monthly performance report
│
├── email/
│   └── daily_email_report.sql   ← Executive daily summary (the main one!)
│
├── ltv/
│   └── cohort_ltv_lifetime.sql  ← Customer lifetime value report
│
├── bonus/
│   └── bonus_report_dashboard.sql ← Bonus campaign tracking
│
└── cohort/
    ├── depositors_cohort.sql           ← Track depositors over time
    ├── depositors_cohort_pct.sql       ← Same as above (percentage)
    ├── new_depositors_cohort.sql       ← New depositors
    ├── new_depositors_cohort_pct.sql   ← New depositors (percentage)
    ├── existing_depositors_cohort.sql  ← Returning depositors
    ├── existing_depositors_cohort_pct.sql ← Returning depositors (percentage)
    ├── deposit_amounts_cohort.sql      ← Deposit money amounts
    ├── deposit_amounts_cohort_pct.sql  ← Deposit amounts (percentage)
    ├── cash_players_cohort.sql         ← Players using real money
    ├── cash_players_cohort_pct.sql     ← Cash players (percentage)
    ├── cash_bet_amount_cohort.sql      ← Betting amounts
    └── cash_bet_amounts_cohort_pct.sql ← Betting amounts (percentage)
```

## 📖 How to Understand Each Report?

All explanations are in the **`docs/reports/`** folder.

### Quick Links to Guides:

1. **Daily KPI Report** → Read: `docs/reports/kpi/daily_kpis.md`
2. **Monthly KPI Report** → Read: `docs/reports/kpi/monthly_kpis.md`
3. **Daily Email Report** → Read: `docs/reports/email/daily_email_report.md`
4. **LTV Report** → Read: `docs/reports/ltv/cohort_ltv_lifetime.md`
5. **Bonus Report** → Read: `docs/reports/bonus/bonus_report_dashboard.md`
6. **All Cohort Reports** → Read: `docs/reports/cohort/README.md`

## 🎯 What You Need to Know

### The Most Important Report
**`sql_reports_adjusted/email/daily_email_report.sql`**
- This is your executive summary
- Shows yesterday's performance
- Shows month-to-date performance
- Predicts end-of-month numbers

### What Changed?
All the calculations are now **aligned** - meaning:
- ✅ Promo bets and wins calculate the same way everywhere
- ✅ Granted bonuses are tracked properly
- ✅ Net Gaming Revenue (NGR) is calculated consistently

## 📝 What Each File Does

### SQL Files (.sql)
These are the actual reports you run in Metabase.
- Copy the SQL code
- Paste it into Metabase
- Run it to see your data

### Documentation Files (.md)
These explain what each report shows you.
- Open them to read instructions
- See what each column means
- Understand how to use the report

## 🚀 How to Use a Report

### Step 1: Find the SQL file
Example: `sql_reports_adjusted/email/daily_email_report.sql`

### Step 2: Read the guide (optional)
Example: `docs/reports/email/daily_email_report.md`

### Step 3: Copy and use
- Open the .sql file
- Copy all the code
- Paste into Metabase
- Run the report

## 📊 Main Reports You'll Use Daily

| Report Name | File Location | What It Shows |
|-------------|---------------|---------------|
| Daily Summary | `sql_reports_adjusted/email/daily_email_report.sql` | Everything in one place |
| Daily KPIs | `sql_reports_adjusted/kpi/daily_kpis.sql` | Daily metrics breakdown |
| Monthly KPIs | `sql_reports_adjusted/kpi/monthly_kpis.sql` | Monthly metrics breakdown |
| Customer Value | `sql_reports_adjusted/ltv/cohort_ltv_lifetime.sql` | How valuable customers are |
| Bonus Performance | `sql_reports_adjusted/bonus/bonus_report_dashboard.sql` | How bonuses perform |

## ❓ Need Help?

### "Where is the report that shows...?"

- **Yesterday's deposits and withdrawals?** → `daily_email_report.sql`
- **This month's revenue?** → `daily_email_report.sql` or `daily_kpis.sql`
- **How customers behave over time?** → Any file in `cohort/` folder
- **Bonus campaign results?** → `bonus_report_dashboard.sql`
- **Customer lifetime value?** → `cohort_ltv_lifetime.sql`

### "How do I know what a column means?"

Look at the documentation file with the same name:
- Report: `daily_kpis.sql`
- Guide: `docs/reports/kpi/daily_kpis.md`

## 📁 Folder Structure (Simplified)

```
Your Repository
│
├── START_HERE.md  ← You are here!
├── README.md      ← Technical overview
├── CHANGELOG.md   ← What changed and when
│
├── sql_reports_adjusted/  ← ALL YOUR SQL REPORTS HERE
│   ├── kpi/               ← Performance reports (2 files)
│   ├── email/             ← Daily summary (1 file)
│   ├── ltv/               ← Customer value (1 file)
│   ├── bonus/             ← Bonus tracking (1 file)
│   └── cohort/            ← Customer behavior over time (12 files)
│
└── docs/
    └── reports/           ← GUIDES EXPLAINING EACH REPORT
        ├── kpi/
        ├── email/
        ├── ltv/
        ├── bonus/
        └── cohort/
```

## 💡 Quick Tips

1. **Start with** `daily_email_report.sql` - it has everything
2. **All calculations are now consistent** across all reports
3. **Cohort reports** show trends over weeks (W0, W1, W2, etc.)
4. **Files ending in _pct** show percentages instead of numbers

## 🔍 Can't Find Something?

Everything you need is in these 2 folders:
1. **`sql_reports_adjusted/`** - The actual SQL reports
2. **`docs/reports/`** - The guides explaining them

That's it! Nothing else matters for your day-to-day work.
