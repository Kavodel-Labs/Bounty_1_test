# Cohort LTV Lifetime Report

## 📊 Report Purpose

The Cohort LTV Lifetime Report analyzes player lifetime value (LTV) by grouping players into monthly registration cohorts. This report tracks all-time performance of each cohort from registration through their entire lifetime, providing critical insights for player acquisition ROI and long-term profitability analysis.

**Use this report to:**
- Calculate customer acquisition cost (CAC) payback periods
- Evaluate long-term profitability of player cohorts
- Compare performance across different registration periods
- Optimize marketing spend based on historical LTV data
- Identify seasonal trends in player value

---

## 📈 Key Metrics (16 Total)

### **Player Acquisition Metrics**

#### **1. REG (Registrations)**
- **What it measures:** Total players registered in the cohort month
- **Calculation:** Count of distinct players created in registration month
- **Why it matters:** Cohort size baseline for all percentage calculations

#### **2. FTD (First-Time Depositors)**
- **What it measures:** Players who made their first deposit (ever)
- **Calculation:** Uses `ROW_NUMBER()` to identify first deposit per player
- **Why it matters:** Shows conversion quality of each cohort

#### **3. Conversion Rate**
- **What it measures:** Percentage of registrations that became FTDs
- **Calculation:** `(FTD / REG) × 100`
- **Why it matters:** Key indicator of acquisition channel quality
- **Healthy range:** 10-30%

### **Financial Flow Metrics**

#### **4. Deposit**
- **What it measures:** Total lifetime deposits from cohort players
- **Calculation:** Sum of all completed deposit transactions (withdrawable balance)
- **Why it matters:** Total cash inflow from cohort

#### **5. WD (Withdrawals)**
- **What it measures:** Total lifetime withdrawals to cohort players
- **Calculation:** Sum of all completed withdrawal transactions (withdrawable balance)
- **Why it matters:** Total cash outflow to cohort

### **Gaming Activity Metrics**

#### **6. GGR (Gross Gaming Revenue)**
- **What it measures:** Total gaming profit including all bet types
- **Calculation:** `(Cash Bets + Promo Bets) - (Cash Wins + Promo Wins)`
- **Why it matters:** Complete picture of gaming revenue from cohort

#### **7. Cash GGR**
- **What it measures:** Gaming profit from real money bets only
- **Calculation:** `Cash Bets - Cash Wins`
- **Why it matters:** Core revenue metric excluding promotions

### **Cost & Fee Metrics**

#### **8. Provider Fee**
- **What it measures:** Cost of gaming providers (game developers)
- **Calculation:** `Cash GGR × 9%`
- **Why it matters:** Largest operational cost component
- **⚠️ Fixed rate:** 9% of Cash GGR

#### **9. Payment Fee**
- **What it measures:** Transaction processing costs
- **Calculation:** `(Deposits + Withdrawals) × 8%`
- **Why it matters:** Cost of payment gateway services
- **⚠️ Fixed rate:** 8% of total transaction volume

#### **10. Platform Fee**
- **What it measures:** Internal platform costs
- **Calculation:** `Cash GGR × 1%`
- **Why it matters:** Platform maintenance and operations
- **⚠️ Fixed rate:** 1% of Cash GGR

#### **11. Bonus Cost**
- **What it measures:** Bonuses converted to real cash
- **Calculation:** Sum of `bonus_completion` transactions with `balance_type='withdrawable'`
- **Why it matters:** Direct marketing cost of promotions

### **Profitability Metrics**

#### **12. NGR (Net Gaming Revenue)**
- **What it measures:** True profit after all costs and fees
- **Calculation:** `Cash GGR - Provider Fee (9%) - Payment Fee (8%) - Platform Fee (1%) - Bonus Cost`
- **Why it matters:** Bottom-line profitability per cohort
- **⚠️ Critical:** Primary metric for LTV calculation

#### **13. LTV (Lifetime Value)**
- **What it measures:** Average net profit per FTD player
- **Calculation:** `NGR / FTD`
- **Why it matters:** Determines maximum acceptable CAC
- **Business Rule:** `CAC < LTV` for profitable acquisition

---

## 🔧 Available Filters

| Filter | Parameter | Options | Default | Description |
|--------|-----------|---------|---------|-------------|
| **Date Range** | `{{start_date}}` | Date picker | 24 months ago | Cohort start month |
| | `{{end_date}}` | Date picker | Current date | Cohort end month |
| **Brand** | `{{brand}}` | Dropdown | All | Company/brand filter |
| **Country** | `{{country}}` | Dropdown | All | Player country (full names) |
| **Currency** | `{{currency_filter}}` | Dropdown | EUR | Transaction currency |
| **Traffic Source** | `{{traffic_source}}` | Organic/Affiliate/All | All | Acquisition channel |
| **Affiliate ID** | `{{affiliate_id}}` | Numeric input | All | Specific affiliate |
| **Affiliate Name** | `{{affiliate_name}}` | Text input | All | Affiliate name filter |
| **Device/Browser** | `{{registration_launcher}}` | Dropdown | All | OS / Browser combination |
| **Test Accounts** | `{{is_test_account}}` | Boolean | Excluded | Include test players |

