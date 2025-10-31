COHORT LTV LIFETIME REPORT - FINAL CORRECTED SQL
Gaming/Casino Platform Analytics - WITH REVISED CALCULATIONS
=============================================================================
* FIX 1: Bulletproof Currency Logic - All monetary calculations now use the CASE statement for EUR conversion and handle NULLs.
* FIX 2: Correct Hierarchical Sorting - The report now sorts with TOTAL on top, followed by the latest months.
* FIX 3: All other filters (device, etc.) are standardized.
*/

WITH 
/**
---------------------------------------------------------------------------
STEP 1: DATE BOUNDS - Determine reporting window
---------------------------------------------------------------------------
*/
start_input AS (
  SELECT NULL::date AS start_date WHERE FALSE
  [[ UNION ALL SELECT {{start_date}}::date ]]
),
end_input AS (
  SELECT NULL::date AS end_date WHERE FALSE
  [[ UNION ALL SELECT {{end_date}}::date ]]
),
bounds AS (
  SELECT
    COALESCE((SELECT MAX(end_date) FROM end_input), CURRENT_DATE) AS end_date,
    COALESCE((SELECT MAX(start_date) FROM start_input), CURRENT_DATE - INTERVAL '24 months') AS start_date
),

/**
---------------------------------------------------------------------------
STEP 2: FILTERED PLAYERS - Apply all global filters as gatekeeper
---------------------------------------------------------------------------
*/
filtered_players AS (
  SELECT DISTINCT players.id AS player_id
  FROM players
  LEFT JOIN companies ON companies.id = players.company_id
  WHERE 1=1
    [[ AND {{brand}} ]]
    [[ AND players.country = CASE {{country}} WHEN 'Romania' THEN 'RO' WHEN 'France' THEN 'FR' WHEN 'Germany' THEN 'DE' WHEN 'Cyprus' THEN 'CY' WHEN 'Poland' THEN 'PL' WHEN 'Spain' THEN 'ES' WHEN 'Italy' THEN 'IT' WHEN 'Canada' THEN 'CA' WHEN 'Australia' THEN 'AU' WHEN 'United Kingdom' THEN 'GB' WHEN 'Finland' THEN 'FI' WHEN 'Albania' THEN 'AL' WHEN 'Austria' THEN 'AT' WHEN 'Belgium' THEN 'BE' WHEN 'Brazil' THEN 'BR' WHEN 'Bulgaria' THEN 'BG' WHEN 'Georgia' THEN 'GE' WHEN 'Greece' THEN 'GR' WHEN 'Hungary' THEN 'HU' WHEN 'India' THEN 'IN' WHEN 'Netherlands' THEN 'NL' WHEN 'Portugal' THEN 'PT' WHEN 'Singapore' THEN 'SG' WHEN 'Turkey' THEN 'TR' WHEN 'United Arab Emirates' THEN 'AE' WHEN 'Afghanistan' THEN 'AF' WHEN 'Armenia' THEN 'AM' WHEN 'Denmark' THEN 'DK' WHEN 'Algeria' THEN 'DZ' WHEN 'Andorra' THEN 'AD' END ]]
    [[ AND CASE WHEN {{traffic_source}} = 'Organic' THEN players.affiliate_id IS NULL WHEN {{traffic_source}} = 'Affiliate' THEN players.affiliate_id IS NOT NULL ELSE TRUE END ]]
    [[ AND {{affiliate_id}} ]]
    [[ AND {{affiliate_name}} ]]
    [[ AND CONCAT(players.os, ' / ', players.browser) = {{registration_launcher}} ]]
    [[ AND {{is_test_account}} ]]
),

/**
---------------------------------------------------------------------------
STEP 3: PLAYER COHORTS - Register all filtered players with their cohort
---------------------------------------------------------------------------
*/
player_cohorts AS (
  SELECT p.id AS player_id, p.created_at AS registration_ts, DATE_TRUNC('month', p.created_at)::date AS registration_month, p.company_id
  FROM players p
  INNER JOIN filtered_players fp ON p.id = fp.player_id
  WHERE p.created_at >= (SELECT start_date FROM bounds) AND p.created_at < (SELECT end_date FROM bounds) + INTERVAL '1 day'
),

/**
---------------------------------------------------------------------------
STEP 4: FTD DATA - Identify first deposits per player
---------------------------------------------------------------------------
*/
ftd_data AS (
  SELECT t.player_id, MIN(t.created_at) AS first_deposit_ts
  FROM transactions t
  INNER JOIN player_cohorts pc ON t.player_id = pc.player_id
  JOIN players ON players.id = t.player_id
  JOIN companies ON companies.id = players.company_id
  WHERE t.transaction_category = 'deposit' AND t.transaction_type = 'credit' AND t.status = 'completed' AND t.balance_type = 'withdrawable'
    [[ AND UPPER(COALESCE(t.metadata->>'currency', t.cash_currency, players.wallet_currency, companies.currency)) IN ({{currency_filter}}) ]]
  GROUP BY t.player_id
),

