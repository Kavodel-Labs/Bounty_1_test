# Cohort Reports Documentation

## 📊 Overview

Cohort reports analyze player behavior by grouping players based on their registration month and tracking their activity across subsequent months. These 14 reports provide detailed retention and engagement analysis across different metrics and display formats.

---

## 📑 Report Types

### **Absolute Value Reports (7 reports)**
Show actual values (counts, amounts) for each cohort-month combination.

### **Percentage Reports (7 reports)**
Show percentages of the original cohort still active in each month.

---

## 🗂️ Available Cohort Reports

| # | Report Name | Type | What It Measures |
|---|-------------|------|------------------|
| 1 | [Cash Bet Amount Cohort](cash_bet_amount_cohort.md) | Absolute | Cash bet amounts by cohort month |
| 2 | [Cash Bet Amount Cohort (%)](cash_bet_amounts_cohort_pct.md) | Percentage | Cash bet amounts as % of M0 |
| 3 | [Cash Players Cohort](cash_players_cohort.md) | Absolute | Number of betting players by cohort month |
| 4 | [Cash Players Cohort (%)](cash_players_cohort_pct.md) | Percentage | Active players as % of cohort size |
| 5 | [Deposit Amounts Cohort](deposit_amounts_cohort.md) | Absolute | Deposit amounts by cohort month |
| 6 | [Deposit Amounts Cohort (%)](deposit_amounts_cohort_pct.md) | Percentage | Deposits as % of M0 |
| 7 | [Depositors Cohort](depositors_cohort.md) | Absolute | Number of depositing players by cohort month |
| 8 | [Depositors Cohort (%)](depositors_cohort_pct.md) | Percentage | Depositors as % of cohort size |
| 9 | [Existing Depositors Cohort](existing_depositors_cohort.md) | Absolute | Repeat depositors (non-FTD) by cohort month |
| 10 | [Existing Depositors Cohort (%)](existing_depositors_cohort_pct.md) | Percentage | Repeat depositors as % of cohort |
| 11 | [New Depositors Cohort](new_depositors_cohort.md) | Absolute | First-time depositors (FTD) by cohort month |
| 12 | [New Depositors Cohort (%)](new_depositors_cohort_pct.md) | Percentage | FTDs as % of cohort size |

---

## 🎯 Understanding Cohort Analysis

### **What is a Cohort?**
A **cohort** is a group of players who registered in the same month.

**Example:**
- **January 2024 Cohort:** All players who registered in January 2024
- **February 2024 Cohort:** All players who registered in February 2024

### **Cohort Months (M0, M1, M2, ...)**
- **M0:** Registration month (when cohort was created)
- **M1:** One month after registration
- **M2:** Two months after registration
- **M3:** Three months after registration
- And so on...

### **Example Timeline**
```
Cohort: January 2024 (Player registered Jan 15, 2024)

M0 (Jan 2024): Registration month - Player activity in January 2024
M1 (Feb 2024): First month after - Player activity in February 2024
M2 (Mar 2024): Second month after - Player activity in March 2024
M3 (Apr 2024): Third month after - Player activity in April 2024
...
```

---

## 📊 Report Structure

All cohort reports follow the same structure:

### **Table Format**
```
Cohort Month  | M0    | M1    | M2    | M3    | M4    | ...
--------------+-------+-------+-------+-------+-------+----
Jan 2024     | 1,250 | 450   | 320   | 280   | 240   | ...
Feb 2024     | 1,380 | 520   | 380   | 310   |   -   | ...
Mar 2024     | 1,450 | 580   | 420   |   -   |   -   | ...
Apr 2024     | 1,520 | 610   |   -   |   -   |   -   | ...
```

- **Rows:** Registration cohorts (months)
- **Columns:** Months since registration (M0, M1, M2, ...)
- **Values:** Depend on report type (count, amount, or percentage)
- **Empty cells (-):** Future months that haven't occurred yet

### **Reading the Table**

