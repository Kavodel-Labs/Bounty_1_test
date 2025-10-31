# BTB Analytics - Quick Reference Card

**Version:** 1.0  |  **Date:** October 31, 2025

---

## 🎯 15 Available Reports

| # | Report Name | What It Shows | Update Frequency |
|---|-------------|---------------|------------------|
| 1 | Daily KPIs | Day-by-day performance | Hourly |
| 2 | Monthly KPIs | Month-by-month trends | Daily |
| 3 | Depositors Cohort | Depositor retention (count) | Daily |
| 4 | Depositors Cohort (%) | Depositor retention (%) | Daily |
| 5 | Deposit Amounts Cohort | Deposit money over time | Daily |
| 6 | Deposit Amounts Cohort (%) | Deposit trends vs Month 0 | Daily |
| 7 | Cash Players Cohort | Cash player retention (count) | Daily |
| 8 | Cash Players Cohort (%) | Cash player retention (%) | Daily |
| 9 | Cash Bet Amounts Cohort | Betting amounts over time | Daily |
| 10 | Cash Bet Amounts Cohort (%) | Betting trends vs Month 0 | Daily |
| 11 | New Depositors Cohort | First-time depositors by reg month | Daily |
| 12 | New Depositors Cohort (%) | FTD conversion by reg month | Daily |
| 13 | Existing Depositors Cohort | Repeat depositor counts | Daily |
| 14 | Existing Depositors Cohort (%) | Repeat deposit rates | Daily |
| 15 | Cohort LTV Lifetime | Complete profitability view | Daily |

---

## 🔍 Filters At-A-Glance

| Filter | Type | Example | Use For |
|--------|------|---------|---------|
| **Brand** | Dropdown | "Casino Royal" | Brand comparison |
| **Country** | Dropdown | Romania, Germany, France | Regional analysis |
| **Start/End Date** | Date Picker | 2025-01-01 to 2025-03-31 | Time period selection |
| **Traffic Source** | Dropdown | Organic / Affiliate | Channel performance |
| **Affiliate ID** | Dropdown | #12345 | Specific affiliate |
| **Affiliate Name** | Search | "PartnerCasino" | Affiliate by name |
| **Device** | Dropdown | "iOS / Safari" | Device targeting |
| **Currency** | Text | EUR, USD, RON | Currency filtering |
| **Test Accounts** | Toggle | Exclude (recommended) | Clean data |

---

## 📊 Key Metrics Formulas

### Acquisition
```
Conversion Rate = (FTDs ÷ Registrations) × 100
D0 FTD Rate = (D0 FTDs ÷ New FTDs) × 100
```

### Financial
```
CashFlow = Deposits - Withdrawals
GGR = (Cash Bet + Promo Bet) - (Cash Win + Promo Win)
Cash GGR = Cash Bet - Cash Win
Revenue = GGR - Bonus Cost
```

### Efficiency
```
Bonus Ratio = (Bonus Cost ÷ GGR) × 100
Payout % = (Cash Win ÷ Cash Bet) × 100
LTV = Total Deposits ÷ FTD Count
```

### Retention
```
Retention % = (Active in Month N ÷ Active in Month 0) × 100
```

---

## 📈 Benchmark Ranges

| Metric | Good | Average | Needs Attention |
|--------|------|---------|-----------------|
| Conversion Rate | 10-15% | 5-10% | < 5% |
| D0 FTD Rate | 70-85% | 60-70% | < 60% |
| Month 1 Retention | 50-60% | 35-50% | < 35% |
| Month 3 Retention | 30-40% | 20-30% | < 20% |
| Bonus Ratio (GGR) | 10-20% | 20-30% | > 30% |
| Payout % | 92-96% | 88-92% | > 96% or < 88% |

---

## 🎨 Quick Troubleshooting

### Numbers Too High?
- ❌ Test accounts included?
- ❌ Wrong date range?
- ❌ No currency filter?
- ❌ Missing brand filter?

### Numbers Too Low?
- ❌ Too many filters active?
- ❌ Date range too narrow?
- ❌ Device filter too specific?
- ❌ Wrong country selected?

### Numbers Don't Match?
- ❌ Different date ranges?
- ❌ Different filters?
- ❌ Daily vs Monthly view?
- ❌ Cached vs fresh data?

---

## 🗓️ Default Date Ranges

| Report Type | Default Period |
|-------------|----------------|
| Daily KPIs | Last 31 days |
| Monthly KPIs | Last 12 months |
| All Cohorts | Last 12 months of cohorts |

---

## 💰 Currency Rules

**All reports show EUR** (converted automatically)

**Conversion Priority:**
1. Transaction metadata → 'currency'
2. Transaction cash_currency
3. Player wallet_currency
4. Company default currency

---

## 📋 Common Filter Combos

### Executive Dashboard
```
Brand: [All]
Country: [All]
Date: Last 12 months
Test Accounts: Exclude
Currency: [All → EUR]
```

