# Monthly KPIs Report

## 📊 Report Purpose

The Monthly KPIs Report provides the same comprehensive metrics as the Daily KPIs Report but aggregated by month. This report is ideal for high-level trend analysis, executive reporting, and year-over-year comparisons.

**Use this report to:**
- Track monthly performance trends
- Compare month-over-month growth
- Perform year-over-year analysis
- Create executive-level summaries
- Identify seasonal patterns

---

## 📈 Key Metrics

**This report includes the same 35+ metrics as the Daily KPIs Report, aggregated monthly.**

For detailed metric definitions, see [Daily KPIs Report](daily_kpis.md).

### **Key Metrics Summary**
- **Player Acquisition:** Registrations, FTDs, New/Old FTDs, D0/Late FTDs
- **Financial Flow:** Deposits, Withdrawals, Cash Flow
- **Player Activity:** Active Players, Real Active Players
- **Gaming Revenue:** Cash Bet/Win, Promo Bet/Win, Turnover, GGR, Cash GGR
- **Costs:** Bonus Cost, Granted Bonus
- **Performance Ratios:** Conversion rates, Bonus ratios, Payout %, Hold %

---

## 🔧 Available Filters

**Same filters as Daily KPIs Report:**

| Filter | Parameter | Default | Description |
|--------|-----------|---------|-------------|
| **Start Date** | `{{start_date}}` | 24 months ago | First month to include |
| **End Date** | `{{end_date}}` | Current month | Last month to include |
| **Brand** | `{{brand}}` | All | Company/brand filter |
| **Country** | `{{country}}` | All | Player country |
| **Currency** | `{{currency_filter}}` | EUR | Transaction currency |
| **Traffic Source** | `{{traffic_source}}` | All | Organic/Affiliate/All |
| **Affiliate ID** | `{{affiliate_id}}` | All | Specific affiliate |
| **Affiliate Name** | `{{affiliate_name}}` | All | Affiliate name |
| **Device/Browser** | `{{registration_launcher}}` | All | OS / Browser combo |
| **Test Accounts** | `{{is_test_account}}` | Excluded | Include test accounts |

---

## 📊 Report Structure

### **Monthly Rows**
- One row per month in date range
- Sorted chronologically (oldest to newest)
- All metrics aggregated per month

### **SUMMARY Row**
- Appears at bottom of report
- Aggregates all monthly metrics
- Percentages recalculated for entire period

### **Example Structure**
```
Month        | Registrations | FTDs  | Deposits  | ... | GGR
2024-01     | 4,520         | 892   | €385,000  | ... | €85,200
2024-02     | 4,812         | 1,024 | €412,500  | ... | €91,800
2024-03     | 5,234         | 1,156 | €468,000  | ... | €102,400
...
SUMMARY     | 58,450        | 12,847| €4,850,000| ... | €1,125,000
```

---

## 🧮 Key Calculation Details

### **Monthly Aggregation**
- All daily metrics summed by month
- Month determined by `DATE_TRUNC('month', date_field)`
- Percentages recalculated at monthly level

### **Metric Calculations**
**Same formulas as Daily KPIs, applied monthly:**

- **FTD Logic:** `ROW_NUMBER()` to identify first deposits
- **Promo Bet/Win:** `external_transaction_id IS NOT NULL` (Updated Nov 2025)
- **Granted Bonus:** `player_bonus_id IS NOT NULL` for campaign bonuses (Updated Nov 2025)
- **Currency:** `COALESCE(eur_amount, amount)` for NULL safety

For detailed calculation explanations, see [Daily KPIs Report](daily_kpis.md).

---

## 💡 How to Interpret Results

### **Month-over-Month (MoM) Analysis**
Calculate growth:
```
MoM Growth % = ((Current Month - Previous Month) / Previous Month) × 100
```

Example:
```
March Registrations: 5,234
February Registrations: 4,812
MoM Growth = ((5,234 - 4,812) / 4,812) × 100 = +8.8%
```

### **Year-over-Year (YoY) Analysis**
Compare same months:
```
YoY Growth % = ((This Year - Last Year) / Last Year) × 100
```

Example:
```
March 2025 FTDs: 1,250
March 2024 FTDs: 1,100
YoY Growth = ((1,250 - 1,100) / 1,100) × 100 = +13.6%
```

### **Seasonal Patterns**
Look for:
- **Q1 (Jan-Mar):** Post-holiday recovery
- **Q2 (Apr-Jun):** Spring growth
- **Q3 (Jul-Sep):** Summer peaks
- **Q4 (Oct-Dec):** Holiday season spikes

### **Trend Analysis**
- **Upward trend:** Sustained growth (good)
- **Downward trend:** Decline requiring action
- **Flat trend:** Stagnation, needs investigation
- **Volatile:** Inconsistent, identify causes

---

## 🎯 Common Use Cases

### **1. Executive Dashboard**
Monthly summary for board/C-suite:
- Run last 12 months
- Focus on key metrics: FTDs, Deposits, GGR, NGR
- Highlight YoY growth

### **2. Budget Planning**
Historical trends for forecasting:
- Average monthly values
- Seasonal adjustment factors
- Growth rates for projections

### **3. Performance Review**
Quarterly business reviews:
- Aggregate by quarter
- Compare against targets
- Identify underperforming months

### **4. Marketing ROI**
Campaign impact analysis:
- Compare campaign months vs baseline
- Calculate incremental lift
- Assess cost-effectiveness

### **5. Seasonality Analysis**
Multi-year patterns:
- Compare same months across years
- Identify consistent seasonal peaks
- Plan marketing calendar

---

## ⚠️ Important Notes

### **Incomplete Current Month**
- Current month shows partial data (month-to-date)
- Don't compare incomplete month to complete months
- Use [Daily Email Report](../email/daily_email_report.md) for current month projections

### **Date Range Defaults**
- No input: Last 24 months
- Custom range: Specify both start and end months
- Includes partial months at boundaries

### **Differences from Daily KPIs**
| Aspect | Daily KPIs | Monthly KPIs |
|--------|-----------|--------------|
| **Granularity** | Per day | Per month |
| **Default Range** | 31 days | 24 months |
| **Use Case** | Operational | Strategic |
| **Performance** | Faster | Slightly slower |

### **Alignment with Other Reports**
- **Daily KPIs:** Same metrics, daily detail
- **Email Report:** Similar metrics, different format
- **LTV Report:** Related but cohort-based

---

## 📊 Recommended Visualizations

### **Line Charts**
Good for:
- Registrations over time
- FTD trends
- Revenue trends (GGR, Cash GGR)

### **Bar Charts**
Good for:
- Month-over-month comparisons
- Seasonal patterns
- Year-over-year comparison

### **Stacked Bar Charts**
Good for:
- New vs Old FTDs
- Cash vs Promo activity
- Breakdown of revenue components

### **Heatmaps**
Good for:
- Multi-year seasonal patterns
- Day-of-week effects within months
- Performance by month and metric

---

## 📞 Questions & Support

**For metric definitions:** See [Daily KPIs Report](daily_kpis.md) or contact Analytics

**For monthly vs daily choice:** Use Monthly for trends, Daily for operations

**For data accuracy:** Contact Technical Team with specific month and metric

**For business interpretation:** Contact Analytics or Finance Team

---

**Last Updated:** November 2025
**Version:** Aligned with Daily KPIs/Email/LTV Reports
**Report Location:** `sql_reports_adjusted/kpi/monthly_kpis.sql`