**Horizontal (Row) Reading:** Track a single cohort over time
```
Jan 2024 Cohort:
M0: 1,250 players → M1: 450 players → M2: 320 players → M3: 280 players

Interpretation: Shows retention decline over time for Jan 2024 cohort
```

**Vertical (Column) Reading:** Compare cohorts at same stage
```
M1 (First Month):
Jan 2024: 450 players
Feb 2024: 520 players
Mar 2024: 580 players

Interpretation: Recent cohorts showing better M1 retention
```

---

## 🔧 Common Filters

All cohort reports support these filters:

| Filter | Parameter | Default | Description |
|--------|-----------|---------|-------------|
| **Start Date** | `{{start_date}}` | 24 months ago | First cohort month |
| **End Date** | `{{end_date}}` | Current month | Last cohort month |
| **Brand** | `{{brand}}` | All | Company/brand filter |
| **Country** | `{{country}}` | All | Player country |
| **Currency** | `{{currency_filter}}` | EUR | Transaction currency |
| **Traffic Source** | `{{traffic_source}}` | All | Organic/Affiliate |
| **Affiliate ID** | `{{affiliate_id}}` | All | Specific affiliate |
| **Affiliate Name** | `{{affiliate_name}}` | All | Affiliate name |
| **Device/Browser** | `{{registration_launcher}}` | All | OS / Browser combo |
| **Test Accounts** | `{{is_test_account}}` | Excluded | Include test players |

---

## 💡 How to Use Cohort Reports

### **1. Retention Analysis**
**Goal:** Understand how well you retain players over time

**Method:**
1. Choose **Depositors Cohort (%)** or **Cash Players Cohort (%)**
2. Look at M1, M2, M3 columns
3. Identify drop-off patterns

**Example:**
```
M0: 100%  → M1: 35% → M2: 22% → M3: 18% → M4: 15%

Interpretation:
- 65% churn after M0 (high, investigate onboarding)
- M1→M2: 37% drop (moderate, normal)
- M2→M3: 18% drop (stabilizing)
- M3→M4: 17% drop (stable retention)
```

### **2. Cohort Quality Comparison**
**Goal:** Determine which cohorts perform better

**Method:**
1. Choose **Cash Bet Amount Cohort** or **Deposit Amounts Cohort**
2. Compare M0, M1, M2 values across different cohorts
3. Identify high-value cohorts

**Example:**
```
         M0      M1      M2
Jan 2024: €50K → €15K → €10K
Feb 2024: €65K → €22K → €16K  ← Better performing cohort
Mar 2024: €55K → €18K → €12K

Interpretation: February cohort shows 25-30% better performance
```

### **3. Seasonality Detection**
**Goal:** Identify seasonal patterns

**Method:**
1. Run report for 2+ years
2. Compare same months across years
3. Identify recurring patterns

**Example:**
```
         M0 Depositors
Jan 2023: 1,250
Jan 2024: 1,450  (+16% YoY)
Jan 2025: 1,620  (+12% YoY)

Interpretation: January consistently strong, plan Q1 marketing
```

### **4. Marketing Campaign Impact**
**Goal:** Measure campaign effectiveness

**Method:**
1. Note campaign launch month
2. Compare that cohort to previous months
3. Track long-term retention vs short-term spike

**Example:**
```
Campaign launched: March 2024

         M0     M1    M2
Feb 2024: 1,200 → 400 → 280
Mar 2024: 1,800 → 650 → 520  ← Campaign month
Apr 2024: 1,300 → 450 → 310

Interpretation:
- M0: +50% spike (campaign worked for acquisition)
- M1: +62% retention (quality players)
- M2: +85% retention (sustainable improvement)
```

### **5. Lifetime Value Projection**
**Goal:** Predict cohort LTV

**Method:**
1. Use **Deposit Amounts Cohort** or **Cash Bet Amount Cohort**
2. Sum M0 + M1 + M2 + ... + M12 for mature cohorts
3. Apply pattern to recent cohorts

