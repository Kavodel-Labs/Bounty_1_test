/* ============================================
   CASH PLAYERS COHORT (%) - NUMERIC VERSION FOR CONDITIONAL FORMATTING
   Shows retention percentages as numbers (Metabase will format as %)
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

/* Step 1: Identify first cash bets with currency filter (ALIGNED WITH DAILY/MONTHLY) */
fcb_all_bets AS (
  SELECT
    t.player_id,
    t.created_at,
    t.currency_type,
    ROW_NUMBER() OVER (PARTITION BY t.player_id ORDER BY t.created_at ASC) as bet_rank
  FROM transactions t
  WHERE t.transaction_category = 'game_bet'
    AND t.transaction_type = 'debit'
    AND t.balance_type = 'withdrawable'
    AND t.status = 'completed'
),
first_cash_bets AS (
  SELECT
    fab.player_id,
    DATE_TRUNC('month', fab.created_at) as first_cash_bet_month,
    fab.created_at as first_cash_bet_date
  FROM fcb_all_bets fab
  INNER JOIN filtered_players fp ON fab.player_id = fp.player_id
  WHERE fab.bet_rank = 1
    AND fab.created_at >= (SELECT start_date FROM bounds)
    AND fab.created_at < (SELECT end_date FROM bounds) + INTERVAL '1 day'
    [[ AND CASE
      WHEN {{currency_filter}} != 'EUR'
      THEN UPPER(fab.currency_type) IN ({{currency_filter}})
      ELSE TRUE
    END ]]
),

/* Step 2: Calculate cohort sizes */
cohort_sizes AS (
  SELECT 
    first_cash_bet_month as cohort_month,
    COUNT(DISTINCT player_id) as cohort_size
  FROM first_cash_bets
  GROUP BY first_cash_bet_month
),

/* Step 3: Track activity for each cohort (ALIGNED WITH DAILY/MONTHLY) */
cohort_activity AS (
  SELECT
    fcb.first_cash_bet_month as cohort_month,
    DATE_TRUNC('month', t.created_at) as activity_month,
    COUNT(DISTINCT t.player_id) as active_players
  FROM first_cash_bets fcb
  INNER JOIN transactions t ON fcb.player_id = t.player_id
  WHERE t.transaction_category = 'game_bet'
    AND t.transaction_type = 'debit'
    AND t.balance_type = 'withdrawable'
    AND t.status = 'completed'
    AND t.created_at >= fcb.first_cash_bet_date
    -- Apply same currency filter (ALIGNED WITH DAILY/MONTHLY)
    [[ AND CASE
      WHEN {{currency_filter}} != 'EUR'
      THEN UPPER(t.currency_type) IN ({{currency_filter}})
      ELSE TRUE
    END ]]
  GROUP BY fcb.first_cash_bet_month, DATE_TRUNC('month', t.created_at)
),

/* Step 4: Calculate retention */
cohort_retention AS (
  SELECT 
    ca.cohort_month,
    ca.activity_month,
    ca.active_players,
    cs.cohort_size,
    EXTRACT(YEAR FROM AGE(ca.activity_month, ca.cohort_month)) * 12 + 
    EXTRACT(MONTH FROM AGE(ca.activity_month, ca.cohort_month)) as months_since_first_bet
  FROM cohort_activity ca
  INNER JOIN cohort_sizes cs ON ca.cohort_month = cs.cohort_month
  WHERE EXTRACT(YEAR FROM AGE(ca.activity_month, ca.cohort_month)) * 12 + 
        EXTRACT(MONTH FROM AGE(ca.activity_month, ca.cohort_month)) <= 12
)

/* Step 5: Pivot showing NUMERIC PERCENTAGES (no % symbol for conditional formatting) */
SELECT 
  TO_CHAR(cohort_month, 'Month YYYY') as "FIRST CASH BET MONTH",
  100::numeric as "Month 0",
  ROUND(MAX(CASE WHEN months_since_first_bet = 1 THEN active_players::numeric / NULLIF(cohort_size, 0) * 100 END), 1) as "Month 1",
  ROUND(MAX(CASE WHEN months_since_first_bet = 2 THEN active_players::numeric / NULLIF(cohort_size, 0) * 100 END), 1) as "Month 2",
  ROUND(MAX(CASE WHEN months_since_first_bet = 3 THEN active_players::numeric / NULLIF(cohort_size, 0) * 100 END), 1) as "Month 3",
  ROUND(MAX(CASE WHEN months_since_first_bet = 4 THEN active_players::numeric / NULLIF(cohort_size, 0) * 100 END), 1) as "Month 4",
  ROUND(MAX(CASE WHEN months_since_first_bet = 5 THEN active_players::numeric / NULLIF(cohort_size, 0) * 100 END), 1) as "Month 5",
  ROUND(MAX(CASE WHEN months_since_first_bet = 6 THEN active_players::numeric / NULLIF(cohort_size, 0) * 100 END), 1) as "Month 6",
  ROUND(MAX(CASE WHEN months_since_first_bet = 7 THEN active_players::numeric / NULLIF(cohort_size, 0) * 100 END), 1) as "Month 7",
  ROUND(MAX(CASE WHEN months_since_first_bet = 8 THEN active_players::numeric / NULLIF(cohort_size, 0) * 100 END), 1) as "Month 8",
  ROUND(MAX(CASE WHEN months_since_first_bet = 9 THEN active_players::numeric / NULLIF(cohort_size, 0) * 100 END), 1) as "Month 9",
  ROUND(MAX(CASE WHEN months_since_first_bet = 10 THEN active_players::numeric / NULLIF(cohort_size, 0) * 100 END), 1) as "Month 10",
  ROUND(MAX(CASE WHEN months_since_first_bet = 11 THEN active_players::numeric / NULLIF(cohort_size, 0) * 100 END), 1) as "Month 11",
  ROUND(MAX(CASE WHEN months_since_first_bet = 12 THEN active_players::numeric / NULLIF(cohort_size, 0) * 100 END), 1) as "Month 12"
FROM cohort_retention
GROUP BY cohort_month, cohort_size
ORDER BY cohort_month;

---------