/**
---------------------------------------------------------------------------
STEP 5: DEPOSIT & WITHDRAWAL METRICS (WITH CURRENCY LOGIC)
---------------------------------------------------------------------------
*/
deposit_withdrawal_metrics AS (
  SELECT pc.registration_month,
    COALESCE(SUM(CASE WHEN t.transaction_category = 'deposit' AND t.transaction_type = 'credit' AND t.status = 'completed' AND t.balance_type = 'withdrawable'
      THEN CASE WHEN {{currency_filter}} = 'EUR' THEN COALESCE(t.eur_amount, t.amount) ELSE t.amount END END), 0) AS total_deposits,
    COALESCE(SUM(CASE WHEN t.transaction_category = 'withdrawal' AND t.transaction_type = 'debit' AND t.status = 'completed' AND t.balance_type = 'withdrawable'
      THEN ABS(CASE WHEN {{currency_filter}} = 'EUR' THEN COALESCE(t.eur_amount, t.amount) ELSE t.amount END) END), 0) AS total_withdrawals
  FROM player_cohorts pc
  LEFT JOIN transactions t ON pc.player_id = t.player_id
  JOIN players ON players.id = pc.player_id
  JOIN companies ON companies.id = players.company_id
  WHERE 1=1
    [[ AND UPPER(COALESCE(t.metadata->>'currency', t.cash_currency, players.wallet_currency, companies.currency)) IN ({{currency_filter}}) ]]
  GROUP BY pc.registration_month
),

/**
---------------------------------------------------------------------------
STEP 6: GGR METRICS (WITH CURRENCY LOGIC)
---------------------------------------------------------------------------
*/
ggr_metrics AS (
  SELECT pc.registration_month,
    COALESCE(SUM(CASE WHEN t.transaction_type = 'debit' AND t.transaction_category = 'game_bet' AND t.balance_type = 'withdrawable' AND t.status = 'completed' THEN ABS(CASE WHEN {{currency_filter}} = 'EUR' THEN COALESCE(t.eur_amount, t.amount) ELSE t.amount END) END), 0) AS cash_bet,
    COALESCE(SUM(CASE WHEN t.transaction_type = 'credit' AND t.transaction_category = 'game_bet' AND t.balance_type = 'withdrawable' AND t.status = 'completed' THEN CASE WHEN {{currency_filter}} = 'EUR' THEN COALESCE(t.eur_amount, t.amount) ELSE t.amount END END), 0) AS cash_win,
    COALESCE(SUM(CASE WHEN t.transaction_type = 'debit' AND t.transaction_category = 'bonus' AND t.balance_type = 'non-withdrawable' AND t.status = 'completed' THEN ABS(CASE WHEN {{currency_filter}} = 'EUR' THEN COALESCE(t.eur_amount, t.amount) ELSE t.amount END) END), 0) AS promo_bet,
    COALESCE(SUM(CASE WHEN t.transaction_type = 'credit' AND t.transaction_category = 'bonus' AND t.balance_type = 'non-withdrawable' AND t.status = 'completed' THEN CASE WHEN {{currency_filter}} = 'EUR' THEN COALESCE(t.eur_amount, t.amount) ELSE t.amount END END), 0) AS promo_win
  FROM player_cohorts pc
  LEFT JOIN transactions t ON pc.player_id = t.player_id
  JOIN players ON players.id = pc.player_id
  JOIN companies ON companies.id = players.company_id
  WHERE 1=1
    [[ AND UPPER(COALESCE(t.metadata->>'currency', t.cash_currency, players.wallet_currency, companies.currency)) IN ({{currency_filter}}) ]]
  GROUP BY pc.registration_month
),

/**
---------------------------------------------------------------------------
STEP 7: BONUS COST METRICS (WITH CURRENCY LOGIC)
---------------------------------------------------------------------------
*/
bonus_cost_metrics AS (
  SELECT pc.registration_month,
    COALESCE(SUM(CASE WHEN t.transaction_type = 'credit' AND t.transaction_category = 'bonus_completion' AND t.status = 'completed' AND t.balance_type = 'withdrawable'
      THEN CASE WHEN {{currency_filter}} = 'EUR' THEN COALESCE(t.eur_amount, t.amount) ELSE t.amount END END), 0) AS total_bonus_cost
  FROM player_cohorts pc
  LEFT JOIN transactions t ON pc.player_id = t.player_id
  JOIN players ON players.id = pc.player_id
  JOIN companies ON companies.id = players.company_id
  WHERE 1=1
    [[ AND UPPER(COALESCE(t.metadata->>'currency', t.cash_currency, players.wallet_currency, companies.currency)) IN ({{currency_filter}}) ]]
  GROUP BY pc.registration_month
),

