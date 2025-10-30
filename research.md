# Metabase Research: Best Practices for Models, Filters, and Dashboard Design

## Table of Contents
1. [Models vs. Saved Questions vs. Snippets](#models-vs-saved-questions-vs-snippets)
2. [Creating and Using Models](#creating-and-using-models)
3. [SQL Parameters and Field Filters](#sql-parameters-and-field-filters)
4. [SQL Snippets for Code Reuse](#sql-snippets-for-code-reuse)
5. [Performance Optimization](#performance-optimization)
6. [Dashboard Design Best Practices](#dashboard-design-best-practices)
7. [Metrics and Naming Conventions](#metrics-and-naming-conventions)
8. [Application to Current BTB Reports](#application-to-current-btb-reports)

---

## Models vs. Saved Questions vs. Snippets

### When to Use Each

**Snippets:**
- Use for **small, commonly used fragments of SQL**
- Ideal for codifying KPIs like revenue calculations or defining active users
- Should be short, reusable lines of SQL (WHERE clauses, JOINs, common calculations)
- Perfect for DRY (Don't Repeat Yourself) principles
- Examples: currency resolution logic, filtered_players CTE, date boundary calculations

**Saved Questions:**
- Use for any code that you'd want to execute by itself
- Queries that return complete result sets
- Can be referenced in other SQL queries using `{{#question_name}}` syntax
- Good for queries that are useful standalone but also referenced elsewhere

**Models:**
- Use to give people good starting datasets for new questions
- Makes it easy for non-technical people to ask questions about your data
- Based on SQL or query builder questions with custom calculated columns
- The "secret sauce" is metadata - tells Metabase what kind of data it's returning
- Enables non-SQL users to explore data with the query builder

### Key Advantages

**Models:**
- Don't require variables for dashboard filters (once column types are defined)
- Provide better starting points for non-technical users compared to raw database tables
- Can include custom, calculated columns
- Support typeahead search for referencing: `{{#your search term}}`

**Snippets:**
- Centralized updates - edit once, changes propagate to all questions using it
- Promotes consistency across queries
- Saves time by avoiding rewriting the same code
- ⚠️ **Warning:** If you break a snippet, you break every question using it - test thoroughly!

---

## Creating and Using Models

### Model Creation Process

1. **Base your model on:**
   - SQL query (more flexible, but requires manual metadata)
   - Query builder question (Metabase fills out metadata automatically)

2. **Metadata is critical:**
   - Without metadata, Metabase can display results but can't "know" the data types
   - With proper metadata, people can explore results with query builder
   - Manually define column types, descriptions, and display settings for SQL-based models

3. **Referencing models in SQL:**
```sql
-- Use typeahead search with # prefix
SELECT * FROM {{#model_name}}

-- Works in CTEs too
WITH base_data AS (
  SELECT * FROM {{#revenue_model}}
)
SELECT ...
```

### Best Practices for Models

- Focus on creating clean, well-structured starting datasets
- Include commonly needed calculated columns
- Document column meanings in metadata
- Consider non-technical users when designing model outputs
- Models should represent "truth tables" that other queries can build upon

---

## SQL Parameters and Field Filters

### Two Types of Variables

#### 1. Field Filter Variables (Preferred)

**Syntax:**
```sql
-- Note: NO column name or operator in WHERE clause
WHERE 1=1
  [[ AND {{brand}} ]]           -- Field Filter (Metabase generates SQL)
  [[ AND {{country}} ]]
```

**Why use Field Filters:**
- Creates "smart" filter widgets (date pickers, dropdown menus)
- Metabase generates the proper SQL for you
- Handles NULL values and multiple selections automatically
- Required for dashboard filter integration
- Better user experience with appropriate widget types

**Setup steps:**
1. Add variable to WHERE clause using `[[ AND {{variable_name}} ]]`
2. Set Variable type to "Field Filter"
3. Map variable to a database field (e.g., Products → Category)
4. Configure filter widget appearance and defaults

#### 2. Basic Variables

**Types:**
- Text
- Number
- Date

**When to use:**
- Simple value substitution where field filters won't work
- Custom logic that doesn't map to a single database field

**Syntax:**
```sql
WHERE column_name = {{text_variable}}
AND date_column >= {{start_date}}
```

### Dashboard Integration

**Requirements:**
- SQL questions must contain at least one variable/parameter to work with dashboard filters
- Field filter type determines compatible dashboard filter types
- Variables must be properly mapped to database fields

**Current Implementation Analysis:**
The BTB reports use field filters correctly:
```sql
[[ AND {{brand}} ]]                    -- Companies.name field filter
[[ AND {{country}} ]]                  -- Country code mapping
[[ AND {{registration_launcher}} ]]   -- Device/browser filter
[[ AND {{currency_filter}} ]]         -- Currency selection
```

---

## SQL Snippets for Code Reuse

### What Makes a Good Snippet?

**Characteristics:**
- Short and focused (not entire queries)
- Reusable across multiple questions
- Stable logic that rarely changes
- Commonly used patterns (JOINs, WHERE clauses, calculations)

### Use Cases for BTB Reports

1. **Currency Resolution Logic:**
```sql
-- Snippet name: currency_resolution
UPPER(COALESCE(
  t.metadata->>'currency',
  t.cash_currency,
  players.wallet_currency,
  companies.currency
))
```

2. **Filtered Players Base:**
```sql
-- Snippet name: filtered_players_base
SELECT DISTINCT players.id AS player_id
FROM players
LEFT JOIN companies ON companies.id = players.company_id
WHERE 1=1
  [[ AND {{brand}} ]]
  [[ AND players.country = {{country_case}} ]]
  [[ AND {{traffic_source_logic}} ]]
  -- etc.
```

3. **Date Bounds Logic:**
```sql
-- Snippet name: daily_bounds
COALESCE((SELECT MAX(end_date) FROM end_input), CURRENT_DATE) AS end_date_raw,
(SELECT MAX(start_date) FROM start_input) AS start_date_raw
```

### Important Considerations

⚠️ **Testing is Critical:**
- Test snippets thoroughly before saving
- Broken snippet = broken questions using it
- Consider versioning or staging environment for snippet changes

**When NOT to use snippets:**
- Long code blocks that are queries themselves (use Saved Questions instead)
- Code that returns complete result sets (save as a question)
- Highly variable logic that changes frequently

---

## Performance Optimization

### Materialized Views Strategy

**What they are:**
- Pre-computed query results stored in the database
- Can be indexed for faster access
- Refreshed periodically to balance freshness and performance

**When to use:**
- Large datasets with complex aggregations
- Dashboard queries that run frequently
- Reports with consistent time-consuming computations
- Peak traffic periods

**Implementation approach for BTB:**
```sql
-- Create materialized view for daily player metrics
CREATE MATERIALIZED VIEW player_daily_metrics AS
SELECT
  player_id,
  DATE_TRUNC('day', transaction_date) as activity_date,
  SUM(CASE WHEN category = 'deposit' ...) as deposits,
  SUM(CASE WHEN category = 'withdrawal' ...) as withdrawals,
  -- etc.
FROM transactions
WHERE status = 'completed'
GROUP BY player_id, DATE_TRUNC('day', transaction_date);

-- Refresh strategy
REFRESH MATERIALIZED VIEW player_daily_metrics;
```

**Benefits:**
- Eliminates redundant full table scans on `transactions` table
- Dramatically speeds up KPI reports (could be 40-60x faster)
- Reduces database load during peak usage
- Queries become simpler - just SELECT from summary table

**Trade-offs:**
- Consumes database storage
- Requires refresh strategy (schedule or manual)
- Data freshness lag (refresh frequency vs. performance)
- Initial creation time for large datasets

### Caching Strategies

**Metabase Caching Levels:**

1. **Database level** (applies to all questions from that database)
2. **Question level** (specific saved question)
3. **Dashboard level** (all questions on dashboard)

**How it works:**
- Cached results stored in application database (self-hosted) or Metabase servers (cloud)
- Subsequent identical queries return cached results
- Cache duration configurable on paid plans
- Model caching speeds up model loading with pre-computed results

**Recommendations for BTB:**
- Set dashboard cache duration to 1 hour for executive dashboards
- Set individual question cache to 15-30 minutes for KPI reports
- Disable caching for real-time operational reports
- Monitor cache hit rates and adjust durations

### Query Optimization Techniques

**1. Aggregate with Summary Tables:**
- Create intermediate summary tables for common aggregations
- Pre-compute metrics at daily or monthly level
- Query summary tables instead of raw transactions

**2. Denormalize for Performance:**
- Flatten nested JSON structures if queried frequently
- Store commonly joined data together
- Balance normalization vs. query performance

**3. Indexing Strategy:**
```sql
-- Essential indexes for BTB reports
CREATE INDEX idx_transactions_player_created
  ON transactions(player_id, created_at);

CREATE INDEX idx_transactions_category_status
  ON transactions(transaction_category, status);

CREATE INDEX idx_players_company_country
  ON players(company_id, country);
```

**4. SQL Performance Tuning:**
- Use `EXPLAIN ANALYZE` to identify bottlenecks
- Avoid SELECT * - specify only needed columns
- Use FILTER clauses instead of multiple CASE statements
- Optimize CTEs - sometimes better to use subqueries or temp tables

**5. Reduce Data Volume:**
- Apply filters as early as possible in query execution
- Use date partitioning for large transaction tables
- Archive old data if not needed for analysis

---

## Dashboard Design Best Practices

### Design Principles

**1. Tailor to Decision-Making:**
- Focus on decisions your audience can act on
- Talk to teams about daily, weekly, monthly decisions they need to make
- Remove metrics that don't drive action

**2. Prioritize Key Metrics:**
- Avoid information overload
- Put most important metrics at top
- Use size and position to indicate importance

**3. Clear and Concise Labels:**
- Use business language, not technical jargon
- Make metric names self-explanatory
- Include context (time period, comparison basis)

**4. Logical Layout:**
- Guide viewer through data with visual flow
- Group related metrics together
- Use color coding for different metric categories

**Example for BTB:**
- 🟢 Green: Registration and Acquisition metrics
- 🔵 Blue: Deposit and Financial metrics
- 🟣 Purple: Gaming and Activity metrics
- 🟡 Yellow: Retention and Cohort metrics

### Dashboard Organization

**When to split dashboards:**
- Too many questions slow loading times
- Different audiences need different views
- Mixing operational and executive metrics

**Use custom click behavior:**
- Link dashboard cards to detailed dashboards
- Create drill-down paths from summary to detail
- Build dashboard navigation hierarchies

**Example Structure for BTB:**
```
Executive Dashboard (high-level KPIs)
  ├─> Registration & Acquisition Dashboard
  ├─> Deposit & Revenue Dashboard
  ├─> Gaming Activity Dashboard
  └─> Cohort & Retention Dashboard
```

### Dashboard Performance

**Optimization techniques:**
- Limit number of cards per dashboard (aim for < 15)
- Use filters to segment data rather than multiple cards
- Cache frequently accessed dashboards
- Pre-aggregate data in database before querying

---

## Metrics and Naming Conventions

### Defining Official Metrics

**What are Metabase Metrics:**
- Pre-defined calculations that standardize how metrics are calculated
- Prevent "five different calculations for the same metric" problem
- Define the official way to calculate important numbers for your team
- Based on query builder (not SQL) but can reference SQL models

**Benefits:**
- Consistency across all reports
- One place to update calculation logic
- Prevents interpretation errors
- Builds trust in data

### Naming Convention Best Practices

**Principles:**

1. **Be Descriptive but Concise:**
   - Good: `registrations_count`, `ftd_conversion_pct`
   - Bad: `#Registrations`, `REG`, `Conversion`

2. **Use Consistent Patterns:**
   ```
   {metric}_{type}_{modifier}

   Examples:
   - deposit_amount_total
   - player_count_active
   - conversion_pct_ftd
   - retention_pct_m1
   ```

3. **Suffix Conventions:**
   - `_count` - counting records
   - `_amount` - monetary values
   - `_pct` - percentages (store as numbers, format in Metabase)
   - `_rate` - ratios
   - `_avg` - averages
   - `_sum` - summed values

4. **Time Period Prefixes:**
   - Avoid: "Monthly Revenue" if metric can be viewed at different granularities
   - Instead: "Revenue" (then slice by time dimension as needed)
   - Use: `ltv_m1`, `ltv_m3`, `ltv_m6` for specific time-locked metrics

5. **Avoid Special Characters:**
   - No: `#`, `%`, spaces, punctuation
   - Yes: underscores, alphanumeric
   - Makes querying easier, prevents API issues

**Recommended Naming for BTB Reports:**

Current → Recommended
```
"#Registrations"           → registrations_count
"#FTDs"                    → ftd_count
"%Conversion total reg"    → conversion_pct_total_reg
"Deposits Amount"          → deposit_amount_total
"Unique Depositors"        → depositors_count_unique
"GGR"                      → ggr_amount
"Active Players"           → players_count_active
"Bonus Cost"               → bonus_cost_amount
"Bonus Ratio (GGR)"        → bonus_cost_pct_of_ggr
"%CashFlow to GGR"         → cashflow_pct_of_ggr
```

---

## Application to Current BTB Reports

### Identified Opportunities

Based on the analysis of the existing reports and the review recommendations, here are specific Metabase improvements to implement:

#### 1. Create Reusable Snippets

**High Priority Snippets:**

```sql
-- Snippet: currency_filter_cascade
-- Description: Standard currency resolution logic
UPPER(COALESCE(
  t.metadata->>'currency',
  t.cash_currency,
  players.wallet_currency,
  companies.currency
))

-- Snippet: player_filter_joins
-- Description: Standard joins for player filtering
LEFT JOIN companies ON companies.id = players.company_id

-- Snippet: country_code_mapping
-- Description: Full country name to ISO code mapping
CASE {{country}}
  WHEN 'Romania' THEN 'RO'
  WHEN 'France' THEN 'FR'
  -- ... (full mapping)
END

-- Snippet: ftd_transaction_filters
-- Description: Standard FTD identification filters
WHERE t.transaction_category = 'deposit'
  AND t.transaction_type = 'credit'
  AND t.status = 'completed'
  AND t.balance_type = 'withdrawable'
```

#### 2. Create Base Models

**Model: filtered_players_base**
- Purpose: Pre-filtered player list based on dashboard filters
- Output: player_id, company_id, registration_date, country, device, etc.
- Metadata: All fields properly typed and described
- Usage: Reference in all reports as starting point

**Model: daily_transactions_summary**
- Purpose: Pre-aggregated daily transaction metrics per player
- Output: player_id, date, deposits, withdrawals, bets, wins, etc.
- Metadata: Monetary fields as currency, dates as date types
- Usage: Dramatically speeds up KPI reports

#### 3. Standardize Filter Implementation

**Current Issues:**
- Device filter inconsistency: `players.os` vs `CONCAT(players.os, ' / ', players.browser)`
- Date parameter naming: `{{start_month}}` vs `{{start_date}}`

**Solution:**
```sql
-- Standardize across ALL queries:
[[ AND CONCAT(players.os, ' / ', players.browser) = {{registration_launcher}} ]]
[[ AND {{start_date}} ]]
[[ AND {{end_date}} ]]
```

#### 4. Implement Column Naming Standard

**Create SQL Templates with Standard Names:**

All reports should output columns following this pattern:
```sql
SELECT
  -- Dimension columns
  report_date,
  cohort_month,

  -- Count metrics
  registrations_count,
  ftd_count,
  depositors_count_unique,
  players_count_active,

  -- Amount metrics
  deposit_amount_total,
  withdrawal_amount_total,
  ggr_amount,
  bonus_cost_amount,

  -- Percentage metrics (as numbers)
  conversion_pct_total_reg,
  conversion_pct_complete_reg,
  ftd_pct_new,
  ftd_pct_old,
  retention_pct_m1,

  -- Derived metrics
  cashflow_amount,
  revenue_amount_net
FROM ...
```

#### 5. Dashboard Reorganization

**Proposed Structure:**

**Dashboard 1: Executive KPIs** (Top-level)
- Daily and Monthly summary TOTAL rows only
- Key metrics cards: Registrations, FTDs, GGR, Revenue
- Links to detailed dashboards

**Dashboard 2: Daily Performance** (Operational)
- Full daily KPI report with trends
- Filter by brand, country, device, currency
- Cache: 30 minutes

**Dashboard 3: Monthly Trends** (Strategic)
- Full monthly KPI report
- YoY comparisons
- Cache: 1 hour

**Dashboard 4: Cohort Analysis Hub** (Retention)
- Tabs or links to all cohort reports
- Unified filters across all cohort views
- Visual retention heatmaps

**Dashboard 5: LTV & Profitability** (Finance)
- Cohort LTV analysis
- Bonus efficiency metrics
- Profitability by segment

#### 6. Performance Improvements

**Immediate:**
- Add indexes on frequently filtered columns
- Use `FILTER` clauses instead of nested `CASE` statements
- Apply filters in `filtered_players` CTE first

**Short-term:**
- Create materialized view: `mv_player_daily_metrics`
- Schedule refresh every hour
- Refactor KPI reports to use materialized view

**Long-term:**
- Partition `transactions` table by date
- Archive transactions older than 2 years to separate table
- Implement incremental refresh for materialized views

---

## Recommendations Summary

### Critical (Do First)

1. **Fix filter inconsistencies** - standardize device filter and date parameters
2. **Create SQL snippets** - for currency resolution, player filtering, transaction filters
3. **Standardize naming** - implement consistent column naming across all reports
4. **Add TOTAL rows** - to all cohort reports (currently missing)

### Important (This Month)

5. **Create base models** - filtered_players_base, daily_transactions_summary
6. **Implement caching** - configure appropriate cache durations for dashboards
7. **Add indexes** - on player_id, created_at, transaction_category, company_id
8. **Reorganize dashboards** - create executive/operational/strategic hierarchy

### Strategic (Ongoing)

9. **Build materialized views** - for high-traffic reports
10. **Document metrics** - create data dictionary with official definitions
11. **Establish SQL standards** - coding guidelines and review process
12. **Monitor performance** - track query times and optimize slow queries

---

## Resources

- [Metabase Documentation - Models](https://www.metabase.com/docs/latest/data-modeling/models)
- [Metabase Learn - SQL Snippets](https://www.metabase.com/learn/metabase-basics/querying-and-dashboards/sql-in-metabase/snippets)
- [Metabase Learn - Field Filters](https://www.metabase.com/learn/metabase-basics/querying-and-dashboards/sql-in-metabase/field-filters)
- [Metabase Learn - Making Dashboards Faster](https://www.metabase.com/learn/metabase-basics/administration/administration-and-operation/making-dashboards-faster)
- [Metabase Learn - BI Dashboard Best Practices](https://www.metabase.com/learn/metabase-basics/querying-and-dashboards/dashboards/bi-dashboard-best-practices)

---

*Document created: 2025-10-30*
*For: BTB Gaming Analytics Dashboard Standardization Project*
