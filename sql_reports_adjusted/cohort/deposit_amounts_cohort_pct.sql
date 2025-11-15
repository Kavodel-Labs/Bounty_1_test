/* ============================================
   DEPOSIT AMOUNTS COHORT (%) - FINAL CORRECTED SQL
   Shows deposit amounts as percentage of Month 0 (as numbers)
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
    -- [FIXED] Aligned with your corrected sample to include data up to the present day.
    COALESCE((SELECT end_date FROM end_input), CURRENT_DATE) AS end_date
),

/* ---------- FILTERED PLAYERS (NO ALIASES for Field Filters) ---------- */
filtered_players AS (
  SELECT DISTINCT players.id AS player_id
  FROM players
  LEFT JOIN companies ON companies.id = players.company_id
  WHERE 1=1
    [[ AND {{brand}} ]]
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
    [[ AND CASE
           WHEN {{traffic_source}} = 'Organic'   THEN players.affiliate_id IS NULL
           WHEN {{traffic_source}} = 'Affiliate' THEN players.affiliate_id IS NOT NULL
           ELSE TRUE
         END ]]
    [[ AND {{affiliate_id}} ]]
    [[ AND {{affiliate_name}} ]]
    [[ AND CONCAT(players.os, ' / ', players.browser) = {{registration_launcher}} ]]
    [[ AND {{is_test_account}} ]]
),

/* Step 1: Identify first deposits with currency filter (ALIGNED WITH DAILY/MONTHLY) */
ftd_all_deposits AS (
  SELECT
    t.player_id,
    t.created_at,
    t.currency_type,
    ROW_NUMBER() OVER (PARTITION BY t.player_id ORDER BY t.created_at ASC) as deposit_rank
  FROM transactions t
  WHERE t.transaction_category = 'deposit'
    AND t.transaction_type = 'credit'
    AND t.status = 'completed'
),
first_deposits AS (
  SELECT
    fad.player_id,
    DATE_TRUNC('month', fad.created_at) as first_deposit_month,
    fad.created_at as first_deposit_date
  FROM ftd_all_deposits fad
  INNER JOIN filtered_players fp ON fad.player_id = fp.player_id
  WHERE fad.deposit_rank = 1
    AND fad.created_at >= (SELECT start_date FROM bounds)
    AND fad.created_at < (SELECT end_date FROM bounds) + INTERVAL '1 day'
    [[ AND CASE
      WHEN {{currency_filter}} != 'EUR'
      THEN UPPER(fad.currency_type) IN ({{currency_filter}})
      ELSE TRUE
    END ]]
),

/* Step 2: Calculate TOTAL DEPOSIT AMOUNTS for each cohort across months (ALIGNED WITH DAILY/MONTHLY) */
cohort_deposit_amounts AS (
  SELECT
    fd.first_deposit_month as cohort_month,
    DATE_TRUNC('month', t.created_at) as activity_month,
    SUM(CASE
      WHEN {{currency_filter}} = 'EUR'
      THEN COALESCE(t.eur_amount, t.amount)
      ELSE t.amount
    END) as total_deposit_amount,
    EXTRACT(YEAR FROM AGE(DATE_TRUNC('month', t.created_at), fd.first_deposit_month)) * 12 +
    EXTRACT(MONTH FROM AGE(DATE_TRUNC('month', t.created_at), fd.first_deposit_month)) as months_since_first_deposit
  FROM first_deposits fd
  INNER JOIN transactions t ON fd.player_id = t.player_id
  WHERE t.transaction_category = 'deposit'
    AND t.transaction_type = 'credit'
    AND t.balance_type = 'withdrawable'
    AND t.status = 'completed'
    AND t.created_at >= fd.first_deposit_date
    -- Apply same currency filter (ALIGNED WITH DAILY/MONTHLY)
    [[ AND CASE
      WHEN {{currency_filter}} != 'EUR'
      THEN UPPER(t.currency_type) IN ({{currency_filter}})
      ELSE TRUE
    END ]]
  GROUP BY fd.first_deposit_month, DATE_TRUNC('month', t.created_at)
),

/* Step 3: Get Month 0 amounts for baseline */
month_0_amounts AS (
  SELECT 
    cohort_month,
    total_deposit_amount as month_0_amount
  FROM cohort_deposit_amounts
  WHERE months_since_first_deposit = 0
)

/* Step 4: Pivot showing NUMERIC PERCENTAGES (no % symbol) */
SELECT 
  TO_CHAR(cda.cohort_month, 'Month YYYY') as "FIRST DEPOSIT MONTH",
  100::numeric as "Month 0",
  ROUND(MAX(CASE WHEN months_since_first_deposit = 1 THEN total_deposit_amount / NULLIF(m0.month_0_amount, 0) * 100 END), 1) as "Month 1",
  ROUND(MAX(CASE WHEN months_since_first_deposit = 2 THEN total_deposit_amount / NULLIF(m0.month_0_amount, 0) * 100 END), 1) as "Month 2",
  ROUND(MAX(CASE WHEN months_since_first_deposit = 3 THEN total_deposit_amount / NULLIF(m0.month_0_amount, 0) * 100 END), 1) as "Month 3",
  ROUND(MAX(CASE WHEN months_since_first_deposit = 4 THEN total_deposit_amount / NULLIF(m0.month_0_amount, 0) * 100 END), 1) as "Month 4",
  ROUND(MAX(CASE WHEN months_since_first_deposit = 5 THEN total_deposit_amount / NULLIF(m0.month_0_amount, 0) * 100 END), 1) as "Month 5",
  ROUND(MAX(CASE WHEN months_since_first_deposit = 6 THEN total_deposit_amount / NULLIF(m0.month_0_amount, 0) * 100 END), 1) as "Month 6",
  ROUND(MAX(CASE WHEN months_since_first_deposit = 7 THEN total_deposit_amount / NULLIF(m0.month_0_amount, 0) * 100 END), 1) as "Month 7",
  ROUND(MAX(CASE WHEN months_since_first_deposit = 8 THEN total_deposit_amount / NULLIF(m0.month_0_amount, 0) * 100 END), 1) as "Month 8",
  ROUND(MAX(CASE WHEN months_since_first_deposit = 9 THEN total_deposit_amount / NULLIF(m0.month_0_amount, 0) * 100 END), 1) as "Month 9",
  ROUND(MAX(CASE WHEN months_since_first_deposit = 10 THEN total_deposit_amount / NULLIF(m0.month_0_amount, 0) * 100 END), 1) as "Month 10",
  ROUND(MAX(CASE WHEN months_since_first_deposit = 11 THEN total_deposit_amount / NULLIF(m0.month_0_amount, 0) * 100 END), 1) as "Month 11",
  ROUND(MAX(CASE WHEN months_since_first_deposit = 12 THEN total_deposit_amount / NULLIF(m0.month_0_amount, 0) * 100 END), 1) as "Month 12"
FROM cohort_deposit_amounts cda
JOIN month_0_amounts m0 ON cda.cohort_month = m0.cohort_month
WHERE months_since_first_deposit <= 12
GROUP BY cda.cohort_month
ORDER BY cda.cohort_month;

--------------
