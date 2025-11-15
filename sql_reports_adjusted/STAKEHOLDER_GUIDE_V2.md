# BTB Gaming Analytics - Stakeholder Guide V2
## Understanding Your Dashboard Metrics & Formulas

**Version:** 2.0
**Date:** November 3, 2025
**Audience:** Business Stakeholders, Product Managers, Executives
**Status:** ✅ All Reports Aligned with CTO-Approved Calculations

---

## 🎯 What's New in V2

### Major Updates
✅ **All 16 reports now use identical FTD (First-Time Depositor) logic**
✅ **LTV formulas updated to CTO-approved calculations**
✅ **New Cash GGR metric added to LTV report**
✅ **NGR formula now includes Bonus Cost**
✅ **Consistent currency filtering across all reports**

### Why This Matters
Previously, different reports calculated first-time depositors differently, leading to inconsistent numbers across dashboards. **Now all reports use the same source of truth**, ensuring stakeholders see matching data everywhere.

---

## 📊 Available Reports (16 Total)

### 1. Performance Reports (2 KPI Reports)
| Report | Purpose | Key Metrics | Update Frequency |
|--------|---------|-------------|------------------|
| **Daily KPIs** | Day-by-day performance tracking | REG, FTD, Deposits, GGR, Cash Flow | Daily |
| **Monthly KPIs** | Month-by-month aggregated trends | Same as Daily (monthly totals) | Monthly |

**What They Show:**
- Player registration and conversion rates
- Deposit and withdrawal volumes
- Revenue metrics (GGR, Cash GGR, Cash Flow)
- Bonus costs and ratios
- Payout percentages

---

### 2. Bonus Analysis Report (1 Report)
| Report | Purpose | Key Metrics |
|--------|---------|-------------|
| **Bonus Dashboard** | Track bonus campaign effectiveness | Bonus distributed, completed, conversion rates |

**What It Shows:**
- Total bonuses given to players
- How many players complete bonus requirements
- Bonus conversion percentages
- Cost of bonus programs

---

### 3. Player Cohort Reports (12 Cohort Reports)

**What is a Cohort?**
A cohort is a group of players who made their first deposit in the same month. Cohort reports track how these groups behave over the following 12 months.

#### Depositor Retention Cohorts (2 Reports)
| Report | Shows | Example Question |
|--------|-------|------------------|
| **Depositors Cohort** | Absolute numbers of returning depositors | "How many players from January 2025 deposited again in February?" |
| **Depositors Cohort (%)** | Percentage retention rates | "What % of January 2025 depositors were still active in June?" |

#### Deposit Amount Cohorts (2 Reports)
| Report | Shows | Example Question |
|--------|-------|------------------|
| **Deposit Amounts Cohort** | Total deposit amounts by cohort over time | "How much did the January 2025 cohort deposit in Month 3?" |
| **Deposit Amounts Cohort (%)** | Deposit trends compared to Month 0 | "Are deposits increasing or decreasing over time?" |

#### Cash Player Cohorts (2 Reports)
| Report | Shows | Example Question |
|--------|-------|------------------|
| **Cash Players Cohort** | Number of players making cash bets | "How many players from the January cohort played in March?" |
| **Cash Players Cohort (%)** | Percentage of active cash players | "What % of the cohort is still playing after 6 months?" |

#### Cash Bet Amount Cohorts (2 Reports)
| Report | Shows | Example Question |
|--------|-------|------------------|
| **Cash Bet Amount Cohort** | Total cash wagered by cohort | "How much did January players bet in Month 4?" |
| **Cash Bet Amounts Cohort (%)** | Betting trends vs. first month | "Are players betting more or less over time?" |

#### New Depositor Cohorts (2 Reports)
| Report | Shows | Example Question |
|--------|-------|------------------|
| **New Depositors Cohort** | First-time depositors by registration month | "How many new depositors did we get in each month?" |
| **New Depositors Cohort (%)** | Percentage breakdown of deposit frequency | "What % make only 1 deposit vs. multiple deposits?" |

#### Existing Depositor Cohorts (2 Reports)
| Report | Shows | Example Question |
|--------|-------|------------------|
| **Existing Depositors Cohort** | Players making repeat deposits | "How many existing players deposited again in March?" |
| **Existing Depositors Cohort (%)** | Percentage of repeat depositors | "What % of existing players remain active?" |

