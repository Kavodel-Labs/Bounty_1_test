/* ============================================
   DEPOSIT AMOUNTS COHORT - ALIGNED WITH DAILY/MONTHLY FILTERS
   Shows total deposit amounts by cohort over time
   ============================================ */

WITH
/* --- Optional date inputs for cohort window --- */
start_input AS (
  SELECT NULL::date AS start_date WHERE FALSE
  [[ UNION ALL SELECT {{start_date}}::date ]]
),
end_input AS (
  SELECT NULL::date AS end_date WHERE FALSE
  [[ UNION ALL SELECT {{end_date}}::date ]]
),

/* --- Normalize cohort window (default: last 12 months through TODAY) --- */
bounds AS (
  SELECT
    COALESCE((SELECT start_date FROM start_input), 
             DATE_TRUNC('month', CURRENT_DATE - INTERVAL '12 months')) AS start_date,
    COALESCE((SELECT end_date FROM end_input), CURRENT_DATE) AS end_date
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

/* Step 1: Identify first deposits with currency filter */
first_deposits AS (
  SELECT 
    t.player_id,
    DATE_TRUNC('month', MIN(t.created_at)) as first_deposit_month,
    MIN(t.created_at) as first_deposit_date
  FROM transactions t
  INNER JOIN filtered_players fp ON t.player_id = fp.player_id
  JOIN players ON players.id = t.player_id
  JOIN companies ON companies.id = players.company_id
  WHERE t.transaction_category = 'deposit' 
    AND t.transaction_type = 'credit' 
    AND t.balance_type = 'withdrawable'
    AND t.status = 'completed'
    -- Apply cohort date bounds
    AND t.created_at >= (SELECT start_date FROM bounds)
    AND t.created_at < (SELECT end_date FROM bounds) + INTERVAL '1 day'
    -- Currency filter using same resolution as daily/monthly
    [[ AND UPPER(COALESCE(
           t.metadata->>'currency',
           t.cash_currency,
           players.wallet_currency,
           companies.currency
         )) IN ({{currency_filter}}) ]]
  GROUP BY t.player_id
),

/* Step 2: Calculate cohort sizes (for reference) */
cohort_sizes AS (
  SELECT 
    first_deposit_month as cohort_month,
    COUNT(DISTINCT player_id) as cohort_size
  FROM first_deposits
  GROUP BY first_deposit_month
),

/* Step 3: Calculate TOTAL DEPOSIT AMOUNTS for each cohort across months */
cohort_deposit_amounts AS (
  SELECT 
    fd.first_deposit_month as cohort_month,
    DATE_TRUNC('month', t.created_at) as activity_month,
    SUM(CASE 
      WHEN {{currency_filter}} = 'EUR' 
      THEN COALESCE(t.eur_amount, t.amount)
      ELSE t.amount 
    END) as total_deposit_amount,
    COUNT(t.id) as total_deposits,
    COUNT(DISTINCT t.player_id) as unique_depositors
  FROM first_deposits fd
  INNER JOIN transactions t ON fd.player_id = t.player_id
  JOIN players ON players.id = t.player_id
  JOIN companies ON companies.id = players.company_id
  WHERE t.transaction_category = 'deposit' 
    AND t.transaction_type = 'credit' 
    AND t.balance_type = 'withdrawable'
    AND t.status = 'completed'
    AND t.created_at >= fd.first_deposit_date
    -- Apply same currency filter
    [[ AND UPPER(COALESCE(
           t.metadata->>'currency',
           t.cash_currency,
           players.wallet_currency,
           companies.currency
         )) IN ({{currency_filter}}) ]]
  GROUP BY fd.first_deposit_month, DATE_TRUNC('month', t.created_at)
),

/* Step 4: Calculate months since first deposit */
cohort_retention AS (
  SELECT 
    cda.cohort_month,
    cda.activity_month,
    cda.total_deposit_amount,
    cda.total_deposits,
    cda.unique_depositors,
    cs.cohort_size,
    EXTRACT(YEAR FROM AGE(cda.activity_month, cda.cohort_month)) * 12 + 
    EXTRACT(MONTH FROM AGE(cda.activity_month, cda.cohort_month)) as months_since_first_deposit
  FROM cohort_deposit_amounts cda
  INNER JOIN cohort_sizes cs ON cda.cohort_month = cs.cohort_month
  WHERE EXTRACT(YEAR FROM AGE(cda.activity_month, cda.cohort_month)) * 12 + 
        EXTRACT(MONTH FROM AGE(cda.activity_month, cda.cohort_month)) <= 12
)

/* Step 5: Pivot showing NUMERIC AMOUNTS ONLY */
SELECT 
  TO_CHAR(cohort_month, 'Month YYYY') as "FIRST DEPOSIT MONTH",
  ROUND(MAX(CASE WHEN months_since_first_deposit = 0 THEN total_deposit_amount END), 2) as "Month 0",
  ROUND(MAX(CASE WHEN months_since_first_deposit = 1 THEN total_deposit_amount END), 2) as "Month 1",
  ROUND(MAX(CASE WHEN months_since_first_deposit = 2 THEN total_deposit_amount END), 2) as "Month 2",
  ROUND(MAX(CASE WHEN months_since_first_deposit = 3 THEN total_deposit_amount END), 2) as "Month 3",
  ROUND(MAX(CASE WHEN months_since_first_deposit = 4 THEN total_deposit_amount END), 2) as "Month 4",
  ROUND(MAX(CASE WHEN months_since_first_deposit = 5 THEN total_deposit_amount END), 2) as "Month 5",
  ROUND(MAX(CASE WHEN months_since_first_deposit = 6 THEN total_deposit_amount END), 2) as "Month 6",
  ROUND(MAX(CASE WHEN months_since_first_deposit = 7 THEN total_deposit_amount END), 2) as "Month 7",
  ROUND(MAX(CASE WHEN months_since_first_deposit = 8 THEN total_deposit_amount END), 2) as "Month 8",
  ROUND(MAX(CASE WHEN months_since_first_deposit = 9 THEN total_deposit_amount END), 2) as "Month 9",
  ROUND(MAX(CASE WHEN months_since_first_deposit = 10 THEN total_deposit_amount END), 2) as "Month 10",
  ROUND(MAX(CASE WHEN months_since_first_deposit = 11 THEN total_deposit_amount END), 2) as "Month 11",
  ROUND(MAX(CASE WHEN months_since_first_deposit = 12 THEN total_deposit_amount END), 2) as "Month 12"
FROM cohort_retention
GROUP BY cohort_month
ORDER BY cohort_month;

----------------------
