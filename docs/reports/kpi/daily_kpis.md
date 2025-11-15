# Daily KPIs Report

## 📊 Report Purpose

The Daily KPIs Report provides comprehensive day-by-day performance metrics for detailed operational analysis. This report shows daily trends with a summary row at the bottom, enabling stakeholders to track performance fluctuations and identify patterns over custom date ranges.

**Use this report to:**
- Monitor daily operational performance
- Identify day-over-day trends and anomalies
- Track detailed player behavior metrics
- Analyze acquisition and retention patterns
- Deep-dive into specific time periods

---

## 📈 Key Metrics (35+ metrics)

### **Player Acquisition & Engagement**

#### **#Registrations**
- **What it measures:** New player accounts created per day
- **Includes:** All registration types (complete and incomplete)
- **Why it matters:** Top-of-funnel acquisition indicator

#### **#FTDs (First-Time Depositors)**
- **What it measures:** Players making their first deposit ever
- **Calculation:** Uses `ROW_NUMBER()` for accurate first deposit identification
- **Why it matters:** Critical conversion metric

#### **#New FTDs**
- **What it measures:** FTDs who registered within the reporting period
- **Calculation:** FTDs where registration_date >= start_date
- **Why it matters:** Shows immediate conversion from new acquisitions

#### **%New FTDs**
- **What it measures:** Percentage of FTDs from new registrations
- **Calculation:** `(New FTDs / Total FTDs) × 100`
- **Why it matters:** Indicates acquisition vs reactivation balance

#### **#Old FTDs**
- **What it measures:** FTDs who registered before the reporting period
- **Calculation:** FTDs where registration_date < start_date
- **Why it matters:** Shows delayed conversion from past registrations

#### **%Old FTDs**
- **What it measures:** Percentage of FTDs from old registrations
- **Calculation:** `(Old FTDs / Total FTDs) × 100`
- **Why it matters:** Indicates nurture campaign effectiveness

#### **#D0 FTDs**
- **What it measures:** Players who deposited on registration day
- **Calculation:** FTDs where deposit_date = registration_date
- **Why it matters:** Measures registration-to-deposit conversion speed
- **Healthy range:** 40-60% of New FTDs

#### **%D0 FTDs**
- **What it measures:** Percentage of FTDs converting same-day
- **Calculation:** `(D0 FTDs / Total FTDs) × 100`
- **Why it matters:** Indicates onboarding effectiveness

#### **#Late FTDs**
- **What it measures:** FTDs who deposited after registration day
- **Calculation:** FTDs where deposit_date > registration_date
- **Why it matters:** Shows nurture/retention effectiveness

#### **%Conversion (Total Reg)**
- **What it measures:** Overall registration-to-FTD conversion
- **Calculation:** `(FTDs / Total Registrations) × 100`
- **Why it matters:** Core acquisition efficiency metric
- **Healthy range:** 10-30%

#### **%Conversion (Complete Reg)**
- **What it measures:** Complete registration-to-FTD conversion
- **Calculation:** `(FTDs / Complete Registrations) × 100`
- **Why it matters:** True registration quality (excludes incomplete)

### **Deposit & Withdrawal Metrics**

#### **Unique Depositors**
- **What it measures:** Distinct players who deposited
- **Calculation:** COUNT(DISTINCT player_id) with deposit transactions
- **Why it matters:** Active depositing player base

#### **#Deposits**
- **What it measures:** Total number of deposit transactions
- **Calculation:** Count of completed deposit transactions
- **Why it matters:** Transaction volume indicator

#### **Deposits Amount**
- **What it measures:** Total value of deposits
- **Calculation:** Sum of completed deposits (withdrawable balance)
- **Why it matters:** Primary cash inflow

#### **#Withdrawals**
- **What it measures:** Total number of withdrawal transactions
- **Calculation:** Count of completed withdrawal transactions
- **Why it matters:** Payout transaction volume

#### **Withdrawals Amount**
- **What it measures:** Total value of withdrawals processed
- **Calculation:** Sum of completed withdrawals (withdrawable balance)
- **Why it matters:** Primary cash outflow

#### **Withdrawals Amount Canceled**
- **What it measures:** Withdrawals reversed/canceled by players
- **Calculation:** Sum of canceled withdrawal amounts
- **Why it matters:** Indicates player re-engagement

#### **%Withdrawals/Deposits**
- **What it measures:** Withdrawal-to-deposit ratio
- **Calculation:** `(Withdrawals / Deposits) × 100`
- **Why it matters:** Liquidity and retention indicator
- **Healthy range:** 40-70%

#### **CashFlow**
- **What it measures:** Net cash movement
- **Calculation:** `Deposits - Withdrawals`
- **Why it matters:** Daily liquidity position

### **Player Activity Metrics**

#### **Active Players**
- **What it measures:** Players with any transaction activity
- **Calculation:** COUNT(DISTINCT player_id) with any completed transaction
- **Why it matters:** Total active user base