**Cohort Time Periods:**
All cohort reports track players for **13 time periods**:
- **Month 0** = First deposit month
- **Months 1-12** = Following 12 months after first deposit

---

### 4. Lifetime Value Report (1 LTV Report)
| Report | Purpose | Key Metrics |
|--------|---------|-------------|
| **Cohort LTV Lifetime** | Calculate profitability per player cohort | REG, FTD, Deposits, GGR, Cash GGR, Fees, NGR, LTV |

**What It Shows:**
- Complete financial picture by player registration cohort
- All revenue, costs, and fees
- Net Gaming Revenue (NGR) after all deductions
- Lifetime Value (LTV) per first-time depositor

---

## 🔍 How to Use the Filters

Every report can be filtered to show exactly what you need. Here's what each filter does:

### Geographic & Business Filters

#### Brand
- **What it does:** Filter by specific casino brands/companies
- **Example:** "Casino Royal" or "Lucky Slots"
- **Technical:** Filters `companies.name`
- **Use when:** Comparing multi-brand performance

#### Country
- **What it does:** Show players from specific countries
- **Options:** 25 countries (Romania, France, Germany, etc.)
- **Technical:** Filters `players.country` (uses ISO codes: RO, FR, DE)
- **Use when:** Regional analysis, compliance reporting, market expansion planning

**Supported Countries:**
Romania, France, Germany, Cyprus, Poland, Spain, Italy, Canada, Australia, United Kingdom, Finland, Albania, Austria, Belgium, Brazil, Bulgaria, Georgia, Greece, Hungary, India, Netherlands, Portugal, Singapore, Turkey, UAE, Afghanistan, Armenia, Denmark, Algeria, Andorra

### Time Period Filters

#### Start Date & End Date
- **What it does:** Sets the date range for your analysis
- **Format:** YYYY-MM-DD
- **Default Ranges:**
  - **Daily KPIs:** Last 31 days
  - **Monthly KPIs:** Last 12 months
  - **Cohort Reports:** Last 12 months of first deposits
  - **LTV Report:** Last 24 months of registrations
- **Use when:** Creating board reports, analyzing specific campaigns, quarter-end reviews

**💡 Pro Tip:** For cohort reports, the date range filters the *first deposit month*, not the activity month.

### Currency Filter

#### Currency
- **What it does:** Shows data in specific currency OR converts to EUR
- **Options:** EUR (default), USD, RON, PLN, and others
- **Technical:**
  - Filters transactions by `currency_type` field
  - EUR option uses `eur_amount` for conversion
- **Use when:** Financial reporting in specific currencies, multi-currency analysis

**Important:** All monetary values in reports are in the selected currency. Changing this filter affects ALL financial metrics.

### Player Acquisition Filters

#### Traffic Source
- **What it does:** Separates organic vs. affiliate traffic
- **Options:**
  - **Organic** = Players who found you directly (no affiliate)
  - **Affiliate** = Players referred by partners
- **Technical:** Based on `players.affiliate_id` (NULL = Organic)
- **Use when:** Measuring marketing ROI, comparing acquisition channels

#### Affiliate ID
- **What it does:** Filter to specific affiliate partner by ID number
- **Example:** "12345"
- **Technical:** Filters `players.affiliate_id`
- **Use when:** Evaluating individual affiliate performance, calculating commissions

#### Affiliate Name
- **What it does:** Search/filter by affiliate partner name
- **Example:** "PartnerCasino" or "SuperAffiliates"
- **Technical:** Filters `affiliates.name`
- **Use when:** Finding affiliates by name instead of remembering IDs

### Device & Technical Filters

#### Registration Launcher (Device)
- **What it does:** Shows which device/browser players used to register
- **Format:** "OS / Browser"
- **Examples:**
  - "iOS / Safari"
  - "Android / Chrome"
  - "Windows / Firefox"
- **Technical:** Concatenates `players.os` + `players.browser`
- **Use when:** Optimizing mobile experience, understanding user behavior

#### Test Account Filter
- **What it does:** Include or exclude test accounts
- **Options:**
  - **True** = Show only test accounts
  - **False** = Show only real players
  - **Both** = Show all accounts