---

## 📊 Report Structure

### **Output Format**

The report displays cohorts in **descending chronological order**:

```
TOTAL           ← Aggregated across all cohorts
November 2025   ← Most recent cohort
October 2025
September 2025
...
January 2023    ← Oldest cohort
```

### **Column Layout**

| Column | Type | Description |
|--------|------|-------------|
| **Month Year** | Text | Cohort registration month |
| **REG** | Integer | Total registrations |
| **FTD** | Integer | First-time depositors |
| **Conversion Rate** | Percentage | FTD/REG ratio |
| **Deposit** | Currency (€) | Lifetime deposits |
| **WD** | Currency (€) | Lifetime withdrawals |
| **GGR** | Currency (€) | Gross gaming revenue |
| **Cash GGR** | Currency (€) | Cash-only gaming revenue |
| **Provider Fee** | Currency (€) | 9% of Cash GGR |
| **Payment Fee** | Currency (€) | 8% of (Deposits + WD) |
| **Platform Fee** | Currency (€) | 1% of Cash GGR |
| **Bonus Cost** | Currency (€) | Converted bonuses |
| **NGR** | Currency (€) | Net gaming revenue |
| **LTV** | Currency (€) | NGR / FTD |

---

## 🧮 Key Calculation Details

### **Cohort Assignment**
- Players assigned to cohort based on **registration month**
- All lifetime activity tracked regardless of when it occurred
- Example: Player registered Jan 2024 → All their activity counts toward Jan 2024 cohort

### **Promo Bet/Win Logic (Updated Nov 2025)**
- **Old logic:** Used `balance_type='non-withdrawable'`
- **New logic:** Uses `external_transaction_id IS NOT NULL` (CTO-approved)
- **Impact:** More accurate tracking, aligned with Daily/Email reports
- **Why changed:** Better identifies true promotional activity

### **NGR Formula Breakdown**

```
Starting Point: Cash GGR = €1,000

Step 1: Provider Fee = €1,000 × 9% = €90
Step 2: Platform Fee = €1,000 × 1% = €10
Step 3: Payment Fee = (€5,000 deposits + €3,000 WD) × 8% = €640
Step 4: Bonus Cost = €150 (actual converted bonuses)

Final NGR = €1,000 - €90 - €10 - €640 - €150 = €110
```

### **LTV Calculation Example**

```
Cohort: January 2024
NGR: €50,000
FTDs: 200

LTV = €50,000 / 200 = €250 per FTD

Interpretation:
- Average lifetime profit per depositing player = €250
- Max acceptable CAC = €250 (breakeven)
- Target CAC = €125-€175 (50-70% of LTV)
```

### **Currency Conversion**
- Multi-currency transactions converted using `eur_amount` field
- Formula: `COALESCE(eur_amount, amount)` (NULL-safe)
- All output displayed in EUR (€)

---

## 💡 How to Interpret Results

### **TOTAL Row Analysis**
- Aggregates all cohorts for overall performance
- Use as benchmark for individual cohort comparison
- Shows historical average LTV across all periods

### **Cohort Maturity**
| Cohort Age | Maturity Level | LTV Stability |
|------------|----------------|---------------|
| 0-3 months | Early | Low - still acquiring data |
| 4-6 months | Developing | Medium - trends emerging |
| 7-12 months | Mature | High - reliable LTV |
| 12+ months | Fully Mature | Very High - stable LTV |

**Important:** Older cohorts have more stable LTV values. Recent cohorts will show increasing LTV as players continue activity.

### **Conversion Rate Patterns**
- **High conversion (>25%):** Strong acquisition quality
- **Medium conversion (15-25%):** Healthy performance
- **Low conversion (<15%):** Quality issues, investigate source

### **LTV Trends**
- **Increasing over time:** Improving player quality or retention
- **Decreasing over time:** Quality degradation, needs attention
- **Stable over time:** Consistent performance
- **Seasonal spikes:** Holiday effects, promotional campaigns

### **Fee Impact Analysis**
Total fees as percentage of Cash GGR:
```
Provider Fee: 9%
Platform Fee: 1%
Payment Fee: Variable (depends on deposit/withdrawal ratio)
Bonus Cost: Variable (depends on promotions)

Typical Total: 18-30% of Cash GGR
```

