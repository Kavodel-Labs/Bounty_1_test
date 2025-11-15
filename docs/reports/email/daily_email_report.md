# Daily Email Report

## 📊 Report Purpose

The Daily Email Report provides a concise, executive-level summary of key business metrics designed for automated email distribution to stakeholders. This report compares yesterday's performance against month-to-date (MTD) figures, provides end-of-month projections, and shows performance versus the previous month.

**Use this report to:**
- Get a quick snapshot of daily business performance
- Track progress toward monthly goals
- Identify trends and anomalies requiring attention
- Monitor key revenue and engagement metrics

---

## 📈 Key Metrics (12 Total)

### **1. Registrations**
- **What it measures:** Total new player accounts created
- **Calculation:** Count of unique players created in the time period
- **Why it matters:** Top-of-funnel indicator of user acquisition success

### **2. FTDs (First-Time Depositors)**
- **What it measures:** Players making their first deposit ever
- **Calculation:** Uses `ROW_NUMBER()` to identify the first deposit per player
- **Why it matters:** Critical conversion metric showing acquisition quality

### **3. Deposits**
- **What it measures:** Total cash deposits (withdrawable balance)
- **Calculation:** Sum of completed deposit transactions with `balance_type='withdrawable'`
- **Why it matters:** Primary revenue inflow indicator

### **4. Paid Withdrawals**
- **What it measures:** Total cash withdrawals processed
- **Calculation:** Sum of completed withdrawal transactions with `balance_type='withdrawable'`
- **Why it matters:** Shows player satisfaction and payout obligations

### **5. Cashflow**
- **What it measures:** Net cash movement (Deposits - Withdrawals)
- **Calculation:** `Deposits - Withdrawals`
- **Why it matters:** Direct indicator of cash position and liquidity

### **6. Cash Turnover**
- **What it measures:** Total real money bets placed
- **Calculation:** Sum of game bet debits with `balance_type='withdrawable'`
- **Why it matters:** Shows player engagement and betting activity

### **7. Total Turnover**
- **What it measures:** All bets including promotional (Cash Bets + Promo Bets)
- **Calculation:** `Cash Turnover + Promo Bets`
- **Why it matters:** Complete picture of betting volume

### **8. Cash GGR (Gross Gaming Revenue)**
- **What it measures:** Profit from real money gaming (Cash Bets - Cash Wins)
- **Calculation:** `Cash Bets - Cash Wins`
- **Why it matters:** Core profitability metric before costs

### **9. Bonus Cost**
- **What it measures:** Bonuses converted to withdrawable cash
- **Calculation:** Sum of `bonus_completion` transactions with `balance_type='withdrawable'`
- **Why it matters:** Direct cost of bonus promotions

### **10. Granted Bonus**
- **What it measures:** Total bonus value issued to players
- **Calculation:** Campaign-based bonuses filtered by `player_bonus_id IS NOT NULL`
- **Includes:** Regular bonuses, free spins, free bets, and bonus completions
- **Why it matters:** Marketing investment in player acquisition/retention

### **11. NGR (Net Gaming Revenue)**
- **What it measures:** True profit after all fees and costs
- **Calculation:** `Cash GGR - Provider Fee (9%) - Payment Fee (8%) - Platform Fee (1%) - Bonus Cost`
- **Why it matters:** Bottom-line profitability metric
- **⚠️ Important:** Aligned with LTV report formula (November 2025 update)

### **12. Hold % (Cash)**
- **What it measures:** Profit margin on cash bets
- **Calculation:** `(Cash GGR / Cash Turnover) × 100`
- **Why it matters:** Efficiency of gaming operations

---

## 🔧 Available Filters

This report has **no configurable filters**. It automatically runs with the following settings:

| Parameter | Value | Description |
|-----------|-------|-------------|
| **Yesterday** | `CURRENT_DATE - 1 day` | Previous day's metrics |
| **MTD** | `Current month start → today` | Month-to-date totals |
| **Estimation** | Linear projection | End-of-month forecast based on MTD pace |
| **Previous Month** | `Last month's full data` | Comparison baseline |
| **Currency** | EUR | All amounts in Euros |

---

## 📊 Report Structure

The report displays data in a **table format** with 5 columns:

| Column | Description |
|--------|-------------|
| **Metric Name** | The metric being measured |
| **Yesterday** | Value for the previous day |
| **MTD** | Month-to-date cumulative value |
| **Estimation** | Projected end-of-month value |
| **Actual (Prev Month)** | Previous month's final value |
| **% vs Prev Month** | Change from previous month (green = positive, red = negative) |

---

## 🧮 Key Calculation Details

