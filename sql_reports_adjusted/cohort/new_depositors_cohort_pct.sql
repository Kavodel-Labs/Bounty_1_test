/* ============================================
   NEW DEPOSITORS COHORT - PERCENTAGE DISTRIBUTION
   Shows percentage of new depositors by EXACT deposit frequency in their cohort month
   One row per month within user-selected date range
   New Depositor = first_ever_deposit in that specific month
   
   LOGIC: Count deposits WITHIN the cohort month only
   - "1 time" = EXACTLY 1 deposit in that month
   - "2 times" = EXACTLY 2 deposits in that month
   - Each FTD appears in ONE column only
   - Row total = 100%
   - Column totals = percentage distribution across all months
   
   FILTERS: Brand, Country, Traffic Source, Affiliate, Registration Launcher, Test Account, Currency
   PARAMETERS: start_date, end_date (DATE), currency_filter, brand, country, traffic_source, affiliate_id, affiliate_name, registration_launcher, is_test_account
   ============================================ */

WITH

/* --- Date range inputs (user-selectable) --- */
start_input AS (
  SELECT NULL::date AS start_date WHERE FALSE
  [[ UNION ALL SELECT {{start_date}}::date ]]
),
end_input AS (
  SELECT NULL::date AS end_date WHERE FALSE
  [[ UNION ALL SELECT {{end_date}}::date ]]
),

/* --- Normalize analysis window (defaults to last 12 months if not specified) --- */
analysis_period AS (
  SELECT 
    COALESCE(
      (SELECT start_date FROM start_input),
      (SELECT DATE_TRUNC('month', MAX(created_at) - INTERVAL '11 months')::date FROM transactions)
    ) AS month_start,
    COALESCE(
      (SELECT end_date FROM end_input),
      (SELECT DATE_TRUNC('month', MAX(created_at))::date FROM transactions)
    ) AS month_end
),