- **Technical:** Filters `players.is_test_account`
- **Use when:** Production reporting (exclude tests), QA validation (include tests)

**⚠️ Important:** Always exclude test accounts for business reporting!

---

## 📈 Understanding Key Metrics

### Registration & Conversion Metrics

#### REG (Registrations)
- **Definition:** Total new player accounts created
- **Formula:** `COUNT(DISTINCT players)`
- **Found in:** Daily KPIs, Monthly KPIs, LTV Report
- **Why it matters:** Top of funnel metric - shows marketing effectiveness

#### FTD (First-Time Depositors)
- **Definition:** Players who made their first deposit (CTO-approved calculation)
- **Formula:** Uses `ROW_NUMBER()` window function to identify true first deposit
- **Found in:** All KPI and Cohort reports
- **Why it matters:** Most important conversion metric - shows monetization success

**How FTD is Calculated (Technical):**
```sql
1. Rank all deposits per player by timestamp
2. Take deposit WHERE rank = 1 (the very first one)
3. Apply date and currency filters
4. Count unique players
```

**⚠️ Important Change:** As of November 2025, ALL reports use this identical FTD calculation method. Previous versions had inconsistencies.

#### Conversion Rate
- **Definition:** Percentage of registrations that become depositors
- **Formula:** `(FTD / REG) × 100`
- **Found in:** Daily KPIs, Monthly KPIs, LTV Report
- **Good benchmark:** 15-25% for gaming industry
- **Why it matters:** Shows how effective your onboarding and acquisition are

### Financial Metrics - Revenue

#### GGR (Gross Gaming Revenue)
- **Definition:** Total profit from all gaming activity (cash + promo)
- **Formula:** `(cash_bet + promo_bet) - (cash_win + promo_win)`
- **Found in:** Daily KPIs, Monthly KPIs, LTV Report
- **Why it matters:** Total revenue before deducting any costs

#### Cash GGR ⭐ NEW IN V2
- **Definition:** Profit from ONLY cash bets (excludes promo bets)
- **Formula:** `cash_bet - cash_win`
- **Found in:** Daily KPIs, LTV Report
- **Why it matters:** Shows "real money" revenue, used for fee calculations

**Difference between GGR and Cash GGR:**
- **GGR** = All gaming revenue (cash + bonus play)
- **Cash GGR** = Only cash gaming revenue (what fees are based on)

#### Cash Bet
- **Definition:** Total amount wagered using real money (withdrawable balance)
- **Formula:** `SUM(transactions WHERE category='game_bet' AND balance_type='withdrawable')`
- **Found in:** Daily KPIs, Monthly KPIs, LTV Report
- **Why it matters:** Shows player engagement with real money

#### Cash Win
- **Definition:** Total amount won from real money bets
- **Formula:** `SUM(transactions WHERE category='game_bet' AND type='credit')`
- **Found in:** Daily KPIs, Monthly KPIs, LTV Report
- **Why it matters:** Determines player payout and RTP

#### Promo Bet & Promo Win
- **Definition:** Betting and winning using bonus/promotional balance
- **Formula:** Similar to cash bet/win but `balance_type='non-withdrawable'`
- **Found in:** Daily KPIs, Monthly KPIs, LTV Report
- **Why it matters:** Tracks bonus engagement (cost is in Bonus Cost)

### Financial Metrics - Costs & Fees

#### Provider Fee
- **Definition:** Fee paid to game providers (9% of Cash GGR)
- **Formula:** `Cash GGR × 0.09`
- **Found in:** LTV Report
- **Why it matters:** Major operational cost, affects profitability

#### Payment Fee
- **Definition:** Transaction processing fees (8% of deposits + withdrawals)
- **Formula:** `(Deposits + Withdrawals) × 0.08`
- **Found in:** LTV Report
- **Why it matters:** Cost of payment processing infrastructure

#### Platform Fee
- **Definition:** Platform/software licensing fee (1% of Cash GGR)
- **Formula:** `Cash GGR × 0.01`
- **Found in:** LTV Report
- **Why it matters:** Technology infrastructure cost

#### Bonus Cost
- **Definition:** Total cost of bonuses that players successfully converted to cash
- **Formula:** `SUM(transactions WHERE category='bonus_completion')`
- **Found in:** Daily KPIs, Monthly KPIs, Bonus Report, LTV Report
- **Why it matters:** Major acquisition/retention cost