### **Promo Bet/Win Logic (Updated Nov 2025)**
- **Old logic:** Used `balance_type='non-withdrawable'`
- **New logic:** Uses `external_transaction_id IS NOT NULL` (CTO-approved)
- **Impact:** More accurate tracking of promotional gaming activity

### **Granted Bonus Logic (Updated Nov 2025)**
- **Filter:** Only counts bonuses with `player_bonus_id IS NOT NULL`
- **Purpose:** Excludes system bonuses, only counts campaign-based bonuses
- **Categories included:**
  - `bonus` - Regular bonus credits
  - `free_spin_bonus` - Free spin rewards
  - `free_bet` / `free_bet_win` / `freebet_win` - Free bet rewards
  - `bonus_completion` - Bonus wagering completions (non-withdrawable)

### **NGR Calculation (Updated Nov 2025)**
```
NGR = Cash GGR
      - Provider Fee (9% of Cash GGR)
      - Payment Fee (8% of Deposits + Withdrawals)
      - Platform Fee (1% of Cash GGR)
      - Bonus Cost
```

**Important:** This formula is **aligned with the LTV report** for consistency.

### **Estimation Method**
Projections use **linear extrapolation**:
```
Estimation = (MTD Value / Days Elapsed MTD) × Total Days in Month
```

Example: If 10 FTDs in 5 days of a 30-day month:
```
Estimation = (10 / 5) × 30 = 60 FTDs
```

---

## 💡 How to Interpret Results

### **Green vs Red Indicators**
- **Green (+X%):** Performance improved vs previous month → Good
- **Red (-X%):** Performance declined vs previous month → Requires attention

### **Yesterday vs MTD Patterns**
- **High yesterday, low MTD:** Recent surge, monitor if sustainable
- **Low yesterday, high MTD:** One-off dip, check for issues
- **Both trending up:** Strong performance period
- **Both trending down:** Systematic issue, investigate causes

### **Estimation Accuracy**
- **Early in month (Days 1-10):** Estimates less reliable, high variance
- **Mid-month (Days 11-20):** Estimates stabilize, moderate confidence
- **Late in month (Days 21+):** Estimates highly accurate, low variance

### **Key Ratios to Monitor**
1. **FTD/Registration %:** Conversion rate (healthy: 10-30%)
2. **Cash GGR/Deposits:** Revenue efficiency (healthy: 3-10%)
3. **Bonus Cost/Cash GGR:** Marketing efficiency (healthy: 10-25%)
4. **Hold %:** Gaming margin (healthy: 3-8%)

---

## ⚠️ Important Notes

### **Data Freshness**
- Report runs on **previous day's data** (T-1)
- Updates automatically each morning
- Does not include today's incomplete data

### **Currency**
- All amounts shown in **EUR (€)**
- Multi-currency transactions are converted using `eur_amount` field
- NULL amounts safely handled with `COALESCE(eur_amount, amount)`

### **Alignment with Other Reports**
- **LTV Report:** NGR calculations now match exactly
- **Daily KPIs:** Metrics calculated using identical logic
- **Bonus Dashboard:** Granted Bonus uses same filtering

### **Excluded from Output**
The following metrics are **calculated internally** but not displayed:
- Cash GGR Casino (removed November 2025)
- GGR Casino (removed November 2025)
- Turnover Casino (removed November 2025)
- Platform Fee (used in NGR, not shown separately)
- Provider Fee (used in NGR, not shown separately)
- Payment Fee (used in NGR, not shown separately)

---

## 🎯 Common Use Cases

### **Morning Performance Review**
Check yesterday's key metrics against MTD pace:
1. Are FTDs on track for monthly target?
2. Is Cash GGR maintaining healthy margins?
3. Are bonus costs within acceptable ranges?

### **Monthly Forecasting**
Use estimations to predict month-end performance:
1. Compare estimation to monthly budget
2. Identify gaps requiring action
3. Adjust marketing spend if needed

### **Historical Comparison**
Compare against previous month:
1. Seasonal trends (month-over-month)
2. Campaign effectiveness (before/after)
3. Market changes impact

### **Anomaly Detection**
Watch for unusual patterns:
1. Yesterday significantly off from MTD average
2. Sudden changes in Hold % or conversion rates
3. Cashflow turning negative unexpectedly

---

## 📞 Questions & Support

**For metric definitions:** Refer to this documentation or contact Analytics Team

**For data accuracy issues:** Contact Technical Team with specific date and metric

**For business interpretation:** Contact Finance or Operations Team

**For formula changes:** All updates require CTO approval

---

**Last Updated:** November 2025
**Version:** V10 (NGR Aligned with LTV)
**Report Location:** `sql_reports_adjusted/email/daily_email_report.sql`