/**
---------------------------------------------------------------------------
STEP 8: COHORT LIFETIME METRICS - Combine all aggregations
---------------------------------------------------------------------------
*/
cohort_lifetime_metrics AS (
  SELECT
    pc.registration_month,
    COUNT(DISTINCT pc.player_id) AS total_registrations,
    COUNT(DISTINCT ftd.player_id) AS ftd_count,
    COALESCE(dwm.total_deposits, 0) AS total_deposits,
    COALESCE(dwm.total_withdrawals, 0) AS total_withdrawals,
    COALESCE(ggr.cash_bet, 0) AS cash_bet,
    COALESCE(ggr.cash_win, 0) AS cash_win,
    COALESCE(ggr.promo_bet, 0) AS promo_bet,
    COALESCE(ggr.promo_win, 0) AS promo_win,
    COALESCE(bcm.total_bonus_cost, 0) AS total_bonus_cost
  FROM player_cohorts pc
  LEFT JOIN ftd_data ftd ON pc.player_id = ftd.player_id
  LEFT JOIN deposit_withdrawal_metrics dwm ON pc.registration_month = dwm.registration_month
  LEFT JOIN ggr_metrics ggr ON pc.registration_month = ggr.registration_month
  LEFT JOIN bonus_cost_metrics bcm ON pc.registration_month = bcm.registration_month
  GROUP BY pc.registration_month, dwm.total_deposits, dwm.total_withdrawals, ggr.cash_bet, ggr.cash_win, ggr.promo_bet, ggr.promo_win, bcm.total_bonus_cost
),

/**
---------------------------------------------------------------------------
STEP 9: FINAL REPORT DATA - Calculate fees, NGR, Net Revenue, and LTV
---------------------------------------------------------------------------
*/
final_report_data AS (
  SELECT
    0 AS sort_order,
    -- [FIX FOR SORTING] Keep the original date for sorting
    registration_month,
    TO_CHAR(registration_month, 'FMMonth YYYY') AS month_year,
    total_registrations AS REG,
    ftd_count AS FTD,
    ROUND(CASE WHEN total_registrations > 0 THEN ftd_count::numeric / total_registrations * 100 ELSE 0 END, 2) AS conversion_rate,
    ROUND(CASE WHEN ftd_count > 0 THEN (((cash_bet + promo_bet - cash_win - promo_win) * 0.90) - ((total_deposits + total_withdrawals) * 0.08) - total_bonus_cost)::numeric / ftd_count ELSE 0 END, 2) AS ltv,
    ROUND(total_deposits, 2) AS deposit,
    ROUND(total_withdrawals, 2) AS wd,
    ROUND(cash_bet + promo_bet - cash_win - promo_win, 2) AS ggr,
    ROUND((cash_bet + promo_bet - cash_win - promo_win) * 0.09, 2) AS provider_fee,
    ROUND((total_deposits + total_withdrawals) * 0.08, 2) AS payment_fee,
    ROUND((cash_bet + promo_bet - cash_win - promo_win) * 0.01, 2) AS platform_fee,
    ROUND(total_bonus_cost, 2) AS bonus_cost,
    ROUND((cash_bet + promo_bet - cash_win - promo_win) - ((cash_bet + promo_bet - cash_win - promo_win) * 0.09) - ((total_deposits + total_withdrawals) * 0.08) - ((cash_bet + promo_bet - cash_win - promo_win) * 0.01), 2) AS ngr,
    ROUND(((cash_bet + promo_bet - cash_win - promo_win) - ((cash_bet + promo_bet - cash_win - promo_win) * 0.09) - ((total_deposits + total_withdrawals) * 0.08) - ((cash_bet + promo_bet - cash_win - promo_win) * 0.01)) - total_bonus_cost, 2) AS net_revenue
  FROM cohort_lifetime_metrics
)

/**
---------------------------------------------------------------------------
FINAL OUTPUT - Combine TOTAL row with individual month rows
---------------------------------------------------------------------------
*/
SELECT 
  -1 AS sort_order,
  NULL::date as registration_month, -- Add NULL date for consistent column structure
  'TOTAL' AS month_year,
  SUM(REG) AS REG,
  SUM(FTD) AS FTD,
  ROUND(SUM(FTD)::numeric / NULLIF(SUM(REG), 0) * 100, 2) AS conversion_rate,
  ROUND(SUM(net_revenue)::numeric / NULLIF(SUM(FTD), 0), 2) AS ltv,
  ROUND(SUM(deposit), 2) AS deposit,
  ROUND(SUM(wd), 2) AS wd,
  ROUND(SUM(ggr), 2) AS ggr,
  ROUND(SUM(provider_fee), 2) AS provider_fee,
  ROUND(SUM(payment_fee), 2) AS payment_fee,
  ROUND(SUM(platform_fee), 2) AS platform_fee,
  ROUND(SUM(bonus_cost), 2) AS bonus_cost,
  ROUND(SUM(ngr), 2) AS ngr,
  ROUND(SUM(net_revenue), 2) AS net_revenue
FROM final_report_data

UNION ALL

SELECT
  sort_order,
  registration_month,
  month_year,
  REG,
  FTD,
  conversion_rate,
  ltv,
  deposit,
  wd,
  ggr,
  provider_fee,
  payment_fee,
  platform_fee,
  bonus_cost,
  ngr,
  net_revenue
FROM final_report_data


ORDER BY sort_order, registration_month DESC;