### Financial Metrics - Profitability

#### NGR (Net Gaming Revenue) ⭐ UPDATED IN V2
- **Definition:** Revenue after all fees and bonus costs
- **Formula:** `Cash GGR - Provider Fee - Payment Fee - Platform Fee - Bonus Cost`
- **Breakdown:**
  ```
  Starting with: Cash GGR (cash_bet - cash_win)
  Subtract: Provider Fee (9% of Cash GGR)
  Subtract: Payment Fee (8% of deposits+withdrawals)
  Subtract: Platform Fee (1% of Cash GGR)
  Subtract: Bonus Cost (completed bonuses)
  = NGR
  ```
- **Found in:** LTV Report
- **Why it matters:** True profit after all operating costs

**⚠️ Important Change:** NGR now includes Bonus Cost subtraction (previously separate).

#### LTV (Lifetime Value) ⭐ UPDATED IN V2
- **Definition:** Average profit per first-time depositor
- **Formula:** `NGR / FTD`
- **Found in:** LTV Report
- **Calculation:**
  - **Individual rows:** `NGR / FTD` for that cohort
  - **TOTAL row:** `SUM(NGR) / SUM(FTD)` across all cohorts
- **Good benchmark:** $100-500 depending on market
- **Why it matters:** Shows if player acquisition is profitable

**⚠️ Important Change:** LTV now uses NGR (which includes bonus cost), not Net Revenue. Calculation is consistent across individual rows and totals.

### Deposit & Withdrawal Metrics

#### Deposits (Amount)
- **Definition:** Total money deposited by players
- **Formula:** `SUM(transactions WHERE category='deposit' AND status='completed')`
- **Found in:** All KPI and Cohort reports
- **Why it matters:** Primary revenue source

#### Deposits (Count)
- **Definition:** Number of deposit transactions
- **Formula:** `COUNT(transactions WHERE category='deposit')`
- **Found in:** Daily KPIs, Monthly KPIs
- **Why it matters:** Shows transaction frequency

#### Withdrawals (Amount)
- **Definition:** Total money withdrawn by players
- **Formula:** `SUM(transactions WHERE category='withdrawal' AND status='completed')`
- **Found in:** All KPI and Cohort reports
- **Why it matters:** Cash outflow, affects liquidity

#### Withdrawals (Count)
- **Definition:** Number of withdrawal transactions
- **Formula:** `COUNT(transactions WHERE category='withdrawal')`
- **Found in:** Daily KPIs, Monthly KPIs
- **Why it matters:** Shows cashout behavior

#### Cash Flow
- **Definition:** Net cash movement (deposits minus withdrawals)
- **Formula:** `Deposits - Withdrawals`
- **Found in:** Daily KPIs, Monthly KPIs
- **Positive = Good:** More money coming in than going out
- **Negative = Warning:** More withdrawals than deposits
- **Why it matters:** Liquidity and working capital management

### Ratio Metrics

#### Bonus Ratio (GGR)
- **Definition:** Bonus cost as percentage of GGR
- **Formula:** `(Bonus Cost / GGR) × 100`
- **Found in:** Daily KPIs, Monthly KPIs
- **Good benchmark:** 10-20%
- **Why it matters:** Shows if bonuses are too expensive

#### Bonus Ratio (Deposits)
- **Definition:** Bonus cost as percentage of deposits
- **Formula:** `(Bonus Cost / Deposits) × 100`
- **Found in:** Daily KPIs, Monthly KPIs
- **Good benchmark:** 5-15%
- **Why it matters:** Alternative view of bonus cost efficiency

#### Payout %
- **Definition:** Percentage of bets returned to players as wins
- **Formula:** `((Cash Win + Promo Win) / (Cash Bet + Promo Bet)) × 100`
- **Found in:** Daily KPIs, Monthly KPIs
- **Typical range:** 92-98% (gaming industry standard)
- **Why it matters:** Player retention - too low = players leave, too high = unprofitable

#### % CashFlow to GGR
- **Definition:** Cash flow as percentage of GGR
- **Formula:** `(Cash Flow / GGR) × 100`
- **Found in:** Daily KPIs, Monthly KPIs
- **Why it matters:** Shows relationship between revenue and cash movement

