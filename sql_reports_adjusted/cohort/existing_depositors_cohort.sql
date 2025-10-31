/* ============================================
   EXISTING DEPOSITORS COHORT - PRODUCTION QUERY
   Full dataset aggregation by months with complete filter suite
   Shows unique count of existing depositors by EXACT deposit frequency within each month
   One row per month across entire available data
   
   Existing Depositor = first_ever_deposit BEFORE that month
   Deposit count = EXACT number of deposits made DURING each month
   
   LOGIC: Count deposits WITHIN the month only
   - "1 deposit" = EXACTLY 1 deposit in that month
   - "2 deposits" = EXACTLY 2 deposits in that month
   - Each depositor appears in ONE column only
   - Row total = unique active existing depositors that month
   - Column totals = sum across all months
   
   FILTERS: Brand, Country, Traffic Source, Affiliate, Registration Launcher, Test Account, Currency
   DATE RANGE: Optional start_date and end_date (defaults to all available data)
   PARAMETERS: start_date, end_date, currency_filter, brand, country, traffic_source, affiliate_id, affiliate_name, registration_launcher, is_test_account
   ============================================ */

WITH

/* --- Optional inputs: empty by default, 1 row when provided --- */
start_input AS (
  SELECT NULL::date AS start_date WHERE FALSE
  [[ UNION ALL SELECT {{start_date}}::date ]]
),
end_input AS (
  SELECT NULL::date AS end_date WHERE FALSE
  [[ UNION ALL SELECT {{end_date}}::date ]]
),

/* --- Normalize window (no inputs → all available data) --- */
bounds_raw AS (
  SELECT  
    COALESCE((SELECT MAX(end_date) FROM end_input), CURRENT_DATE) AS end_date_raw,
    (SELECT MAX(start_date) FROM start_input) AS start_date_raw
),
bounds AS (
  SELECT  
    end_date_raw AS end_date,
    /* default start = beginning of all data; if user set start, use it */
    CASE
      WHEN start_date_raw IS NULL THEN (SELECT MIN(DATE_TRUNC('month', created_at))::date FROM transactions WHERE transaction_category = 'deposit')
      WHEN start_date_raw > end_date_raw THEN end_date_raw
      ELSE start_date_raw
    END AS start_date  
  FROM bounds_raw
),

/* --- Step 1: Get all months in analysis period --- */
all_months AS (
  SELECT DISTINCT DATE_TRUNC('month', d)::date AS month_start
  FROM generate_series(
         (SELECT start_date FROM bounds),
         (SELECT end_date FROM bounds),
         INTERVAL '1 month'
       ) AS d
),

/* ---------- FILTERED PLAYERS (NO ALIASES for Field Filters) ---------- */
filtered_players AS (
  SELECT DISTINCT players.id AS player_id
  FROM players
  LEFT JOIN companies ON companies.id = players.company_id
  WHERE 1=1
    [[ AND {{brand}} ]]              -- Field Filter → Companies.name
    [[ AND players.country = CASE {{country}}
    WHEN 'Romania' THEN 'RO'
    WHEN 'France' THEN 'FR'
    WHEN 'Germany' THEN 'DE'
    WHEN 'Cyprus' THEN 'CY'
    WHEN 'Poland' THEN 'PL'
    WHEN 'Spain' THEN 'ES'
    WHEN 'Italy' THEN 'IT'
    WHEN 'Canada' THEN 'CA'
    WHEN 'Australia' THEN 'AU'
    WHEN 'United Kingdom' THEN 'GB'
    WHEN 'Finland' THEN 'FI'
    WHEN 'Albania' THEN 'AL'
    WHEN 'Austria' THEN 'AT'
    WHEN 'Belgium' THEN 'BE'
    WHEN 'Brazil' THEN 'BR'
    WHEN 'Bulgaria' THEN 'BG'
    WHEN 'Georgia' THEN 'GE'
    WHEN 'Greece' THEN 'GR'
    WHEN 'Hungary' THEN 'HU'
    WHEN 'India' THEN 'IN'
    WHEN 'Netherlands' THEN 'NL'
    WHEN 'Portugal' THEN 'PT'
    WHEN 'Singapore' THEN 'SG'
    WHEN 'Turkey' THEN 'TR'
    WHEN 'United Arab Emirates' THEN 'AE'
    WHEN 'Afghanistan' THEN 'AF'
    WHEN 'Armenia' THEN 'AM'
    WHEN 'Denmark' THEN 'DK'
    WHEN 'Algeria' THEN 'DZ'
    WHEN 'Andorra' THEN 'AD'
    END ]]

    -- Text/Category variables (optional)
    [[ AND CASE
           WHEN {{traffic_source}} = 'Organic'   THEN players.affiliate_id IS NULL
           WHEN {{traffic_source}} = 'Affiliate' THEN players.affiliate_id IS NOT NULL
           ELSE TRUE
         END ]]
    [[ AND {{affiliate_id}} ]]
    [[ AND {{affiliate_name}} ]]
    [[ AND CONCAT(players.os, ' / ', players.browser) = {{registration_launcher}} ]]

    -- TEST ACCOUNT as a Field Filter → Players.is_test_account (boolean)
    [[ AND {{is_test_account}} ]]
),