#### **Real Active Players**
- **What it measures:** Players with real money gaming activity
- **Calculation:** COUNT(DISTINCT player_id) with game_bet transactions
- **Why it matters:** True gaming engagement

### **Gaming Revenue Metrics**

#### **Cash Bet**
- **What it measures:** Real money bets placed
- **Calculation:** Sum of game_bet debits (withdrawable balance)
- **Why it matters:** Core betting volume

#### **Cash Win**
- **What it measures:** Real money wins paid
- **Calculation:** Sum of game_bet credits (withdrawable balance)
- **Why it matters:** Player winnings

#### **Promo Bet** ⚠️ Updated Nov 2025
- **What it measures:** Promotional/bonus bets placed
- **Calculation:** Bonus transactions with `external_transaction_id IS NOT NULL`
- **Why it matters:** Promotional gaming activity
- **Note:** Logic updated from `balance_type='non-withdrawable'`

#### **Promo Win** ⚠️ Updated Nov 2025
- **What it measures:** Promotional/bonus wins paid
- **Calculation:** Bonus transactions with `external_transaction_id IS NOT NULL`
- **Why it matters:** Promotional payout costs
- **Note:** Logic updated from `balance_type='non-withdrawable'`

#### **Turnover**
- **What it measures:** Total betting volume
- **Calculation:** `Cash Bet + Promo Bet`
- **Why it matters:** Complete betting activity picture

#### **Turnover Casino**
- **What it measures:** Casino-specific betting volume
- **Calculation:** Same as Turnover (casino-only platform)
- **Why it matters:** Segment-specific analysis

#### **GGR (Gross Gaming Revenue)**
- **What it measures:** Total gaming profit
- **Calculation:** `(Cash Bet + Promo Bet) - (Cash Win + Promo Win)`
- **Why it matters:** Overall revenue before costs

#### **GGR Casino**
- **What it measures:** Casino-specific gaming profit
- **Calculation:** Same as GGR (casino-only platform)
- **Why it matters:** Segment-specific profitability

#### **Cash GGR**
- **What it measures:** Real money gaming profit
- **Calculation:** `Cash Bet - Cash Win`
- **Why it matters:** Core revenue metric

#### **Cash GGR Casino**
- **What it measures:** Casino real money profit
- **Calculation:** Same as Cash GGR (casino-only platform)
- **Why it matters:** Segment-specific analysis

### **Bonus & Cost Metrics**

#### **Bonus Converted (Gross)**
- **What it measures:** Bonuses converted to any balance type
- **Calculation:** Sum of all bonus_completion transactions
- **Why it matters:** Total bonus conversion volume

#### **Bonus Cost**
- **What it measures:** Bonuses converted to withdrawable cash
- **Calculation:** Sum of bonus_completion (withdrawable balance)
- **Why it matters:** Actual marketing cost of bonuses

#### **Granted Bonus** ⚠️ Updated Nov 2025
- **What it measures:** Bonus value issued to players
- **Calculation:** Campaign bonuses filtered by `player_bonus_id IS NOT NULL`
- **Includes:** Regular bonuses, free spins, free bets, completions
- **Why it matters:** Marketing investment tracking
- **Note:** Now filters campaign-based bonuses only

### **Performance Ratios**

#### **Bonus Ratio (GGR)**
- **What it measures:** Bonus cost as percentage of GGR
- **Calculation:** `(Bonus Cost / GGR) × 100`
- **Why it matters:** Marketing efficiency
- **Healthy range:** 10-25%

#### **Bonus Ratio (Deposits)**
- **What it measures:** Bonus cost as percentage of deposits
- **Calculation:** `(Bonus Cost / Deposits) × 100`
- **Why it matters:** Alternative efficiency measure

#### **Payout %**
- **What it measures:** Win-to-bet ratio
- **Calculation:** `((Cash Win + Promo Win) / (Cash Bet + Promo Bet)) × 100`
- **Why it matters:** Gaming return-to-player indicator
- **Typical range:** 92-97%

#### **%CashFlow to GGR**
- **What it measures:** Cash flow efficiency
- **Calculation:** `(CashFlow / GGR) × 100`
- **Why it matters:** Operational efficiency indicator

---

## 🔧 Available Filters

| Filter | Parameter | Options | Default | Description |
|--------|-----------|---------|---------|-------------|
| **Start Date** | `{{start_date}}` | Date picker | 31 days ago | Report start date |
| **End Date** | `{{end_date}}` | Date picker | Today | Report end date |
| **Brand** | `{{brand}}` | Dropdown | All | Company/brand filter |
| **Country** | `{{country}}` | Dropdown | All | Player country |
| **Currency** | `{{currency_filter}}` | Dropdown | EUR | Transaction currency |
| **Traffic Source** | `{{traffic_source}}` | Organic/Affiliate/All | All | Acquisition channel |
| **Affiliate ID** | `{{affiliate_id}}` | Numeric input | All | Specific affiliate |
| **Affiliate Name** | `{{affiliate_name}}` | Text input | All | Affiliate name |
| **Device/Browser** | `{{registration_launcher}}` | Dropdown | All | OS / Browser combo |
| **Test Accounts** | `{{is_test_account}}` | Boolean | Excluded | Include test players |