**Example:**
```
Mature Cohort (Jan 2023):
M0: €80K + M1: €25K + M2: €18K + ... + M12: €5K = €200K total

Recent Cohort (Mar 2025):
M0: €85K + M1: €28K = €113K so far
Projected: €113K + (similar decay pattern) ≈ €215K total LTV
```

---

## 📈 Absolute vs Percentage Reports

### **When to Use Absolute Reports**
- **Budget planning:** Need actual amounts
- **Revenue forecasting:** Need currency values
- **Capacity planning:** Need player counts
- **Comparative volume:** Compare absolute size

### **When to Use Percentage Reports**
- **Retention analysis:** Track % of cohort remaining
- **Engagement rates:** Normalized comparison
- **Quality comparison:** Independent of cohort size
- **Efficiency metrics:** Performance per capita

### **Example Comparison**

**Absolute (Cash Players Cohort):**
```
         M0     M1    M2
Jan 2024: 1,000 → 300 → 200
Feb 2024: 1,500 → 600 → 450

Question: Which cohort better?
Answer: Unclear - Feb has more players, but larger starting size
```

**Percentage (Cash Players Cohort %):**
```
         M0     M1     M2
Jan 2024: 100% → 30%  → 20%
Feb 2024: 100% → 40%  → 30%

Question: Which cohort better?
Answer: Clear - Feb retains 50% more players (40% vs 30% at M1)
```

---

## 🎯 Key Metrics by Report Type

### **Player Count Reports**
- **Depositors Cohort:** Total unique depositors
- **Cash Players Cohort:** Total unique betting players
- **New Depositors Cohort:** FTDs only
- **Existing Depositors Cohort:** Repeat depositors only

### **Amount Reports**
- **Deposit Amounts Cohort:** Sum of deposit values
- **Cash Bet Amount Cohort:** Sum of real money bets

### **Percentage Reports**
- All percentage reports: `(Mx Value / M0 Value) × 100`
- M0 always = 100% (baseline)
- Higher % = better retention/engagement

---

## ⚠️ Important Notes

### **Cohort Maturity**
- **Young cohorts (<3 months):** Incomplete data, trends emerging
- **Mature cohorts (6-12 months):** Reliable patterns
- **Old cohorts (12+ months):** Complete lifetime view

**Never compare M6 of a young cohort to M6 of a mature cohort directly.**

### **Empty Cells**
- Represent future months that haven't occurred
- Not zero, just no data yet
- Will populate as time passes

### **Cohort Assignment**
- Players assigned to cohort by **registration month**
- All their lifetime activity tracked
- Cannot be in multiple cohorts

### **Currency Handling**
- All amounts use EUR conversion
- Formula: `COALESCE(eur_amount, amount)`
- Multi-currency safe

### **FTD vs Depositor**
- **FTD (First-Time Depositor):** First deposit ever, only counted once
- **Depositor:** Any deposit, can be counted multiple times
- **Existing Depositor:** Depositor who is NOT making their first deposit

---

## 📊 Best Practices

### **1. Start with Percentage Reports**
Easier to spot patterns and compare cohorts.

### **2. Focus on M1-M3**
Most critical months for retention and engagement.

### **3. Compare Similar Cohorts**
Month-to-month or season-to-season.

### **4. Track Trends, Not Absolutes**
Look for improving or declining patterns.

### **5. Combine with Other Reports**
- Use LTV Report for profitability
- Use Daily KPIs for operational detail
- Use Bonus Report for campaign effectiveness

---

## 📞 Questions & Support

**For cohort methodology:** Contact Analytics Team

**For retention benchmarks:** Contact Operations Team

**For data accuracy:** Contact Technical Team with cohort month and metric

**For strategic insights:** Contact Finance Team with cohort analysis

---

**Last Updated:** November 2025
**Report Location:** `sql_reports_adjusted/cohort/`
**Total Reports:** 14 (7 absolute + 7 percentage)