/* Step 2: Identify first deposit date for all filtered players --- */
player_first_deposit AS (
  SELECT 
    transactions.player_id,
    MIN(transactions.created_at) as first_deposit_date
  FROM transactions
  INNER JOIN filtered_players fp ON transactions.player_id = fp.player_id
  JOIN players ON players.id = transactions.player_id
  JOIN companies ON companies.id = players.company_id
  WHERE transactions.transaction_category = 'deposit'
    AND transactions.transaction_type = 'credit'
    AND transactions.balance_type = 'withdrawable'
    AND transactions.status = 'completed'
    AND transactions.created_at >= (SELECT start_date FROM bounds)
    AND transactions.created_at < (SELECT end_date FROM bounds) + INTERVAL '1 day'
    -- Currency filter using standard hierarchy
    [[ AND UPPER(COALESCE(
           transactions.metadata->>'currency',
           transactions.cash_currency,
           players.wallet_currency,
           companies.currency
         )) IN ({{currency_filter}}) ]]
  GROUP BY transactions.player_id
),

/* --- Step 3: Filter to EXISTING DEPOSITORS for each month --- */
/* Existing = first deposit occurred BEFORE the month being analyzed */
existing_depositors_by_month AS (
  SELECT 
    am.month_start,
    pfd.player_id,
    pfd.first_deposit_date
  FROM all_months am
  CROSS JOIN player_first_deposit pfd
  INNER JOIN filtered_players fp ON pfd.player_id = fp.player_id
  WHERE pfd.first_deposit_date < am.month_start
),

/* --- Step 4: Count deposits per existing depositor per month with currency filter --- */
monthly_deposit_counts AS (
  SELECT 
    edbm.month_start,
    edbm.player_id,
    COUNT(*) as deposits_in_month
  FROM existing_depositors_by_month edbm
  INNER JOIN transactions t ON edbm.player_id = t.player_id
  JOIN players ON players.id = t.player_id
  JOIN companies ON companies.id = players.company_id
  WHERE t.transaction_category = 'deposit'
    AND t.transaction_type = 'credit'
    AND t.balance_type = 'withdrawable'
    AND t.status = 'completed'
    AND DATE_TRUNC('month', t.created_at)::date = edbm.month_start
    -- Currency filter using standard hierarchy
    [[ AND UPPER(COALESCE(
           t.metadata->>'currency',
           t.cash_currency,
           players.wallet_currency,
           companies.currency
         )) IN ({{currency_filter}}) ]]
  GROUP BY edbm.month_start, edbm.player_id
),

/* --- Step 5: Calculate EXACT bucket distribution for each month --- */
monthly_bucket_counts AS (
  SELECT
    month_start,
    -- EXACT deposit count buckets
    COUNT(CASE WHEN deposits_in_month = 1 THEN 1 END) as bucket_1,
    COUNT(CASE WHEN deposits_in_month = 2 THEN 1 END) as bucket_2,
    COUNT(CASE WHEN deposits_in_month = 3 THEN 1 END) as bucket_3,
    COUNT(CASE WHEN deposits_in_month = 4 THEN 1 END) as bucket_4,
    COUNT(CASE WHEN deposits_in_month = 5 THEN 1 END) as bucket_5,
    COUNT(CASE WHEN deposits_in_month = 6 THEN 1 END) as bucket_6,
    COUNT(CASE WHEN deposits_in_month >= 7 THEN 1 END) as bucket_7_plus,
    -- Total active existing depositors
    COUNT(*) as total_active
  FROM monthly_deposit_counts
  GROUP BY month_start
),

/* --- Step 6: Calculate column totals --- */
column_totals AS (
  SELECT
    NULL::date as month_start,
    SUM(bucket_1) as bucket_1,
    SUM(bucket_2) as bucket_2,
    SUM(bucket_3) as bucket_3,
    SUM(bucket_4) as bucket_4,
    SUM(bucket_5) as bucket_5,
    SUM(bucket_6) as bucket_6,
    SUM(bucket_7_plus) as bucket_7_plus,
    SUM(total_active) as total_active
  FROM monthly_bucket_counts
),

/* --- Step 7: Union monthly data with totals row --- */
all_rows AS (
  SELECT 
    month_start,
    bucket_1,
    bucket_2,
    bucket_3,
    bucket_4,
    bucket_5,
    bucket_6,
    bucket_7_plus,
    total_active,
    0 as sort_order
  FROM monthly_bucket_counts
  WHERE total_active > 0  -- Exclude empty months
  
  UNION ALL
  
  SELECT 
    month_start,
    bucket_1,
    bucket_2,
    bucket_3,
    bucket_4,
    bucket_5,
    bucket_6,
    bucket_7_plus,
    total_active,
    1 as sort_order
  FROM column_totals
)

/* --- Final Output: Monthly data with totals row --- */
SELECT 
  CASE 
    WHEN month_start IS NULL THEN 'TOTALS'
    ELSE TO_CHAR(month_start, 'FMMonth YYYY')
  END as "Month",
  bucket_1 as "1 deposit",
  bucket_2 as "2 deposits",
  bucket_3 as "3 deposits",
  bucket_4 as "4 deposits",
  bucket_5 as "5 deposits",
  bucket_6 as "6 deposits",
  bucket_7_plus as "7+ deposits",
  total_active as "Total Active Existing Depositors"
FROM all_rows
ORDER BY CASE WHEN sort_order = 1 THEN 1 ELSE 0 END DESC, 
         month_start DESC;

--------------------

/* ============================================
