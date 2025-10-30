# BTB Gaming Analytics - SQL Reports

This directory contains all SQL reports for the BTB gaming analytics dashboard, extracted and organized from the original `Business Overview_full sql_BTB_11.md` file.

## Directory Structure

```
sql_reports/
├── kpi/              # Key Performance Indicator reports
├── cohort/           # Cohort analysis reports
├── ltv/              # Lifetime Value reports
└── README.md         # This file
```

---

## Report Catalog

### KPI Reports (2)

#### 1. Daily KPIs (`kpi/daily_kpis.sql`)
**Description:** Multi-day KPI view with TOTAL summary row
**Time Granularity:** Daily
**Output Columns:**
- Date, Registrations, FTDs (New/Old/D0/Late), Conversion rates
- Deposits, Withdrawals, CashFlow
- Active Players, Betting metrics (Cash/Promo Bet/Win)
- GGR, Bonus metrics, Payout %, Revenue

**Parameters:**
- `{{start_date}}` - Start date (defaults to 31 days ago)
- `{{end_date}}` - End date (defaults to today)
- `{{brand}}` - Company/brand filter
- `{{country}}` - Country filter
- `{{registration_launcher}}` - Device (OS / Browser)
- `{{currency_filter}}` - Currency codes
- `{{traffic_source}}` - Organic/Affiliate
- `{{affiliate_id}}` - Specific affiliate ID
- `{{affiliate_name}}` - Affiliate name
- `{{is_test_account}}` - Include/exclude test accounts

**Features:**
- TOTAL row with proper unique counts
- Date series with daily buckets
- Currency resolution cascade
- Comprehensive filtering

---

#### 2. Monthly KPIs (`kpi/monthly_kpis.sql`)
**Description:** Multi-month KPI view with TOTAL summary row
**Time Granularity:** Monthly
**Output Columns:** Same as Daily KPIs but aggregated by month
**Parameters:** Same as Daily KPIs

**Features:**
- TOTAL row with accurate monthly aggregations
- Month series generation
- Same metric calculations as daily report

**Known Issues:**
- ⚠️ Device filter uses `players.os` instead of `CONCAT(players.os, ' / ', players.browser)` - needs standardization
- See ACTION_PLAN.md Phase 1 for fix

---

### Cohort Reports (12)

All cohort reports track player behavior over time since their first action (first deposit or registration).

#### 3. Cash Players Cohort (`cohort/cash_players_cohort.sql`)
**Description:** Count of cash balance active players by cohort over 12 months
**Cohort Definition:** First cash game activity month
**Output:** Absolute player counts for Month 0-12
**Features:** Shows retention of cash-playing players

---

#### 4. Cash Players Cohort (%) (`cohort/cash_players_cohort_pct.sql`)
**Description:** Percentage retention of cash players by cohort
**Cohort Definition:** First cash game activity month
**Output:** Percentage values (Month 0 = 100%)
**Features:** Month 0 always 100, subsequent months show % retained

---

#### 5. Cash Bet Amount Cohort (`cohort/cash_bet_amount_cohort.sql`)
**Description:** Total cash bet amounts by cohort over 12 months
**Cohort Definition:** First cash game activity month
**Output:** Absolute bet amounts for Month 0-12
**Features:** Shows betting volume trends by cohort

---

#### 6. Cash Bet Amounts Cohort (%) (`cohort/cash_bet_amounts_cohort_pct.sql`)
**Description:** Cash bet amounts as percentage of Month 0
**Cohort Definition:** First cash game activity month
**Output:** Percentage of Month 0 bet amount
**Features:** Month 0 = 100%, shows relative betting trends

---

#### 7. Depositors Cohort (`cohort/depositors_cohort.sql`)
**Description:** Count of active depositors by cohort over 12 months
**Cohort Definition:** First deposit month
**Output:** Absolute depositor counts for Month 0-12
**Features:** Shows deposit retention patterns

---

#### 8. Depositors Cohort (%) (`cohort/depositors_cohort_pct.sql`)
**Description:** Percentage retention of depositors
**Cohort Definition:** First deposit month
**Output:** Percentage values (Month 0 = 100%)
**Features:** Classic retention cohort view

---

#### 9. Deposit Amounts Cohort (`cohort/deposit_amounts_cohort.sql`)
**Description:** Total deposit amounts by cohort over 12 months
**Cohort Definition:** First deposit month
**Output:** Absolute deposit amounts for Month 0-12
**Features:** Shows deposit volume by cohort age

---

#### 10. Deposit Amounts Cohort (%) (`cohort/deposit_amounts_cohort_pct.sql`)
**Description:** Deposit amounts as percentage of Month 0
**Cohort Definition:** First deposit month
**Output:** Percentage of Month 0 deposit amount
**Features:** Shows relative deposit trends over cohort lifetime

