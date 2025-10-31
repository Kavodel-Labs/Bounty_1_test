/* ============================================
   CASH BET AMOUNTS COHORT (%) - NUMERIC VERSION FOR CONDITIONAL FORMATTING
   Shows bet amounts as percentage of Month 0 (as numbers)
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

/* Step 1: Identify first cash bets with currency filter */
first_cash_bets AS (
  SELECT 
    t.player_id,
    DATE_TRUNC('month', MIN(t.created_at)) as first_cash_bet_month,
    MIN(t.created_at) as first_cash_bet_date
  FROM transactions t
  INNER JOIN filtered_players fp ON t.player_id = fp.player_id
  JOIN players ON players.id = t.player_id
  JOIN companies ON companies.id = players.company_id
  WHERE t.transaction_category = 'game_bet' 
    AND t.transaction_type = 'debit' 
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

/* Step 2: Calculate TOTAL BET AMOUNTS for each cohort across months */
cohort_bet_amounts AS (
  SELECT 
    fcb.first_cash_bet_month as cohort_month,
    DATE_TRUNC('month', t.created_at) as activity_month,
    SUM(ABS(CASE 
      WHEN {{currency_filter}} = 'EUR' 
      THEN COALESCE(t.eur_amount, t.amount)
      ELSE t.amount 
    END)) as total_amount_wagered,
    EXTRACT(YEAR FROM AGE(DATE_TRUNC('month', t.created_at), fcb.first_cash_bet_month)) * 12 + 
    EXTRACT(MONTH FROM AGE(DATE_TRUNC('month', t.created_at), fcb.first_cash_bet_month)) as months_since_first_bet
  FROM first_cash_bets fcb
  INNER JOIN transactions t ON fcb.player_id = t.player_id
  JOIN players ON players.id = t.player_id
  JOIN companies ON companies.id = players.company_id
  WHERE t.transaction_category = 'game_bet' 
    AND t.transaction_type = 'debit' 
    AND t.balance_type = 'withdrawable'
    AND t.status = 'completed'
    AND t.created_at >= fcb.first_cash_bet_date
    -- Apply same currency filter
    [[ AND UPPER(COALESCE(
           t.metadata->>'currency',
           t.cash_currency,
           players.wallet_currency,
           companies.currency
         )) IN ({{currency_filter}}) ]]
  GROUP BY fcb.first_cash_bet_month, DATE_TRUNC('month', t.created_at)
),

/* Step 3: Get Month 0 amounts for baseline */
month_0_amounts AS (
  SELECT 
    cohort_month,
    total_amount_wagered as month_0_amount
  FROM cohort_bet_amounts
  WHERE months_since_first_bet = 0
)

/* Step 4: Pivot showing NUMERIC PERCENTAGES (no % symbol) */
SELECT 
  TO_CHAR(cba.cohort_month, 'Month YYYY') as "FIRST CASH BET MONTH",
  100::numeric as "Month 0",  -- Always 100 for Month 0
  ROUND(MAX(CASE WHEN months_since_first_bet = 1 THEN total_amount_wagered / NULLIF(m0.month_0_amount, 0) * 100 END), 1) as "Month 1",
  ROUND(MAX(CASE WHEN months_since_first_bet = 2 THEN total_amount_wagered / NULLIF(m0.month_0_amount, 0) * 100 END), 1) as "Month 2",
  ROUND(MAX(CASE WHEN months_since_first_bet = 3 THEN total_amount_wagered / NULLIF(m0.month_0_amount, 0) * 100 END), 1) as "Month 3",
  ROUND(MAX(CASE WHEN months_since_first_bet = 4 THEN total_amount_wagered / NULLIF(m0.month_0_amount, 0) * 100 END), 1) as "Month 4",
  ROUND(MAX(CASE WHEN months_since_first_bet = 5 THEN total_amount_wagered / NULLIF(m0.month_0_amount, 0) * 100 END), 1) as "Month 5",
  ROUND(MAX(CASE WHEN months_since_first_bet = 6 THEN total_amount_wagered / NULLIF(m0.month_0_amount, 0) * 100 END), 1) as "Month 6",
  ROUND(MAX(CASE WHEN months_since_first_bet = 7 THEN total_amount_wagered / NULLIF(m0.month_0_amount, 0) * 100 END), 1) as "Month 7",
  ROUND(MAX(CASE WHEN months_since_first_bet = 8 THEN total_amount_wagered / NULLIF(m0.month_0_amount, 0) * 100 END), 1) as "Month 8",
  ROUND(MAX(CASE WHEN months_since_first_bet = 9 THEN total_amount_wagered / NULLIF(m0.month_0_amount, 0) * 100 END), 1) as "Month 9",
  ROUND(MAX(CASE WHEN months_since_first_bet = 10 THEN total_amount_wagered / NULLIF(m0.month_0_amount, 0) * 100 END), 1) as "Month 10",
  ROUND(MAX(CASE WHEN months_since_first_bet = 11 THEN total_amount_wagered / NULLIF(m0.month_0_amount, 0) * 100 END), 1) as "Month 11",
  ROUND(MAX(CASE WHEN months_since_first_bet = 12 THEN total_amount_wagered / NULLIF(m0.month_0_amount, 0) * 100 END), 1) as "Month 12"
FROM cohort_bet_amounts cba
JOIN month_0_amounts m0 ON cba.cohort_month = m0.cohort_month
WHERE months_since_first_bet <= 12
GROUP BY cba.cohort_month
ORDER BY cba.cohort_month;


-------------