---

## 🧮 Complete Formula Reference

### CTO-Approved Calculations (Current as of Nov 2025)

#### Revenue Calculations
```
GGR = (cash_bet + promo_bet) - (cash_win + promo_win)

Cash GGR = cash_bet - cash_win

Cash Bet = SUM(all cash wagers on withdrawable balance)

Cash Win = SUM(all cash wins credited to withdrawable balance)
```

#### Cost Calculations
```
Provider Fee = Cash GGR × 0.09 (9%)

Payment Fee = (Deposits + Withdrawals) × 0.08 (8%)

Platform Fee = Cash GGR × 0.01 (1%)

Bonus Cost = SUM(completed bonuses converted to cash)
```

#### Profitability Calculations
```
NGR = Cash GGR - Provider Fee - Payment Fee - Platform Fee - Bonus Cost

Simplified NGR = (Cash GGR × 0.90) - (Deposits + Withdrawals × 0.08) - Bonus Cost

LTV = NGR / FTD
```

#### Conversion & Ratio Calculations
```
Conversion Rate = (FTD / REG) × 100

Bonus Ratio (GGR) = (Bonus Cost / GGR) × 100

Bonus Ratio (Deposits) = (Bonus Cost / Deposits) × 100

Payout % = ((Cash Win + Promo Win) / (Cash Bet + Promo Bet)) × 100

% CashFlow to GGR = (Cash Flow / GGR) × 100
```

---

## 📊 Reading Cohort Reports

### Cohort Report Structure

All cohort reports follow this format:

| First Deposit Month | Month 0 | Month 1 | Month 2 | ... | Month 12 |
|---------------------|---------|---------|---------|-----|----------|
| January 2025        | 1,000   | 450     | 380     | ... | 120      |
| February 2025       | 1,200   | 520     | 420     | ... | 150      |
| March 2025          | 950     | 410     | ...     | ... | ...      |

**How to Read:**
- **Rows** = Cohorts (groups of players by first deposit month)
- **Columns** = Time periods after first deposit
- **Values** = Depend on report type (counts, amounts, or percentages)

### Interpreting Cohort Patterns

#### Healthy Cohort Pattern
```
Month 0: 100% (baseline)
Month 1: 40-50% (natural drop after first month)
Month 3: 25-35% (settling into regular players)
Month 6: 15-25% (loyal player base)
Month 12: 10-20% (very loyal players)
```

**What this means:** Good retention, players stay engaged

#### Warning Signs
```
Month 0: 100%
Month 1: 20% or less (too low - poor onboarding)
Month 3: <10% (players leaving quickly)
Month 6: <5% (severe retention problem)
```

**What this means:** Players not finding value, need to investigate

### Cohort Report Use Cases

#### Example 1: Evaluating a New Marketing Campaign
**Question:** "Did our January 2025 Facebook campaign bring quality players?"

**How to answer:**
1. Open **Depositors Cohort (%)** report
2. Filter: `start_date = 2025-01-01`, `end_date = 2025-01-31`
3. Look at January 2025 cohort row
4. Compare Month 1-6 retention vs. other cohorts
5. If retention is similar or better = successful campaign

#### Example 2: Regional Performance Analysis
**Question:** "Are German players more valuable than French players?"

**How to answer:**
1. Open **LTV Report**
2. Filter: `country = Germany`, check LTV value
3. Filter: `country = France`, check LTV value
4. Compare: Higher LTV = more valuable players
5. Also check: Deposit amounts, retention rates, GGR

#### Example 3: Measuring Bonus Program ROI
**Question:** "Is our bonus program profitable?"

**How to answer:**
1. Open **Daily KPIs** for last month
2. Check `Bonus Cost` (total cost)
3. Check `GGR` (total revenue)
4. Check `Bonus Ratio (GGR)` (cost as % of revenue)
5. If Bonus Ratio >20% = might be too expensive
6. Cross-check with `Conversion Rate` - are bonuses bringing depositors?

---

## 🎯 Best Practices for Stakeholders

### When Using Filters

✅ **DO:**
- Always exclude test accounts for business reporting
- Use consistent date ranges when comparing periods
- Filter by one currency at a time for financial analysis
- Document filters used in reports shared with executives