### Regional Deep Dive
```
Brand: [All]
Country: Romania
Date: Last 6 months
Test Accounts: Exclude
Currency: [All → EUR]
```

### Affiliate Performance
```
Brand: [All]
Country: [All]
Traffic Source: Affiliate
Affiliate ID: #12345
Date: Last 3 months
Test Accounts: Exclude
```

### Mobile vs Desktop
```
Brand: [All]
Device: "iOS / Safari" vs "Windows / Chrome"
Date: Last 30 days
Test Accounts: Exclude
```

---

## 📱 Report Selection Guide

**Want to see...**

→ **Today's performance?**
Use: Daily KPIs (last 7-30 days)

→ **This month's trends?**
Use: Monthly KPIs (last 6-12 months)

→ **Player retention?**
Use: Depositors Cohort (%)

→ **Revenue by cohort?**
Use: Cohort LTV Lifetime

→ **Are bonuses worth it?**
Use: Daily/Monthly KPIs → Check Bonus Ratio

→ **Which affiliates perform best?**
Use: Daily KPIs → Filter by Affiliate ID

→ **Mobile vs Desktop performance?**
Use: Daily KPIs → Filter by Device

→ **Long-term player value?**
Use: Deposit Amounts Cohort + LTV Report

---

## 🔢 Transaction Categories

| Category | Type | Balance Type | Means |
|----------|------|--------------|-------|
| `deposit` | credit | withdrawable | Money in |
| `withdrawal` | debit | withdrawable | Money out |
| `game_bet` | debit | withdrawable | Real money bet |
| `game_bet` | credit | withdrawable | Real money win |
| `bonus` | debit | non-withdrawable | Bonus bet |
| `bonus` | credit | non-withdrawable | Bonus win |
| `bonus_completion` | credit | withdrawable | Bonus → Cash |

---

## ⚡ Performance Tips

**Slow Loading?**
- Narrow date range (try last 30 days instead of 12 months)
- Remove unused filters
- Check if report cached (wait 30 seconds, try again)

**Want Faster Reports?**
- Use Monthly instead of Daily for long periods
- Apply filters BEFORE opening report
- Let report cache (don't refresh constantly)

---

## 🎯 KPI Watching Schedule

**Daily (Every Morning):**
- Daily KPIs → Last 7 days
- Check: REG, FTDs, Revenue
- Alert if: 20% drop vs last week

**Weekly (Monday):**
- Daily KPIs → Last 30 days
- Monthly KPIs → Current month progress
- Check: Trends, Conversion Rate
- Alert if: Conversion < 5%

**Monthly (1st of Month):**
- Monthly KPIs → Last 12 months
- Cohort LTV → All cohorts
- Deposit/Cash Players Cohorts → Retention trends
- Check: MoM growth, Retention curves
- Alert if: Month 1 retention < 40%

**Quarterly (Start of Quarter):**
- All cohort reports
- Deep dive: Affiliate performance
- Regional analysis
- Strategic planning metrics

---

## 📊 Cohort Reading Guide

**Cohort Table Format:**
```
First Deposit Month | Month 0 | Month 1 | Month 2 | ... | Month 12
--------------------|---------|---------|---------|-----|----------
January 2025        |   100   |   45    |   32    | ... |   15
February 2025       |   120   |   50    |   38    | ... |   [N/A]
```

**Understanding:**
- **Rows:** Each cohort (month players first deposited)
- **Columns:** Time since first deposit
- **Month 0:** Always 100% in percentage reports
- **[N/A] / Blank:** Not enough time has passed yet

**Red Flags:**
- Month 1 < 40% → Poor onboarding
- Continuous steep decline → Engagement issues
- Month 3 < 25% → Experience problems

---

## 💡 Pro Tips

1. **Always exclude test accounts** for business reports
2. **Compare similar time periods** (Mon-to-Mon, not partial months)
3. **Use percentage cohorts** for comparing different sized groups
4. **Filter by traffic source** to see Organic vs Affiliate separately
5. **Check currency** is set correctly for financial reports
6. **Allow cache to work** - don't refresh too frequently
7. **Start broad, then filter** - see overall picture first
8. **Save common filter combinations** - document your standards
9. **Export before meetings** - don't rely on live data during presentations
10. **Verify with 2 metrics** - if FTDs spike, check Conversion Rate too

---

## 📞 Quick Contacts

| Issue | Contact |
|-------|---------|
| Data looks wrong | Analytics Team |
| Dashboard not loading | IT Support |
| Need new metric | Product Team |
| Filter not working | Analytics Team |
| Training needed | Analytics Team |

---

## 🔗 Related Documents

- **STAKEHOLDER_GUIDE.md** - Complete detailed guide
- **CORRECTIONS_SUMMARY.md** - Technical changes log
- **ACTION_PLAN.md** - Future improvements roadmap

---

*Print this for your desk or bookmark for quick reference!*

*Last Updated: October 31, 2025*
