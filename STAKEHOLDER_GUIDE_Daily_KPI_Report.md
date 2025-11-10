# Daily KPI Email Report - Stakeholder Guide

## Executive Summary

The **Daily KPI Report** is your comprehensive business intelligence dashboard that provides day-by-day insights into your gaming platform's performance. This report consolidates player acquisition, financial performance, gaming activity, and promotional effectiveness metrics into a single, actionable view.

**Purpose:** Monitor daily operational performance and identify trends across player behavior, revenue generation, and bonus efficiency.

**Delivery:** Available through Metabase dashboards with optional email distribution.

**Time Range:** Defaults to the last 31 days, fully customizable.

---

## Table of Contents

1. [Understanding Your Report](#understanding-your-report)
2. [Key Performance Indicators Explained](#key-performance-indicators-explained)
3. [How Metrics Are Calculated](#how-metrics-are-calculated)
4. [Using Filters Effectively](#using-filters-effectively)
5. [Reading the Report](#reading-the-report)
6. [Common Business Questions](#common-business-questions)
7. [Best Practices](#best-practices)
8. [Troubleshooting & FAQs](#troubleshooting--faqs)

---

## Understanding Your Report

### Report Structure

The Daily KPI Report consists of:

- **TOTAL Summary Row** - Aggregated metrics for the entire date range
- **Daily Detail Rows** - Individual metrics for each day in the selected period
- **40+ Metrics** - Covering acquisition, finance, gaming, and bonuses

### Default Behavior

| Setting | Default Value |
|---------|---------------|
| Date Range | Last 31 days (ending today) |
| Time Zone | Server time (typically UTC) |
| Currency | All currencies (can be filtered) |
| Brands | All brands (can be filtered) |
| Countries | All countries (can be filtered) |

---

## Key Performance Indicators Explained

### 1. Player Acquisition Metrics

#### **#Registrations**
- **What it measures:** Total new player signups
- **Why it matters:** Top-of-funnel indicator of marketing effectiveness
- **Good to know:** Includes both verified and unverified email addresses

#### **#FTDs (First-Time Depositors)**
- **What it measures:** Number of players making their first deposit
- **Why it matters:** The most critical conversion metric
- **Formula:** Unique players with first completed deposit in the date range

#### **#New FTDs vs #Old FTDs**
- **New FTDs:** Players who registered AND deposited in the same month
- **Old FTDs:** Players who deposited in a later month than registration
- **Why it matters:** Shows how quickly you convert players (velocity)

#### **#D0 FTDs (Day-0 FTDs)**
- **What it measures:** Players who deposit on the same day they register
- **Why it matters:** Indicates registration flow quality and player intent
- **Industry benchmark:** 60-80% of FTDs typically convert on D0

#### **%Conversion (Total Reg)**
- **Formula:** (#FTDs / #Registrations) × 100
- **Industry benchmark:** 5-15% for organic traffic, 15-35% for paid
- **Why it matters:** Core efficiency metric for player acquisition

#### **%Conversion (Complete Reg)**
- **Formula:** (#FTDs / Email-Verified Registrations) × 100
- **Why it matters:** Removes "junk" registrations for cleaner conversion rate
- **Use case:** Better for evaluating registration flow quality

---

### 2. Financial Metrics

#### **Unique Depositors**
- **What it measures:** Count of distinct players who made at least one deposit
- **Why it matters:** Measures active, engaged player base
- **Note:** One player depositing 5 times = 1 unique depositor

#### **#Deposits**
- **What it measures:** Total number of completed deposit transactions
- **Why it matters:** Transaction volume indicator
- **Note:** One player depositing 5 times = 5 deposits

#### **Deposits Amount**
- **What it measures:** Total monetary value of all completed deposits
- **Currency:** Respects currency filter (resolves from transaction metadata)
- **Why it matters:** Primary revenue inflow

#### **#Withdrawals & Withdrawals Amount**
- **What it measures:** Completed withdrawal transactions and their total value
- **Why it matters:** Player trust indicator; retention signal
- **Good to know:** High withdrawal rates can indicate player satisfaction

#### **Withdrawals Amount Canceled**
- **What it measures:** Value of withdrawals that were cancelled (not completed)
- **Why it matters:** May indicate payment issues or retention tactics
- **Use case:** Monitor for operational problems

#### **%Withdrawals/Deposits**
- **Formula:** (Withdrawals Amount / Deposits Amount) × 100
- **Industry benchmark:** 40-70% is typical
- **Why it matters:** Liquidity and profitability indicator
- **Red flag:** >100% means you're paying out more than taking in

#### **CashFlow**
- **Formula:** Deposits Amount - Withdrawals Amount
- **Why it matters:** Net financial movement (not profit!)
- **Important:** This is NOT GGR - it includes unclaimed winnings

---

### 3. Gaming Activity Metrics

#### **Active Players**
- **What it measures:** Players who placed at least one bet (cash OR promo)
- **Why it matters:** Overall platform engagement
- **Use case:** Track daily active users (DAU)

#### **Real Active Players**
- **What it measures:** Players who placed at least one CASH bet
- **Why it matters:** True revenue-generating activity
- **Key difference:** Excludes bonus-only players

#### **Cash Bet**
- **What it measures:** Total bet amount using withdrawable (cash) balance
- **Why it matters:** Core revenue-generating activity
- **Use case:** Primary indicator of betting volume

#### **Cash Win**
- **What it measures:** Total winnings paid from cash balance bets
- **Why it matters:** Payout obligation to players
- **Note:** Includes all wins, even if not withdrawn

#### **Promo Bet**
- **What it measures:** Total bet amount using bonus/non-withdrawable balance
- **Why it matters:** Measures bonus utilization
- **Use case:** Track promotional engagement

#### **Promo Win**
- **What it measures:** Winnings from bonus balance + free spin winnings
- **Why it matters:** Bonus cost component
- **Note:** Includes completed free spins

#### **Turnover (Total Turnover)**
- **Formula:** Cash Bet + Promo Bet
- **Industry term:** "Handle" or "Stakes"
- **Why it matters:** Total betting activity across all balance types

#### **GGR (Gross Gaming Revenue)**
- **Formula:** (Cash Bet + Promo Bet) - (Cash Win + Promo Win)
- **Why it matters:** THE PRIMARY PROFITABILITY METRIC
- **Industry standard:** This is what gaming platforms report as revenue
- **Note:** Before bonuses, but includes promo activity

#### **Cash GGR**
- **Formula:** Cash Bet - Cash Win
- **Why it matters:** Revenue excluding promotional activity
- **Use case:** "True" revenue generation without bonus distortion

#### **Payout %**
- **Formula:** [(Cash Win + Promo Win) / (Cash Bet + Promo Bet)] × 100
- **Industry benchmark:** 92-97% for slots, 97-99% for table games
- **Why it matters:** Return-to-player (RTP) verification
- **Red flag:** Consistently below 90% may indicate game configuration issues

---

### 4. Bonus & Promotion Metrics

#### **Bonus Converted**
- **What it measures:** Bonus amount successfully converted to withdrawable cash
- **Requirements:** Players completed wagering requirements
- **Why it matters:** Cost of promotional offers

#### **Bonus Cost**
- **Formula:** All bonus amounts that became withdrawable
- **Why it matters:** Total promotional expense
- **Note:** Includes wagering completions only (not unclaimed bonuses)

#### **Bonus Ratio (GGR)**
- **Formula:** (Bonus Cost / GGR) × 100
- **Industry benchmark:** 10-25%
- **Why it matters:** Measures promotional efficiency
- **Use case:** Track if bonuses drive sufficient revenue

#### **Bonus Ratio (Deposits)**
- **Formula:** (Bonus Cost / Deposits Amount) × 100
- **Why it matters:** Alternative view of bonus cost relative to deposits
- **Use case:** CFO-friendly metric for P&L analysis

#### **%CashFlow to GGR**
- **Formula:** (CashFlow / GGR) × 100
- **Industry benchmark:** 80-120%
- **Why it matters:** Reconciliation metric
- **Red flag:** <50% may indicate unclaimed winnings or bonus abuse

---

## How Metrics Are Calculated

### Data Sources

All metrics are calculated from three primary database tables:

| Table | Contains |
|-------|----------|
| **players** | Registration info, email verification, country, brand, affiliate |
| **transactions** | Deposits, withdrawals, bets, wins, bonuses, completions |
| **companies** | Brand names, default currencies |

### Currency Resolution Logic

The report uses a **4-tier cascade** to determine transaction currency:

```
1. Transaction metadata currency (highest priority)
   ↓
2. Transaction cash_currency field
   ↓
3. Player wallet_currency
   ↓
4. Company default currency (lowest priority)
```

**Why this matters:** Ensures accurate multi-currency reporting even with incomplete data.

### Transaction Filtering Rules

#### Deposits
```sql
transaction_category = 'deposit'
transaction_type = 'credit'
status = 'completed'
balance_type = 'withdrawable'
```

#### Withdrawals
```sql
transaction_category = 'withdrawal'
transaction_type = 'debit'
balance_type = 'withdrawable'
status = 'completed'
```

#### Cash Bets
```sql
transaction_category = 'game_bet'
transaction_type = 'debit'
balance_type = 'withdrawable'
status = 'completed'
```

#### Promo Bets
```sql
transaction_category = 'bonus'
transaction_type = 'debit'
balance_type = 'non-withdrawable'
status = 'completed'
```

#### Bonus Converted
```sql
transaction_category = 'bonus_completion'
transaction_type = 'credit'
balance_type = 'withdrawable'
status = 'completed'
```

---

## Using Filters Effectively

### Available Filters

#### **Date Range Filters**

| Filter | Default | Use Case |
|--------|---------|----------|
| Start Date | 31 days ago | Custom date range start |
| End Date | Today | Custom date range end |

**Tips:**
- Leave blank for last 31 days
- Use for week-over-week, month-over-month analysis
- Maximum recommended range: 90 days for performance

---

#### **Brand Filter**

**Field:** Company Name (from companies table)

**Examples:**
- "Casino Royal"
- "Lucky Spin Gaming"
- "BetMaster"

**Use cases:**
- Multi-brand operators isolating performance
- Compare brand performance side-by-side
- White-label partner reporting

---

#### **Country Filter**

**Format:** Full country name (converts to ISO codes internally)

**Supported countries:**
- Romania, France, Germany, Cyprus, Poland, Spain, Italy
- Canada, Australia, United Kingdom, Finland
- Albania, Austria, Belgium, Brazil, Bulgaria
- Georgia, Greece, Hungary, India, Netherlands
- Portugal, Singapore, Turkey, United Arab Emirates
- Afghanistan, Armenia, Denmark, Algeria, Andorra

**Use cases:**
- Regulatory compliance reporting
- Geo-targeted campaign analysis
- Market penetration tracking

---

#### **Currency Filter**

**Format:** ISO currency codes (uppercase)

**Examples:** EUR, USD, GBP, CAD, AUD, RON, PLN

**Use cases:**
- Single-currency P&L reports
- Avoid FX conversion complexity
- Regional financial reports

**Important:** Filters using the 4-tier resolution cascade

---

#### **Traffic Source Filter**

**Options:**
- **Organic** - Players with no affiliate_id
- **Affiliate** - Players with an affiliate_id

**Use cases:**
- CAC (customer acquisition cost) analysis
- Organic vs paid performance comparison
- Marketing ROI calculations

---

#### **Affiliate ID / Affiliate Name**

**Field:** Text match against affiliate_id or affiliate_name

**Use cases:**
- Partner performance reporting
- Commission calculations
- Fraud detection (unusual conversion patterns)

---

#### **Registration Launcher**

**Format:** "OS / Browser" (e.g., "Android / Chrome", "iOS / Safari")

**Use cases:**
- Mobile vs desktop performance
- Browser-specific conversion issues
- Device targeting for campaigns

---

#### **Test Account Filter**

**Field:** is_test_account (boolean)

**Options:**
- Include test accounts
- Exclude test accounts (RECOMMENDED for production reports)

**Why it matters:** Test accounts can severely distort metrics

---

### Filter Best Practices

#### ✅ DO:
- **Start broad, narrow down** - Begin without filters, add as needed
- **Compare apples to apples** - Use same filters when comparing periods
- **Exclude test accounts** - Always filter these out for business reporting
- **Document filter settings** - Note what filters were applied in reports

#### ❌ DON'T:
- **Over-filter** - Too many filters = too little data
- **Mix filtered and unfiltered** - Causes confusion in trend analysis
- **Forget currency filters** - Multi-currency reports can be misleading
- **Compare different filter sets** - Makes trend analysis invalid

---

## Reading the Report

### Anatomy of the Report Output

```
┌─────────────┬──────────────┬─────────┬─────────────┬──────────┐
│    Date     │ #Registrations│  #FTDs  │  Deposits   │   GGR    │
│             │              │         │   Amount    │          │
├─────────────┼──────────────┼─────────┼─────────────┼──────────┤
│   TOTAL     │    1,250     │   187   │  €45,320.50 │ €8,125.30│  ← SUMMARY ROW
├─────────────┼──────────────┼─────────┼─────────────┼──────────┤
│ 2024-01-15  │     42       │    7    │  €1,450.00  │  €285.40 │  ← DAILY DETAIL
│ 2024-01-16  │     38       │    5    │  €1,125.00  │  €210.50 │
│ 2024-01-17  │     55       │    9    │  €2,340.75  │  €425.80 │
└─────────────┴──────────────┴─────────┴─────────────┴──────────┘
```

### Understanding the TOTAL Row

The **TOTAL** row appears first and shows:

- **Sums:** Most metrics (registrations, deposits, amounts, GGR)
- **Weighted averages:** Percentages (conversion rates, bonus ratios)
- **Unique counts:** Unique depositors (NOT sum of daily uniques!)

**Critical distinction:**
- ✅ **Unique Depositors in TOTAL** = Distinct players across entire period
- ❌ **Sum of daily unique depositors** ≠ Total unique depositors

**Example:**
```
Day 1: Player A deposits (1 unique depositor)
Day 2: Player A deposits again (1 unique depositor)
Day 2: Player B deposits (1 unique depositor)

Daily sum: 1 + 1 + 1 = 3
TOTAL unique: 2 (Player A + Player B)
```

---

### Day-by-Day Analysis

#### Look for:

1. **Weekly patterns**
   - Weekends vs weekdays
   - Payday patterns (1st, 15th of month)

2. **Outliers**
   - Sudden spikes in registrations (campaign launch?)
   - Unusual payout % (game configuration issue?)
   - High withdrawal days (big winner?)

3. **Trends**
   - Declining conversion rates
   - Increasing bonus costs
   - Growing active player base

---

## Common Business Questions

### Q1: "How is our player acquisition performing?"

**Metrics to check:**
1. **#Registrations** - Top of funnel
2. **%Conversion total reg** - Funnel efficiency
3. **#D0 FTDs** - Acquisition quality
4. **%New FTDs** - Conversion velocity

**Red flags:**
- Conversion <5% (for organic)
- D0 FTDs <50% of total FTDs
- Growing registrations but flat FTDs

---

### Q2: "Are we making money?"

**Primary metric:** **GGR** (Gross Gaming Revenue)

**Supporting metrics:**
- **Cash GGR** - Revenue without bonus distortion
- **Bonus Ratio (GGR)** - Is promotional cost sustainable?
- **CashFlow** - Are we net positive on deposits/withdrawals?

**Profitability formula:**
```
Net Profit = GGR - Bonus Cost - Operating Expenses - Payment Fees - Taxes
```

**Healthy indicators:**
- GGR > 0 (always!)
- Bonus Ratio (GGR) < 25%
- CashFlow positive
- Cash GGR growing month-over-month

---

### Q3: "How effective are our bonuses?"

**Key metrics:**
1. **Bonus Ratio (GGR)** - Cost as % of revenue
2. **Bonus Converted** - How much players actually converted
3. **Promo Bet** - Are bonuses driving engagement?

**Ideal scenario:**
```
High Promo Bet + Low Bonus Cost + High GGR = Effective bonuses
```

**Warning signs:**
- Bonus Ratio >30% (unsustainable)
- Bonus Converted >>> Promo Bet (abuse)
- High bonus cost but low retention

---

### Q4: "Are we retaining players?"

**Metrics to watch:**
1. **Unique Depositors** - Growing over time?
2. **Real Active Players** - Sustained engagement?
3. **#Old FTDs** - Players returning to deposit?
4. **Withdrawals Amount** - Players winning and staying?

**Good retention signs:**
- Unique depositors growing faster than registrations
- Old FTDs >30% of total FTDs
- Consistent real active player counts

---

### Q5: "Is our RTP (payout %) correct?"

**Primary metric:** **Payout %**

**Expected ranges by game type:**
- **Slots:** 92-97%
- **Table games:** 97-99%
- **Live dealer:** 98-99.5%

**Investigation triggers:**
- Payout % <90% (games paying too little)
- Payout % >100% (games paying too much - urgent!)
- Wild day-to-day variation (>5% swings)

**Note:** Short-term variance is normal; look at 30-day trends

---

### Q6: "Which campaigns are working?"

**Filter by:**
- **Traffic Source** (Organic vs Affiliate)
- **Affiliate ID** (specific partners)
- **Registration Launcher** (device/browser)

**Compare:**
- Conversion rates
- FTD quality (D0 FTDs %)
- LTV proxies (deposits per FTD)

**Winner identification:**
```
High conversion + High D0 FTDs + High deposits per FTD = Scale this!
```

---

## Best Practices

### Daily Monitoring

#### What to check daily:

✅ **Operational metrics** (morning routine)
1. Active Players - platform health check
2. Deposits Amount - cash flow monitoring
3. GGR - profitability pulse
4. Payout % - RTP verification

✅ **Anomaly detection**
1. Sudden spikes or drops (>20% change)
2. Zero-value days (data pipeline issue?)
3. Unusual bonus ratios (abuse?)

---

### Weekly Review

#### Monday morning reports:

✅ **Week-over-week comparison**
1. Total registrations (growth trends)
2. FTD conversion (acquisition efficiency)
3. Total GGR (revenue performance)
4. Bonus ratio (cost control)

✅ **Campaign effectiveness**
1. Filter by traffic source
2. Compare affiliate performance
3. Identify top-performing channels

---

### Monthly Business Review

✅ **Strategic metrics**
1. Month-over-month growth rates
2. Customer acquisition cost (CAC) trends
3. Bonus ROI (GGR / Bonus Cost)
4. Retention indicators (Old FTDs %, repeat depositors)

✅ **Financial reconciliation**
1. CashFlow vs GGR alignment
2. Withdrawal patterns (trust indicator)
3. Currency mix changes (market shifts)

---

### Red Flag Checklist

🚩 **Immediate attention required if:**

| Condition | Threshold | Possible Issue |
|-----------|-----------|----------------|
| Payout % | >100% or <85% | Game configuration error |
| Bonus Ratio (GGR) | >40% | Bonus abuse or unsustainable promotions |
| %Withdrawals/Deposits | >95% | Payment fraud or operational loss |
| Conversion rate | Drops >50% day-over-day | Registration flow broken |
| GGR | Negative | Critical operational issue |
| Active Players | Zero for multiple days | Data pipeline failure |

---

### Data Quality Checks

#### Before trusting your report:

✅ **Completeness checks**
1. No missing days in date range
2. TOTAL row values make sense
3. All brands/currencies included (if expected)

✅ **Sanity checks**
1. Deposits Amount > Withdrawals Amount (usually)
2. FTDs ≤ Unique Depositors (always)
3. Unique Depositors ≤ Registrations (always)
4. Cash Bet + Promo Bet = Turnover (always)

✅ **Consistency checks**
1. Compare to yesterday's report (overlapping dates should match)
2. Cross-check with payment processor reports
3. Verify test accounts are excluded

---

## Troubleshooting & FAQs

### Numbers Don't Match My Expectations

**Common causes:**

1. **Currency mixing**
   - **Solution:** Apply currency filter to isolate single currency

2. **Test accounts included**
   - **Solution:** Filter `is_test_account = false`

3. **Date range confusion**
   - **Solution:** Check start/end dates; report uses transaction created_at timestamps

4. **Time zone differences**
   - **Solution:** Report uses server time (typically UTC); adjust expectations

5. **Brand/country filters applied unknowingly**
   - **Solution:** Clear all filters and re-apply intentionally

---

### Why Don't Daily Unique Depositors Sum to TOTAL?

**This is correct behavior!**

**Explanation:**
- Daily unique depositors count each player once per day
- TOTAL unique depositors count each player once across entire period
- Same player on multiple days = counted once in TOTAL

**Example:**
```
Day 1: Player A, B, C deposit (3 unique)
Day 2: Player A, D deposit (2 unique)

Daily sum: 3 + 2 = 5
TOTAL unique: 4 (A, B, C, D)
```

---

### Conversion Rate Seems Low

**Investigation steps:**

1. **Check registration quality**
   - Compare %Conversion total vs complete reg
   - High incomplete registrations = flow issues

2. **Check D0 FTDs %**
   - Low D0 % = players not converting immediately
   - May indicate friction in deposit flow

3. **Filter by traffic source**
   - Organic typically converts lower than paid
   - Compare to industry benchmarks for your source

4. **Time lag consideration**
   - Players may convert days/weeks after registration
   - Use monthly report for longer conversion windows

---

### GGR is Negative - Is This Wrong?

**No - negative GGR is possible!**

**Causes:**
- Big winner(s) on the day/period
- High-variance games (slots with massive jackpots)
- Small sample size (early days, few players)

**When to worry:**
- Negative GGR for 7+ consecutive days
- Negative GGR across large player volumes
- Payout % consistently >100%

**Action:** Check Payout % and investigate specific game payouts

---

### Bonus Ratio Seems High

**Acceptable ranges:**
- **10-15%:** Efficient bonus program
- **15-25%:** Normal for competitive markets
- **25-35%:** High but sustainable short-term (campaigns)
- **>35%:** Unsustainable or potential abuse

**Causes of high ratio:**
1. Aggressive welcome bonuses (new player acquisition)
2. Bonus hunters (players gaming wagering requirements)
3. Low GGR period (denominator effect)
4. Misconfigured bonuses (too easy to convert)

**Solutions:**
- Tighten wagering requirements
- Reduce bonus sizes
- Implement max conversion caps
- Better player segmentation

---

### Where is LTV or Cohort Data?

**This report doesn't include:**
- Lifetime value (LTV) calculations
- Cohort retention analysis
- Long-term player value metrics

**For those metrics, use:**
- **Cohort LTV Lifetime Report** (separate report)
- **Monthly KPIs Report** (longer time windows)
- **Cohort Analysis Reports** (12 dedicated cohort reports available)

---

### Can I Export This Report?

**Yes!** Metabase supports:

1. **CSV export** - All data, full precision
2. **Excel export** - Formatted spreadsheet
3. **PNG export** - Visualization snapshot
4. **Email subscriptions** - Automated daily delivery

**To set up daily email:**
1. Open report in Metabase
2. Click "Subscribe" in top right
3. Choose recipients and schedule
4. Select delivery time (recommend early morning)

---

### How Real-Time is This Data?

**Data freshness:**
- **Transactions:** Near real-time (<5 minutes typical)
- **Player registrations:** Real-time
- **Email verification:** Real-time

**Important:** Report calculates on-demand when opened, so:
- Latest data always included
- No "stale" cached results
- Longer date ranges = slower queries

**Performance tip:** Use 30-60 day windows for best speed

---

## Glossary

| Term | Definition |
|------|------------|
| **FTD** | First-Time Depositor - player making their first deposit ever |
| **GGR** | Gross Gaming Revenue - bets minus wins before costs |
| **NGR** | Net Gaming Revenue - GGR minus bonus costs |
| **RTP** | Return to Player - % of bets paid back as wins |
| **Payout %** | Same as RTP (bets won / bets placed × 100) |
| **Turnover** | Total bets placed (cash + promo) |
| **Handle** | Alternative term for turnover |
| **Cash Balance** | Withdrawable player balance |
| **Bonus Balance** | Non-withdrawable promotional balance |
| **Wagering Requirement** | Bet multiplier to convert bonus to cash (e.g., 30x) |
| **CPA** | Cost Per Acquisition - marketing cost per FTD |
| **CAC** | Customer Acquisition Cost - total cost to acquire player |
| **DAU** | Daily Active Users - unique players active per day |
| **Cohort** | Group of players sharing common characteristic (e.g., registration month) |

---

## Technical Notes

### Database Tables Used

- **players** - Player registration and profile data
- **transactions** - All financial and gaming transactions
- **companies** - Brand configuration and defaults

### Query Performance

**Typical execution times:**
- 7 days: <2 seconds
- 31 days: 3-5 seconds
- 90 days: 8-15 seconds
- 365 days: 30-60 seconds (not recommended)

**Optimization tips:**
- Use currency filters to reduce transaction volume
- Limit date ranges to what you need
- Apply brand filters for multi-brand setups

### Data Retention

- **Transaction history:** Typically unlimited
- **Report availability:** Real-time (no pre-aggregation)
- **Deleted players:** Still counted in historical metrics

---

## Support & Feedback

### Getting Help

**For data questions:**
1. Check this guide first
2. Review [FAQ section](#troubleshooting--faqs)
3. Contact: [Your BI team contact]

**For technical issues:**
1. Metabase not loading: [Your IT support]
2. Data discrepancies: [Your data team contact]
3. Report access: [Your admin contact]

**For business interpretation:**
1. Metric definitions: This guide
2. Strategic questions: [Your analytics team]
3. Custom reporting needs: [Your BI team]

---

## Document Information

**Version:** 1.0
**Last Updated:** 2025-11-10
**Report Name:** Daily KPIs - Multi-Day with Summary Row
**Maintained By:** Analytics Team
**Review Schedule:** Quarterly

---

## Quick Reference Card

### Daily Health Check (5 minutes)

```
✓ Active Players       - Is anyone playing?
✓ GGR                  - Are we making money?
✓ Payout %             - Is RTP in normal range?
✓ Deposits Amount      - Is cash flowing in?
✓ #FTDs                - Are we acquiring customers?
```

### Weekly Deep Dive (30 minutes)

```
✓ Week-over-week trends in registrations & FTDs
✓ Conversion rate changes
✓ Bonus ratio sustainability
✓ Top-performing traffic sources
✓ Outlier days investigation
```

### Monthly Business Review (2 hours)

```
✓ Month-over-month growth analysis
✓ CAC and LTV trends (cross-reference cohort reports)
✓ Bonus ROI evaluation
✓ Market mix analysis (countries, brands)
✓ Strategic recommendations
```

---

**Remember:** Data is only valuable if it drives action. Use this report to identify trends, spot problems early, and make informed decisions. When in doubt, start with the TOTAL row and drill down from there.

**Happy analyzing! 📊**