❌ **DON'T:**
- Mix multiple currencies in the same analysis
- Compare cohorts with different date ranges
- Forget to check if test accounts are excluded
- Use partial months for Monthly KPIs (wait for month to complete)

### When Analyzing Cohorts

✅ **DO:**
- Compare cohorts of similar sizes (don't compare 100 players vs. 10,000)
- Look for trends across multiple cohorts (not just one)
- Consider external factors (seasonality, campaigns, competitors)
- Wait at least 3 months before judging cohort performance

❌ **DON'T:**
- Draw conclusions from incomplete cohorts (need time to mature)
- Panic over one bad month (look for patterns)
- Compare Month 0 across cohorts (always 100% in % reports)
- Ignore outlier months (check for data quality issues)

### When Reporting to Executives

✅ **DO:**
- Use TOTAL rows in reports (aggregate view)
- Focus on LTV and NGR for profitability discussions
- Show month-over-month trends (not just absolute numbers)
- Explain anomalies before executives ask

❌ **DON'T:**
- Present raw data without context
- Change filter settings without noting it
- Cherry-pick best-looking cohorts
- Forget to mention report version (V2 formulas differ from V1)

---

## 🔧 Technical Changes Log (V1 → V2)

### What Changed and Why

#### 1. FTD Calculation Method (All Reports)
**Old Method:**
```sql
MIN(created_at) GROUP BY player_id
```
**Problem:** Could incorrectly identify first deposit in edge cases

**New Method:**
```sql
ROW_NUMBER() OVER (PARTITION BY player_id ORDER BY created_at ASC)
WHERE deposit_rank = 1
```
**Benefit:** Guaranteed accurate first deposit identification

**Impact:** FTD counts may differ slightly from V1 reports

---

#### 2. Currency Filtering (All Reports)
**Old Method:**
```sql
COALESCE(metadata->>'currency', cash_currency, wallet_currency, company_currency)
```
**Problem:** Complex, slow, inconsistent

**New Method:**
```sql
currency_type field (direct)
```
**Benefit:** Faster queries, consistent results

**Impact:** Simpler, more reliable currency filtering

---

#### 3. NGR Formula (LTV Report Only)
**Old Formula:**
```
NGR = GGR - Provider Fee - Payment Fee - Platform Fee
Net Revenue = NGR - Bonus Cost (separate metric)
```

**New Formula:**
```
NGR = Cash GGR - Provider Fee - Payment Fee - Platform Fee - Bonus Cost
```

**Key Changes:**
- Now uses **Cash GGR** instead of full GGR
- **Bonus Cost included** in NGR calculation
- **Net Revenue metric removed** (use NGR instead)

**Impact:** NGR values will be lower in V2 (bonus cost now subtracted)

---

#### 4. LTV Calculation (LTV Report Only)
**Old Calculation:**
```
Individual rows: Complex embedded formula
TOTAL row: Net Revenue / FTD
```

**New Calculation:**
```
Individual rows: NGR / FTD
TOTAL row: SUM(NGR) / SUM(FTD)
```

**Impact:**
- LTV values will differ from V1
- LTV now consistently uses NGR
- More accurate profitability per depositor

---

#### 5. New Column Added (LTV Report Only)
**Added:** Cash GGR column
- Position: After GGR column
- Purpose: Shows revenue used for fee calculations
- Helps understand difference between total GGR and cash-only GGR

---

### Migration Notes

**If you're comparing V1 and V2 reports:**

⚠️ **Do NOT directly compare these metrics between versions:**
- FTD (first-time depositor counts)
- NGR (Net Gaming Revenue)
- LTV (Lifetime Value)

✅ **Safe to compare between versions:**
- REG (Registrations)
- Deposits (amounts and counts)
- Withdrawals (amounts and counts)
- GGR (Gross Gaming Revenue)
- Bonus Cost

**Recommendation:** Use V2 as the new baseline. Historical V1 data should be noted as "legacy calculations."

---

## 📞 Getting Help

### Common Questions

**Q: Why do my FTD numbers differ from last month's report?**
A: If using V2 reports, FTD calculation method changed. V2 is more accurate. Use V2 going forward.

**Q: What's the difference between GGR and Cash GGR?**
A: GGR includes all gaming revenue (cash + promo bets). Cash GGR only counts real money bets. Use Cash GGR for profitability analysis.

**Q: Why is my LTV negative?**
A: NGR is negative (costs exceed revenue for that cohort). Common in early months or with aggressive bonus programs. Check Bonus Cost.

**Q: How long should I wait before evaluating a cohort?**
A: Minimum 3 months. Ideally 6-12 months for accurate LTV assessment.

**Q: Can I compare cohorts from different brands?**
A: Yes, but be aware of different operating costs, markets, and bonus strategies. Use LTV for fair comparison.

**Q: Which report should I use for board meetings?**
A: Monthly KPIs for high-level trends, LTV Report for profitability, Depositors Cohort (%) for retention story.

### Report-Specific Questions

**Daily KPIs:**
- Use for: Operational monitoring, spotting anomalies
- Frequency: Check daily or weekly
- Best for: Operations teams, marketing teams

**Monthly KPIs:**
- Use for: Trend analysis, executive reporting
- Frequency: Review monthly
- Best for: Executives, board presentations

**Cohort Reports:**
- Use for: Long-term player behavior, retention analysis
- Frequency: Review monthly or quarterly
- Best for: Product teams, retention strategies

**LTV Report:**
- Use for: Profitability analysis, investment decisions
- Frequency: Review monthly or quarterly
- Best for: Finance, executives, investors

---

## 📋 Quick Reference: Filter Combinations

### Common Use Cases

| Use Case | Filters to Apply | Reports to Use |
|----------|------------------|----------------|
| **Overall Business Health** | None (all data) | Monthly KPIs, LTV Report |
| **Specific Market Performance** | Country | All Reports |
| **Affiliate Evaluation** | Affiliate ID or Name | Daily/Monthly KPIs, LTV Report |
| **Campaign Effectiveness** | Start/End Date, Traffic Source | Cohort Reports (retention), LTV Report (profitability) |
| **Mobile vs Desktop** | Registration Launcher | All Reports |
| **Currency-Specific Analysis** | Currency Filter | All Reports |
| **Brand Comparison** | Brand (run report twice, once per brand) | All Reports |
| **Bonus Program ROI** | None | Bonus Report, Daily KPIs (bonus ratios) |

---

## ✅ Verification Checklist

Before presenting data to stakeholders, verify:

- [ ] Test accounts are excluded (`is_test_account = False`)
- [ ] Date range is complete (no partial months for monthly reports)
- [ ] Currency filter matches your analysis needs
- [ ] Using V2 reports (check formula documentation)
- [ ] Compared to previous periods for context
- [ ] Noted any filter changes from previous reports
- [ ] Explained any anomalies or outliers
- [ ] TOTAL row makes sense (not skewed by one outlier)

---

## 📅 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Oct 31, 2025 | Initial stakeholder guide |
| 2.0 | Nov 3, 2025 | Updated with CTO-approved formulas, new Cash GGR metric, aligned FTD logic across all 16 reports |

---

## 🎓 Glossary

**Cohort:** Group of players who made their first deposit in the same month

**FTD:** First-Time Depositor - player making their first ever deposit

**GGR:** Gross Gaming Revenue - total profit before costs

**Cash GGR:** GGR from only cash bets (excludes promotional bets)

**NGR:** Net Gaming Revenue - profit after all fees and costs

**LTV:** Lifetime Value - average profit per first-time depositor

**REG:** Registrations - new player accounts created

**Payout %:** Percentage of bets returned to players as winnings

**RTP:** Return to Player (same as Payout %)

**Balance Type:**
- **Withdrawable:** Real money that can be cashed out
- **Non-Withdrawable:** Bonus/promotional funds

**Transaction Categories:**
- **deposit:** Money added by player
- **withdrawal:** Money taken out by player
- **game_bet:** Wager placed on game
- **bonus:** Promotional funds activity
- **bonus_completion:** Bonus successfully converted to cash

---

**End of Stakeholder Guide V2**

*For technical documentation, see: TECHNICAL_REFERENCE_TABLE.md*
*For formula comparisons, see: DAILY_VS_MONTHLY_COMPARISON.md*
*For audit details, see: COHORT_AUDIT_REPORT.md*