---

#### 11. New Depositors Cohort (`cohort/new_depositors_cohort.sql`)
**Description:** Count of players making first deposit by registration cohort
**Cohort Definition:** Registration month (not first deposit month)
**Output:** Absolute counts of FTDs from each registration cohort
**Features:** Tracks conversion timing by registration cohort

**Known Issues:**
- ⚠️ Date parameters use `{{start_month}}` and `{{end_month}}` instead of standard `{{start_date}}/{{end_date}}`
- ⚠️ Device filter uses `players.os` instead of `CONCAT` pattern
- See ACTION_PLAN.md Phase 1 for fixes

---

#### 12. New Depositors Cohort - Percentage (`cohort/new_depositors_cohort_pct.sql`)
**Description:** Percentage of registrations becoming depositors by cohort
**Cohort Definition:** Registration month
**Output:** Conversion percentages
**Features:** Shows FTD conversion efficiency by registration cohort

**Known Issues:** Same as New Depositors Cohort (#11)

---

#### 13. Existing Depositors Cohort (`cohort/existing_depositors_cohort.sql`)
**Description:** Count of depositors who made additional deposits
**Cohort Definition:** First deposit month
**Output:** Count of repeat depositors Month 0-12
**Features:** Tracks deposit frequency/repeat behavior

---

#### 14. Existing Depositors Cohort % (`cohort/existing_depositors_cohort_pct.sql`)
**Description:** Percentage of cohort making repeat deposits
**Cohort Definition:** First deposit month
**Output:** Percentage making subsequent deposits
**Features:** Measures deposit stickiness

---

### LTV Reports (1)

#### 15. Cohort LTV Lifetime Report (`ltv/cohort_ltv_lifetime.sql`)
**Description:** Comprehensive lifetime value analysis by registration cohort
**Cohort Definition:** Registration month
**Time Granularity:** Lifetime (all-time since registration)

**Output Columns:**
- `month_year` - Registration month
- `REG` - Total registrations
- `FTD` - First-time depositors
- `conversion_rate` - FTD/REG ratio
- `ltv` - Average deposits per FTD
- `deposit` - Total deposits
- `wd` - Total withdrawals
- `ggr` - Gross Gaming Revenue
- `ngr` - Net Gaming Revenue (= GGR in this platform)
- `bonus_cost` - Total bonus cost
- `revenue` - Net revenue (GGR - bonus cost)

**Features:**
- TOTAL row with aggregated metrics
- Includes all lifetime activity per cohort
- Comprehensive profitability view

---

## Common Parameters

All reports support these filter parameters (unless noted otherwise):

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `{{start_date}}` | Date | Start of analysis period | 2024-01-01 |
| `{{end_date}}` | Date | End of analysis period | 2024-12-31 |
| `{{brand}}` | Field Filter | Company/brand name | Companies.name |
| `{{country}}` | Field Filter | Player country (mapped to ISO codes) | 'Romania' → 'RO' |
| `{{registration_launcher}}` | Field Filter | Device (OS / Browser) | 'iOS / Safari' |
| `{{currency_filter}}` | Text | Currency codes (comma-separated) | 'EUR', 'USD' |
| `{{traffic_source}}` | Text | Player acquisition source | 'Organic', 'Affiliate' |
| `{{affiliate_id}}` | Field Filter | Specific affiliate ID | Players.affiliate_id |
| `{{affiliate_name}}` | Field Filter | Affiliate name | Affiliates.name |
| `{{is_test_account}}` | Field Filter | Include/exclude test accounts | Players.is_test_account |

---

## Architecture Notes

### Currency Resolution Cascade

All reports use a consistent 4-level cascade for currency:
```sql
COALESCE(
  t.metadata->>'currency',     -- Transaction override
  t.cash_currency,             -- Transaction default
  players.wallet_currency,     -- Player account default
  companies.currency           -- Company default
)
```

### Filtered Players Pattern

Most reports start with a `filtered_players` CTE:
```sql
filtered_players AS (
  SELECT DISTINCT players.id AS player_id
  FROM players
  LEFT JOIN companies ON companies.id = players.company_id
  WHERE 1=1
    [[ AND {{brand}} ]]
    [[ AND {{country}} ]]
    -- ... other filters
)
```

This CTE is then INNER JOINed throughout the query to ensure all metrics respect the user's filter selections.

### Date Bounds Logic

Reports use sophisticated default date handling:
- Daily KPIs: Default to last 31 days
- Monthly KPIs: Default to last 12 months
- Cohort reports: Default to last 12 months of cohorts

Users can override with `{{start_date}}` and `{{end_date}}` parameters.

---

## Known Issues & Standardization Needs

See `ACTION_PLAN.md` for comprehensive list. Key issues:

### Critical (Phase 1)
1. **Device Filter Inconsistency**
   - Most reports: `CONCAT(players.os, ' / ', players.browser)`
   - Monthly KPIs & New Depositors Cohort: `players.os` only
   - **Impact:** Filter returns wrong data

2. **Date Parameter Naming**
   - New Depositors Cohort reports: `{{start_month}}`, `{{end_month}}`
   - All other reports: `{{start_date}}`, `{{end_date}}`
   - **Impact:** Dashboard filter doesn't wire correctly

3. **Bonus Metrics Ambiguity**
   - "Bonus Converted" and "Bonus Cost" use identical calculations
   - **Impact:** Stakeholder confusion on true bonus cost

### High Priority (Phase 2)
4. **Inconsistent Column Naming**
   - Examples: `#Registrations`, `REG`, `total_registrations`
   - **Impact:** Hard to query, confusing to users

5. **Missing TOTAL Rows**
   - Daily/Monthly KPIs have TOTAL rows
   - All 12 cohort reports missing TOTAL rows
   - **Impact:** Users must manually aggregate

### Medium Priority (Phase 3)
6. **Code Duplication**
   - `filtered_players` CTE duplicated in ~14 queries
   - Currency resolution duplicated ~30+ times
   - **Impact:** Maintenance burden, risk of inconsistency

---

## Usage in Metabase

### Import Process

1. Create new Native Query in Metabase
2. Copy contents of desired `.sql` file
3. Configure parameters (map Field Filters to database columns)
4. Save as Question or Model
5. Add to dashboard

### Parameter Mapping

When creating Field Filters in Metabase:

| Parameter | Map To | Widget Type |
|-----------|--------|-------------|
| `{{brand}}` | Companies → name | Dropdown |
| `{{country}}` | Players → country | Dropdown (with ISO mapping) |
| `{{registration_launcher}}` | Players → Custom (OS / Browser) | Dropdown |
| `{{currency_filter}}` | - | Text input |
| `{{traffic_source}}` | - | Dropdown (Organic/Affiliate) |
| `{{affiliate_id}}` | Players → affiliate_id | Dropdown |
| `{{is_test_account}}` | Players → is_test_account | Toggle |

---

## Optimization Opportunities

See `research.md` and `ACTION_PLAN.md` for detailed recommendations:

1. **Create SQL Snippets**
   - Currency resolution logic
   - Filtered players CTE
   - Country code mapping
   - FTD transaction filters

2. **Create Metabase Models**
   - `filtered_players_base` model
   - `player_daily_metrics` summary table

3. **Add Database Indexes**
   - `transactions(player_id, created_at)`
   - `transactions(transaction_category, status, balance_type)`
   - `players(company_id, country)`

4. **Consider Materialized Views**
   - Pre-aggregate daily metrics
   - 10-40x performance improvement potential

---

## File Naming Convention

```
{metric_type}_{variant}.sql

Examples:
- daily_kpis.sql
- monthly_kpis.sql
- depositors_cohort.sql
- depositors_cohort_pct.sql
- cash_players_cohort.sql
```

---

## Maintenance

### When Updating Reports

1. Update the source `.sql` file in this directory
2. Test thoroughly with all filter combinations
3. Update this README if adding new reports or changing parameters
4. Follow SQL Standards (see `SQL_STANDARDS.md` when created)
5. Submit for code review before deploying to Metabase
6. Update Metabase question from updated SQL file

### Adding New Reports

1. Determine category (KPI / Cohort / LTV / Other)
2. Create file in appropriate subdirectory
3. Follow naming convention
4. Use standard header comment (see ACTION_PLAN.md)
5. Reuse common patterns (filtered_players, currency resolution, etc.)
6. Add entry to this README
7. Test before deploying

---

## Related Documentation

- **ACTION_PLAN.md** - Comprehensive standardization roadmap
- **research.md** - Metabase best practices and optimization strategies
- **gai.md** - Original GAI analysis and recommendations
- **claude review.md** - Claude's review and phased implementation plan

---

## Questions or Issues?

For questions about:
- **Report logic:** See inline SQL comments
- **Standardization:** See ACTION_PLAN.md
- **Metabase features:** See research.md
- **Bug reports:** Check ACTION_PLAN.md Known Issues section first

---

*Last Updated: October 30, 2025*
*Total Reports: 15 (2 KPI, 12 Cohort, 1 LTV)*
*Status: Extracted from Business Overview - Ready for standardization*