**Healthy NGR:** 70-82% of Cash GGR

---

## 🎯 Common Use Cases

### **1. Marketing ROI Analysis**
```
Question: Is our €100 CAC profitable?

Analysis:
- Find mature cohorts (6+ months old)
- Average LTV = €180
- Payback ratio = €180 / €100 = 1.8x
- Conclusion: Profitable, continue acquisition
```

### **2. Cohort Performance Comparison**
```
Scenario: Compare Q1 vs Q2 2024 cohorts

Steps:
1. Filter by date range (Jan-Mar 2024 vs Apr-Jun 2024)
2. Compare average LTV between periods
3. Identify which quarter performed better
4. Investigate drivers (campaigns, seasonality, etc.)
```

### **3. Channel Performance Evaluation**
```
Question: Which traffic source has better LTV?

Steps:
1. Run report with Traffic Source = "Organic"
2. Note average LTV
3. Run report with Traffic Source = "Affiliate"
4. Note average LTV
5. Compare and allocate budget accordingly
```

### **4. Seasonal Trend Analysis**
```
Scenario: Do holiday months have better LTV?

Analysis:
- Compare Nov/Dec cohorts vs other months
- Look at multi-year patterns
- Adjust seasonal marketing spend
```

### **5. Payback Period Calculation**
```
Given:
- CAC = €120
- Cohort NGR growth per month = €20

Payback Period = €120 / €20 = 6 months

Track monthly to ensure projections accurate
```

---

## ⚠️ Important Notes

### **Data Completeness**
- Report shows **lifetime data through report run date**
- Recent cohorts are still "maturing" - LTV will increase
- Historical cohorts are stable - LTV unlikely to change significantly
- **Never compare recent vs old cohorts directly** (apples to oranges)

### **FTD Definition**
- Uses `ROW_NUMBER()` to identify **absolute first deposit**
- Player can only be FTD in one cohort (their registration month)
- Multiple deposits in same day counted as single FTD event
- Currency filter applies to FTD identification

### **Alignment with Other Reports**
- **Email Report:** NGR calculations now match exactly (Nov 2025)
- **Daily KPIs:** Uses identical FTD and promo bet/win logic
- **Bonus Dashboard:** Different scope (campaign-specific vs lifetime)

### **Fee Rates**
All fee percentages are **fixed and standardized**:
- Provider Fee: **9%** (not configurable)
- Payment Fee: **8%** (not configurable)
- Platform Fee: **1%** (not configurable)

Any changes require CTO approval and system-wide update.

### **Currency Filtering**
- Filter affects **transaction inclusion**, not just display
- Example: `currency_filter=USD` shows only USD transactions in EUR equivalent
- Use `currency_filter=EUR` to include multi-currency (default behavior)

### **Test Accounts**
- Excluded by default using `{{is_test_account}}` filter
- Include for testing/validation only
- Never include in production business analysis

---

## 📊 Example Output

```
┌────────────────┬─────┬─────┬──────────┬──────────┬────────┬─────────┬───────────┬─────────┐
│ Month Year     │ REG │ FTD │ Conv %   │ Deposit  │ WD     │ Cash GGR│ NGR       │ LTV     │
├────────────────┼─────┼─────┼──────────┼──────────┼────────┼─────────┼───────────┼─────────┤
│ TOTAL          │15,234│3,821│  25.09%  │€2,150,000│€980,000│ €415,000│  €85,000  │ €22.25  │
│ November 2025  │  520│  110│  21.15%  │  €45,000 │ €18,000│  €8,500 │  €1,450   │ €13.18  │
│ October 2025   │  612│  142│  23.20%  │  €68,000 │ €29,000│ €12,800 │  €2,650   │ €18.66  │
│ September 2025 │  588│  156│  26.53%  │  €82,000 │ €35,000│ €15,200 │  €3,180   │ €20.38  │
│ ...            │ ... │ ... │  ...     │  ...     │ ...    │  ...    │  ...      │ ...     │
└────────────────┴─────┴─────┴──────────┴──────────┴────────┴─────────┴───────────┴─────────┘
```

**Key Observations:**
- November cohort (newest) has lowest LTV - still maturing
- September cohort more mature - LTV stabilizing
- TOTAL row shows historical average LTV = €22.25

---

## 📞 Questions & Support

**For LTV interpretation:** Contact Finance or Analytics Team

**For CAC vs LTV analysis:** Contact Marketing Team with cohort data

**For data accuracy:** Contact Technical Team with specific cohort and metric

**For formula changes:** Requires CTO approval (aligned with Email Report)

---

**Last Updated:** November 2025
**Version:** Aligned with Daily/Email Reports
**Report Location:** `sql_reports_adjusted/ltv/cohort_ltv_lifetime.sql`