/* --- Get all months in the analysis period --- */
available_months AS (
  SELECT DATE_TRUNC('month', d)::date AS month_start
  FROM GENERATE_SERIES(
    (SELECT month_start FROM analysis_period),
    (SELECT month_end FROM analysis_period),
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

/* Step 1: Find first deposit date and identify FTD cohort month */
player_first_deposit AS (
  SELECT 
    transactions.player_id,
    MIN(transactions.created_at) as first_deposit_date,
    DATE_TRUNC('month', MIN(transactions.created_at))::date AS cohort_month
  FROM transactions
  INNER JOIN filtered_players ON transactions.player_id = filtered_players.player_id
  JOIN players ON players.id = transactions.player_id
  JOIN companies ON companies.id = players.company_id
  WHERE transactions.transaction_category = 'deposit'
    AND transactions.transaction_type = 'credit'
    AND transactions.balance_type = 'withdrawable'
    AND transactions.status = 'completed'
    -- Currency filter using standard hierarchy
    [[ AND UPPER(COALESCE(
           transactions.metadata->>'currency',
           transactions.cash_currency,
           players.wallet_currency,
           companies.currency
         )) IN ({{currency_filter}}) ]]
  GROUP BY transactions.player_id
),

/* Step 2: Count deposits WITHIN the cohort month for each FTD */
ftd_deposit_counts AS (
  SELECT 
    pfd.cohort_month,
    pfd.player_id,
    COUNT(*) as deposits_in_cohort_month
  FROM player_first_deposit pfd
  INNER JOIN transactions t ON pfd.player_id = t.player_id
  WHERE t.transaction_category = 'deposit'
    AND t.transaction_type = 'credit'
    AND t.balance_type = 'withdrawable'
    AND t.status = 'completed'
    AND DATE_TRUNC('month', t.created_at)::date = pfd.cohort_month
    -- Apply same currency filter
    [[ AND UPPER(COALESCE(
           t.metadata->>'currency',
           t.cash_currency,
           (SELECT wallet_currency FROM players WHERE id = pfd.player_id),
           (SELECT currency FROM companies WHERE id = (SELECT company_id FROM players WHERE id = pfd.player_id))
         )) IN ({{currency_filter}}) ]]
  GROUP BY pfd.cohort_month, pfd.player_id
),

/* Step 3: Calculate EXACT bucket distribution for each month */
monthly_bucket_counts AS (
  SELECT
    cohort_month,
    COUNT(CASE WHEN deposits_in_cohort_month = 1 THEN 1 END) as bucket_1,
    COUNT(CASE WHEN deposits_in_cohort_month = 2 THEN 1 END) as bucket_2,
    COUNT(CASE WHEN deposits_in_cohort_month = 3 THEN 1 END) as bucket_3,
    COUNT(CASE WHEN deposits_in_cohort_month = 4 THEN 1 END) as bucket_4,
    COUNT(CASE WHEN deposits_in_cohort_month = 5 THEN 1 END) as bucket_5,
    COUNT(CASE WHEN deposits_in_cohort_month = 6 THEN 1 END) as bucket_6,
    COUNT(CASE WHEN deposits_in_cohort_month >= 7 THEN 1 END) as bucket_7_plus,
    COUNT(*) as total_cohort
  FROM ftd_deposit_counts
  GROUP BY cohort_month
),

/* Step 4: Calculate column totals (sum of counts across all months) */
column_totals AS (
  SELECT
    NULL::date as cohort_month,
    SUM(bucket_1) as bucket_1,
    SUM(bucket_2) as bucket_2,
    SUM(bucket_3) as bucket_3,
    SUM(bucket_4) as bucket_4,
    SUM(bucket_5) as bucket_5,
    SUM(bucket_6) as bucket_6,
    SUM(bucket_7_plus) as bucket_7_plus,
    SUM(total_cohort) as total_cohort
  FROM monthly_bucket_counts
),

/* Step 5: Union monthly data with totals row */
all_rows AS (
  SELECT 
    cohort_month,
    bucket_1,
    bucket_2,
    bucket_3,
    bucket_4,
    bucket_5,
    bucket_6,
    bucket_7_plus,
    total_cohort,
    0 as sort_order
  FROM monthly_bucket_counts
  
  UNION ALL
  
  SELECT 
    cohort_month,
    bucket_1,
    bucket_2,
    bucket_3,
    bucket_4,
    bucket_5,
    bucket_6,
    bucket_7_plus,
    total_cohort,
    1 as sort_order
  FROM column_totals
)

/* Final Output - Monthly data with percentages and totals row */
SELECT 
  CASE 
    WHEN cohort_month IS NULL THEN 'TOTALS'
    ELSE TO_CHAR(cohort_month, 'FMMonth YYYY')
  END as "Month",
  ROUND(bucket_1::numeric / NULLIF(total_cohort, 0) * 100, 1) as "1 time",
  ROUND(bucket_2::numeric / NULLIF(total_cohort, 0) * 100, 1) as "2 times",
  ROUND(bucket_3::numeric / NULLIF(total_cohort, 0) * 100, 1) as "3 times",
  ROUND(bucket_4::numeric / NULLIF(total_cohort, 0) * 100, 1) as "4 times",
  ROUND(bucket_5::numeric / NULLIF(total_cohort, 0) * 100, 1) as "5 times",
  ROUND(bucket_6::numeric / NULLIF(total_cohort, 0) * 100, 1) as "6 times",
  ROUND(bucket_7_plus::numeric / NULLIF(total_cohort, 0) * 100, 1) as "7+ times",
  ROUND((bucket_1 + bucket_2 + bucket_3 + bucket_4 + bucket_5 + bucket_6 + bucket_7_plus)::numeric / NULLIF(total_cohort, 0) * 100, 1) as "Total"
FROM all_rows
ORDER BY CASE WHEN sort_order = 1 THEN 1 ELSE 0 END DESC, 
         cohort_month DESC;

-------------