---

## 📊 Report Structure

### **Daily Rows**
- One row per day in date range
- Sorted chronologically (oldest to newest)
- All metrics calculated per-day

### **SUMMARY Row**
- Appears at bottom of report
- Aggregates all daily metrics
- Percentages recalculated for entire period

### **Example Structure**
```
Date          | Registrations | FTDs | Deposits | ... | GGR
2025-11-01   | 150           | 25   | €12,500  | ... | €2,800
2025-11-02   | 162           | 31   | €15,200  | ... | €3,100
2025-11-03   | 145           | 28   | €13,800  | ... | €2,950
...
SUMMARY      | 4,825         | 782  | €385,000 | ... | €85,200
```

---

## 🧮 Key Calculation Details

### **FTD Logic**
Uses `ROW_NUMBER() OVER (PARTITION BY player_id ORDER BY created_at ASC)`:
- Identifies absolute first deposit per player
- Prevents double-counting if player deposits multiple times
- Accurate even with duplicate timestamps

### **New vs Old FTDs**
- **New:** Registration date >= Report start date
- **Old:** Registration date < Report start date
- Sum always equals Total FTDs

### **D0 FTD Calculation**
```sql
WHERE DATE_TRUNC('day', deposit_timestamp) = DATE_TRUNC('day', registration_timestamp)
AND deposit_rank = 1
```

### **Currency Handling**
- All amounts use: `COALESCE(eur_amount, amount)`
- NULL-safe conversion
- Multi-currency support with EUR display

### **Promo Bet/Win (Updated Logic)**
**Old:** `balance_type = 'non-withdrawable'`
**New:** `external_transaction_id IS NOT NULL`

More accurate identification of promotional activity.

### **Granted Bonus (Updated Logic)**
**Filter:** `player_bonus_id IS NOT NULL`
**Purpose:** Only campaign-based bonuses, excludes system bonuses
**Categories:**
- `bonus` - Regular bonus credits
- `free_spin_bonus` - Free spin rewards
- `free_bet` / `free_bet_win` / `freebet_win` - Free bet rewards
- `bonus_completion` (non-withdrawable only)

---

## 💡 How to Interpret Results

### **Daily Patterns**
- **Weekday vs Weekend:** Typically different player behavior
- **Day-of-month effects:** Payday patterns (1st, 15th)
- **Seasonal trends:** Holidays, special events

### **SUMMARY Row Usage**
- Use for period-level KPIs
- Compare SUMMARY across different date ranges
- Evaluate campaign performance (before/after)

### **Conversion Funnel Analysis**
```
Registrations
    ↓ (%Conversion)
FTDs
    ↓ (%D0)
Same-Day FTDs
    ↓
Ongoing Activity
```

Track drop-off at each stage.

### **Anomaly Detection**
Watch for:
- Sudden spikes/drops in registrations
- Unusual conversion rate changes
- Unexpected GGR fluctuations
- Withdrawal ratio exceeding deposits

### **Cohort Analysis**
- Filter by registration date range
- Track New FTDs specifically
- Measure immediate conversion quality

---

## ⚠️ Important Notes

### **Date Range Defaults**
- No input: Last 31 days (including today)
- Custom range: Specify both start and end dates
- Max recommended: 365 days (performance)

### **Currency Filter Impact**
- Affects transaction inclusion, not just display
- EUR filter recommended for multi-currency view
- Specific currency shows only that currency

### **Test Accounts**
- Excluded by default
- Include for QA/testing purposes only
- Never include in business analysis

### **Alignment with Other Reports**
- **Email Report:** Same FTD, Promo Bet/Win, Granted Bonus logic
- **LTV Report:** Same FTD and promo logic
- **Monthly KPIs:** Same calculations, monthly aggregation

### **Performance Considerations**
- Large date ranges (>90 days) may take longer to load
- Use specific filters to improve query speed
- SUMMARY row calculated efficiently with aggregations

---

## 🎯 Common Use Cases

### **Daily Performance Monitoring**
Set date range to last 7 days, review trends.

### **Campaign Effectiveness**
Compare metrics before/during/after campaign dates.

### **Cohort Analysis**
Filter new registrations, track their FTD behavior.

### **Channel Performance**
Use Traffic Source filter to compare Organic vs Affiliate.

### **Country-Specific Analysis**
Filter by country to evaluate market performance.

### **Weekend vs Weekday Comparison**
Run report for weekdays only, then weekends only, compare.

---

## 📞 Questions & Support

**For metric definitions:** Refer to this documentation
**For data accuracy:** Contact Technical Team
**For business interpretation:** Contact Analytics Team
**For formula changes:** Requires CTO approval

---

**Last Updated:** November 2025
**Version:** Aligned with Email/LTV Reports
**Report Location:** `sql_reports_adjusted/kpi/daily_kpis.sql`
