-- ===================================================
-- DAILY EMAIL REPORT - V7 (Updated with New Metrics)
-- ===================================================
-- Purpose: Aligned with daily_kpis.sql calculations
-- Added: Registrations, FTDs, Promo Bet/Win, Turnover Casino, GGR Casino, Granted Bonus
-- Updated: Promo Bet/Win use external_transaction_id IS NOT NULL (CTO-approved)
-- Updated: Granted Bonus uses player_bonus_id IS NOT NULL
-- Removed: Provider Fee, Payment Fee
-- NGR = Cash GGR - Platform Fee - Bonus Cost
-- Hold% = Cash GGR / Cash Turnover × 100
-- Updated: November 2025
-- Currency: EUR

WITH temporal_calculations AS (
  SELECT
    -- Date context
    CURRENT_DATE as report_date,
    EXTRACT(day FROM CURRENT_DATE) as days_elapsed_mtd,
    EXTRACT(day FROM DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day') as total_days_month

  FROM generate_series(1, 1) -- Dummy table for constants
),

-- ========== REGISTRATIONS ==========
registrations_calc AS (
  SELECT
    -- YESTERDAY
    COUNT(*) FILTER (WHERE DATE_TRUNC('day', created_at) = CURRENT_DATE - INTERVAL '1 day') as registrations_yesterday,
    -- MTD
    COUNT(*) FILTER (WHERE DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE)) as registrations_mtd,
    -- PREVIOUS MONTH
    COUNT(*) FILTER (WHERE DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')) as registrations_prev_month
  FROM players
),

-- ========== FTDs (Using ROW_NUMBER logic from daily_kpis) ==========
ftd_all_deposits AS (
  SELECT
    player_id,
    created_at,
    ROW_NUMBER() OVER (PARTITION BY player_id ORDER BY created_at ASC) as deposit_rank
  FROM transactions
  WHERE transaction_category = 'deposit'
    AND transaction_type = 'credit'
    AND status = 'completed'
),
ftd_calc AS (
  SELECT
    -- YESTERDAY
    COUNT(*) FILTER (WHERE DATE_TRUNC('day', created_at) = CURRENT_DATE - INTERVAL '1 day' AND deposit_rank = 1) as ftds_yesterday,
    -- MTD
    COUNT(*) FILTER (WHERE DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE) AND deposit_rank = 1) as ftds_mtd,
    -- PREVIOUS MONTH
    COUNT(*) FILTER (WHERE DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month') AND deposit_rank = 1) as ftds_prev_month
  FROM ftd_all_deposits
),

-- ========== TRANSACTION METRICS ==========
transaction_metrics AS (
  SELECT
    -- DEPOSITS - YESTERDAY
    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('day', created_at) = CURRENT_DATE - INTERVAL '1 day'
      AND transaction_category = 'deposit' AND transaction_type = 'credit'
      AND status = 'completed' AND balance_type = 'withdrawable'
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as deposits_yesterday,

    -- DEPOSITS - MTD
    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE)
      AND transaction_category = 'deposit' AND transaction_type = 'credit'
      AND status = 'completed' AND balance_type = 'withdrawable'
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as deposits_mtd,

    -- DEPOSITS - PREVIOUS MONTH
    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
      AND transaction_category = 'deposit' AND transaction_type = 'credit'
      AND status = 'completed' AND balance_type = 'withdrawable'
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as deposits_prev_month,

    -- WITHDRAWALS - YESTERDAY
    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('day', created_at) = CURRENT_DATE - INTERVAL '1 day'
      AND transaction_category = 'withdrawal' AND transaction_type = 'debit'
      AND status = 'completed' AND balance_type = 'withdrawable'
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as withdrawals_yesterday,

    -- WITHDRAWALS - MTD
    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE)
      AND transaction_category = 'withdrawal' AND transaction_type = 'debit'
      AND status = 'completed' AND balance_type = 'withdrawable'
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as withdrawals_mtd,

    -- WITHDRAWALS - PREVIOUS MONTH
    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
      AND transaction_category = 'withdrawal' AND transaction_type = 'debit'
      AND status = 'completed' AND balance_type = 'withdrawable'
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as withdrawals_prev_month,

    -- CASH BETS (WITHDRAWABLE ONLY) - YESTERDAY
    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('day', created_at) = CURRENT_DATE - INTERVAL '1 day'
      AND transaction_category = 'game_bet' AND transaction_type = 'debit'
      AND status = 'completed' AND balance_type = 'withdrawable'
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as cash_bets_yesterday,

    -- CASH BETS - MTD
    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE)
      AND transaction_category = 'game_bet' AND transaction_type = 'debit'
      AND status = 'completed' AND balance_type = 'withdrawable'
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as cash_bets_mtd,

    -- CASH BETS - PREVIOUS MONTH
    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
      AND transaction_category = 'game_bet' AND transaction_type = 'debit'
      AND status = 'completed' AND balance_type = 'withdrawable'
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as cash_bets_prev_month,

    -- CASH WINS (WITHDRAWABLE ONLY) - YESTERDAY
    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('day', created_at) = CURRENT_DATE - INTERVAL '1 day'
      AND transaction_category = 'game_bet' AND transaction_type = 'credit'
      AND status = 'completed' AND balance_type = 'withdrawable'
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as cash_wins_yesterday,

    -- CASH WINS - MTD
    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE)
      AND transaction_category = 'game_bet' AND transaction_type = 'credit'
      AND status = 'completed' AND balance_type = 'withdrawable'
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as cash_wins_mtd,

    -- CASH WINS - PREVIOUS MONTH
    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
      AND transaction_category = 'game_bet' AND transaction_type = 'credit'
      AND status = 'completed' AND balance_type = 'withdrawable'
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as cash_wins_prev_month,

    -- PROMO BETS (NEW LOGIC: external_transaction_id IS NOT NULL) - YESTERDAY
    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('day', created_at) = CURRENT_DATE - INTERVAL '1 day'
      AND transaction_category = 'bonus' AND transaction_type = 'debit'
      AND status = 'completed' AND external_transaction_id IS NOT NULL
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as promo_bets_yesterday,

    -- PROMO BETS - MTD
    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE)
      AND transaction_category = 'bonus' AND transaction_type = 'debit'
      AND status = 'completed' AND external_transaction_id IS NOT NULL
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as promo_bets_mtd,

    -- PROMO BETS - PREVIOUS MONTH
    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
      AND transaction_category = 'bonus' AND transaction_type = 'debit'
      AND status = 'completed' AND external_transaction_id IS NOT NULL
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as promo_bets_prev_month,

    -- PROMO WINS (NEW LOGIC: external_transaction_id IS NOT NULL) - YESTERDAY
    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('day', created_at) = CURRENT_DATE - INTERVAL '1 day'
      AND transaction_category = 'bonus' AND transaction_type = 'credit'
      AND status = 'completed' AND external_transaction_id IS NOT NULL
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as promo_wins_yesterday,

    -- PROMO WINS - MTD
    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE)
      AND transaction_category = 'bonus' AND transaction_type = 'credit'
      AND status = 'completed' AND external_transaction_id IS NOT NULL
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as promo_wins_mtd,

    -- PROMO WINS - PREVIOUS MONTH
    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
      AND transaction_category = 'bonus' AND transaction_type = 'credit'
      AND status = 'completed' AND external_transaction_id IS NOT NULL
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as promo_wins_prev_month,

    -- BONUS COST - YESTERDAY
    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('day', created_at) = CURRENT_DATE - INTERVAL '1 day'
      AND transaction_category = 'bonus_completion' AND transaction_type = 'credit'
      AND status = 'completed' AND balance_type = 'withdrawable'
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as bonus_cost_yesterday,

    -- BONUS COST - MTD
    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE)
      AND transaction_category = 'bonus_completion' AND transaction_type = 'credit'
      AND status = 'completed' AND balance_type = 'withdrawable'
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as bonus_cost_mtd,

    -- BONUS COST - PREVIOUS MONTH
    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
      AND transaction_category = 'bonus_completion' AND transaction_type = 'credit'
      AND status = 'completed' AND balance_type = 'withdrawable'
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as bonus_cost_prev_month,

    -- GRANTED BONUS (NEW LOGIC: player_bonus_id IS NOT NULL) - YESTERDAY
    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('day', created_at) = CURRENT_DATE - INTERVAL '1 day'
      AND transaction_type = 'credit' AND status = 'completed'
      AND balance_type = 'non-withdrawable' AND player_bonus_id IS NOT NULL
      AND transaction_category IN ('bonus', 'free_spin_bonus', 'free_bet', 'free_bet_win', 'freebet_win', 'bonus_completion')
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as granted_bonus_yesterday,

    -- GRANTED BONUS - MTD
    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE)
      AND transaction_type = 'credit' AND status = 'completed'
      AND balance_type = 'non-withdrawable' AND player_bonus_id IS NOT NULL
      AND transaction_category IN ('bonus', 'free_spin_bonus', 'free_bet', 'free_bet_win', 'freebet_win', 'bonus_completion')
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as granted_bonus_mtd,

    -- GRANTED BONUS - PREVIOUS MONTH
    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
      AND transaction_type = 'credit' AND status = 'completed'
      AND balance_type = 'non-withdrawable' AND player_bonus_id IS NOT NULL
      AND transaction_category IN ('bonus', 'free_spin_bonus', 'free_bet', 'free_bet_win', 'freebet_win', 'bonus_completion')
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as granted_bonus_prev_month

  FROM transactions
),

calculated_metrics AS (
  SELECT
    tc.*,
    rc.registrations_yesterday,
    rc.registrations_mtd,
    rc.registrations_prev_month,
    fc.ftds_yesterday,
    fc.ftds_mtd,
    fc.ftds_prev_month,
    tm.*,

    -- CASH GGR CALCULATIONS (Cash Bets - Cash Wins)
    (tm.cash_bets_yesterday - tm.cash_wins_yesterday) as cash_ggr_yesterday,
    (tm.cash_bets_mtd - tm.cash_wins_mtd) as cash_ggr_mtd,
    (tm.cash_bets_prev_month - tm.cash_wins_prev_month) as cash_ggr_prev_month,

    -- TURNOVER CASINO (Cash Bets + Promo Bets)
    (tm.cash_bets_yesterday + tm.promo_bets_yesterday) as turnover_casino_yesterday,
    (tm.cash_bets_mtd + tm.promo_bets_mtd) as turnover_casino_mtd,
    (tm.cash_bets_prev_month + tm.promo_bets_prev_month) as turnover_casino_prev_month,

    -- GGR CASINO (Total Turnover - Total Wins)
    ((tm.cash_bets_yesterday + tm.promo_bets_yesterday) - (tm.cash_wins_yesterday + tm.promo_wins_yesterday)) as ggr_casino_yesterday,
    ((tm.cash_bets_mtd + tm.promo_bets_mtd) - (tm.cash_wins_mtd + tm.promo_wins_mtd)) as ggr_casino_mtd,
    ((tm.cash_bets_prev_month + tm.promo_bets_prev_month) - (tm.cash_wins_prev_month + tm.promo_wins_prev_month)) as ggr_casino_prev_month,

    -- CASHFLOW
    (tm.deposits_yesterday - tm.withdrawals_yesterday) as cashflow_yesterday,
    (tm.deposits_mtd - tm.withdrawals_mtd) as cashflow_mtd,
    (tm.deposits_prev_month - tm.withdrawals_prev_month) as cashflow_prev_month,

    -- ESTIMATIONS (Linear Projection)
    ROUND((rc.registrations_mtd::numeric / NULLIF(tc.days_elapsed_mtd, 0)) * tc.total_days_month, 0) as registrations_estimation,
    ROUND((fc.ftds_mtd::numeric / NULLIF(tc.days_elapsed_mtd, 0)) * tc.total_days_month, 0) as ftds_estimation,
    ROUND((tm.deposits_mtd / NULLIF(tc.days_elapsed_mtd, 0)) * tc.total_days_month, 0) as deposits_estimation,
    ROUND((tm.withdrawals_mtd / NULLIF(tc.days_elapsed_mtd, 0)) * tc.total_days_month, 0) as withdrawals_estimation,
    ROUND((tm.cash_bets_mtd / NULLIF(tc.days_elapsed_mtd, 0)) * tc.total_days_month, 0) as cash_bets_estimation,
    ROUND((tm.cash_wins_mtd / NULLIF(tc.days_elapsed_mtd, 0)) * tc.total_days_month, 0) as cash_wins_estimation,
    ROUND((tm.promo_bets_mtd / NULLIF(tc.days_elapsed_mtd, 0)) * tc.total_days_month, 0) as promo_bets_estimation,
    ROUND((tm.promo_wins_mtd / NULLIF(tc.days_elapsed_mtd, 0)) * tc.total_days_month, 0) as promo_wins_estimation,
    ROUND((tm.bonus_cost_mtd / NULLIF(tc.days_elapsed_mtd, 0)) * tc.total_days_month, 0) as bonus_cost_estimation,
    ROUND((tm.granted_bonus_mtd / NULLIF(tc.days_elapsed_mtd, 0)) * tc.total_days_month, 0) as granted_bonus_estimation

  FROM temporal_calculations tc
  CROSS JOIN registrations_calc rc
  CROSS JOIN ftd_calc fc
  CROSS JOIN transaction_metrics tm
),

final_calculations AS (
  SELECT
    *,
    -- ESTIMATED DERIVED METRICS
    (cash_bets_estimation - cash_wins_estimation) as cash_ggr_estimation,
    (cash_bets_estimation + promo_bets_estimation) as turnover_casino_estimation,
    ((cash_bets_estimation + promo_bets_estimation) - (cash_wins_estimation + promo_wins_estimation)) as ggr_casino_estimation,

    -- PLATFORM FEE (1% of Cash GGR)
    ROUND((cash_bets_yesterday - cash_wins_yesterday) * 0.01, 2) as platform_fee_yesterday,
    ROUND((cash_bets_mtd - cash_wins_mtd) * 0.01, 2) as platform_fee_mtd,
    ROUND((cash_bets_prev_month - cash_wins_prev_month) * 0.01, 2) as platform_fee_prev_month,
    ROUND(((cash_bets_mtd / NULLIF(days_elapsed_mtd, 0)) * total_days_month - (cash_wins_mtd / NULLIF(days_elapsed_mtd, 0)) * total_days_month) * 0.01, 2) as platform_fee_estimation

  FROM calculated_metrics
),

ngr_calculations AS (
  SELECT
    *,
    -- NGR = Cash GGR - Platform Fee - Bonus Cost
    (cash_ggr_yesterday - platform_fee_yesterday - bonus_cost_yesterday) as ngr_yesterday,
    (cash_ggr_mtd - platform_fee_mtd - bonus_cost_mtd) as ngr_mtd,
    (cash_ggr_prev_month - platform_fee_prev_month - bonus_cost_prev_month) as ngr_prev_month,
    (cash_ggr_estimation - platform_fee_estimation - bonus_cost_estimation) as ngr_estimation
  FROM final_calculations
)

-- FINAL OUTPUT: Daily Report Table Format with Dynamic Date Header Row
SELECT
  metric_name,
  yesterday_value,
  mtd_value,
  estimation_value,
  actual_prev_month,
  percentage_difference
FROM (
  -- HEADER ROW with dynamic dates
  SELECT 0 as sort_order, 'DATE PERIOD →' as metric_name,
    'yesterday_' || TO_CHAR(CURRENT_DATE - INTERVAL '1 day', 'DD-MM-YY') as yesterday_value,
    'mtd_' || UPPER(TO_CHAR(CURRENT_DATE, 'MON-YY')) as mtd_value,
    'estimation_' || UPPER(TO_CHAR(CURRENT_DATE, 'MON-YY')) as estimation_value,
    'actual_' || UPPER(TO_CHAR(CURRENT_DATE - INTERVAL '1 month', 'MON-YY')) as actual_prev_month,
    '% vs ' || UPPER(TO_CHAR(CURRENT_DATE - INTERVAL '1 month', 'MON-YY')) as percentage_difference

  UNION ALL

  -- 1. REGISTRATIONS
  SELECT 1, 'REGISTRATIONS',
    TO_CHAR(registrations_yesterday, 'FM999,999,999'),
    TO_CHAR(registrations_mtd, 'FM999,999,999'),
    TO_CHAR(registrations_estimation, 'FM999,999,999'),
    TO_CHAR(registrations_prev_month, 'FM999,999,999'),
    CASE
      WHEN ((registrations_estimation - registrations_prev_month) / NULLIF(registrations_prev_month::numeric, 0)) * 100 > 0
      THEN CONCAT('+', ROUND(((registrations_estimation - registrations_prev_month) / NULLIF(registrations_prev_month::numeric, 0)) * 100, 1), '%')
      ELSE CONCAT(ROUND(((registrations_estimation - registrations_prev_month) / NULLIF(registrations_prev_month::numeric, 0)) * 100, 1), '%')
    END
  FROM ngr_calculations

  UNION ALL

  -- 2. FTDs
  SELECT 2, 'FTDs',
    TO_CHAR(ftds_yesterday, 'FM999,999,999'),
    TO_CHAR(ftds_mtd, 'FM999,999,999'),
    TO_CHAR(ftds_estimation, 'FM999,999,999'),
    TO_CHAR(ftds_prev_month, 'FM999,999,999'),
    CASE
      WHEN ((ftds_estimation - ftds_prev_month) / NULLIF(ftds_prev_month::numeric, 0)) * 100 > 0
      THEN CONCAT('+', ROUND(((ftds_estimation - ftds_prev_month) / NULLIF(ftds_prev_month::numeric, 0)) * 100, 1), '%')
      ELSE CONCAT(ROUND(((ftds_estimation - ftds_prev_month) / NULLIF(ftds_prev_month::numeric, 0)) * 100, 1), '%')
    END
  FROM ngr_calculations

  UNION ALL

  -- 3. DEPOSITS
  SELECT 3, 'DEPOSITS',
    CONCAT('€', TO_CHAR(ROUND(deposits_yesterday, 0), 'FM999,999,999')),
    CONCAT('€', TO_CHAR(ROUND(deposits_mtd, 0), 'FM999,999,999')),
    CONCAT('€', TO_CHAR(deposits_estimation, 'FM999,999,999')),
    CONCAT('€', TO_CHAR(ROUND(deposits_prev_month, 0), 'FM999,999,999')),
    CASE
      WHEN ((deposits_estimation - deposits_prev_month) / NULLIF(deposits_prev_month, 0)) * 100 > 0
      THEN CONCAT('+', ROUND(((deposits_estimation - deposits_prev_month) / NULLIF(deposits_prev_month, 0)) * 100, 1), '%')
      ELSE CONCAT(ROUND(((deposits_estimation - deposits_prev_month) / NULLIF(deposits_prev_month, 0)) * 100, 1), '%')
    END
  FROM ngr_calculations

  UNION ALL

  -- 4. PAID WITHDRAWALS
  SELECT 4, 'PAID WITHDRAWALS',
    CONCAT('€', TO_CHAR(ROUND(withdrawals_yesterday, 0), 'FM999,999,999')),
    CONCAT('€', TO_CHAR(ROUND(withdrawals_mtd, 0), 'FM999,999,999')),
    CONCAT('€', TO_CHAR(withdrawals_estimation, 'FM999,999,999')),
    CONCAT('€', TO_CHAR(ROUND(withdrawals_prev_month, 0), 'FM999,999,999')),
    CASE
      WHEN ((withdrawals_estimation - withdrawals_prev_month) / NULLIF(withdrawals_prev_month, 0)) * 100 > 0
      THEN CONCAT('+', ROUND(((withdrawals_estimation - withdrawals_prev_month) / NULLIF(withdrawals_prev_month, 0)) * 100, 1), '%')
      ELSE CONCAT(ROUND(((withdrawals_estimation - withdrawals_prev_month) / NULLIF(withdrawals_prev_month, 0)) * 100, 1), '%')
    END
  FROM ngr_calculations

  UNION ALL

  -- 5. CASHFLOW
  SELECT 5, 'CASHFLOW',
    CONCAT('€', TO_CHAR(ROUND(cashflow_yesterday, 0), 'FM999,999,999')),
    CONCAT('€', TO_CHAR(ROUND(cashflow_mtd, 0), 'FM999,999,999')),
    CONCAT('€', TO_CHAR(ROUND((deposits_estimation - withdrawals_estimation), 0), 'FM999,999,999')),
    CONCAT('€', TO_CHAR(ROUND(cashflow_prev_month, 0), 'FM999,999,999')),
    CASE
      WHEN (((deposits_estimation - withdrawals_estimation) - cashflow_prev_month) / NULLIF(cashflow_prev_month, 0)) * 100 > 0
      THEN CONCAT('+', ROUND((((deposits_estimation - withdrawals_estimation) - cashflow_prev_month) / NULLIF(cashflow_prev_month, 0)) * 100, 1), '%')
      ELSE CONCAT(ROUND((((deposits_estimation - withdrawals_estimation) - cashflow_prev_month) / NULLIF(cashflow_prev_month, 0)) * 100, 1), '%')
    END
  FROM ngr_calculations

  UNION ALL

  -- 6. CASH TURNOVER
  SELECT 6, 'CASH TURNOVER',
    CONCAT('€', TO_CHAR(ROUND(cash_bets_yesterday, 0), 'FM999,999,999')),
    CONCAT('€', TO_CHAR(ROUND(cash_bets_mtd, 0), 'FM999,999,999')),
    CONCAT('€', TO_CHAR(cash_bets_estimation, 'FM999,999,999')),
    CONCAT('€', TO_CHAR(ROUND(cash_bets_prev_month, 0), 'FM999,999,999')),
    CASE
      WHEN ((cash_bets_estimation - cash_bets_prev_month) / NULLIF(cash_bets_prev_month, 0)) * 100 > 0
      THEN CONCAT('+', ROUND(((cash_bets_estimation - cash_bets_prev_month) / NULLIF(cash_bets_prev_month, 0)) * 100, 1), '%')
      ELSE CONCAT(ROUND(((cash_bets_estimation - cash_bets_prev_month) / NULLIF(cash_bets_prev_month, 0)) * 100, 1), '%')
    END
  FROM ngr_calculations

  UNION ALL

  -- 7. TURNOVER CASINO
  SELECT 7, 'TURNOVER CASINO',
    CONCAT('€', TO_CHAR(ROUND(turnover_casino_yesterday, 0), 'FM999,999,999')),
    CONCAT('€', TO_CHAR(ROUND(turnover_casino_mtd, 0), 'FM999,999,999')),
    CONCAT('€', TO_CHAR(turnover_casino_estimation, 'FM999,999,999')),
    CONCAT('€', TO_CHAR(ROUND(turnover_casino_prev_month, 0), 'FM999,999,999')),
    CASE
      WHEN ((turnover_casino_estimation - turnover_casino_prev_month) / NULLIF(turnover_casino_prev_month, 0)) * 100 > 0
      THEN CONCAT('+', ROUND(((turnover_casino_estimation - turnover_casino_prev_month) / NULLIF(turnover_casino_prev_month, 0)) * 100, 1), '%')
      ELSE CONCAT(ROUND(((turnover_casino_estimation - turnover_casino_prev_month) / NULLIF(turnover_casino_prev_month, 0)) * 100, 1), '%')
    END
  FROM ngr_calculations

  UNION ALL

  -- 8. TOTAL TURNOVER
  SELECT 8, 'TOTAL TURNOVER',
    CONCAT('€', TO_CHAR(ROUND(turnover_casino_yesterday, 0), 'FM999,999,999')),
    CONCAT('€', TO_CHAR(ROUND(turnover_casino_mtd, 0), 'FM999,999,999')),
    CONCAT('€', TO_CHAR(turnover_casino_estimation, 'FM999,999,999')),
    CONCAT('€', TO_CHAR(ROUND(turnover_casino_prev_month, 0), 'FM999,999,999')),
    CASE
      WHEN ((turnover_casino_estimation - turnover_casino_prev_month) / NULLIF(turnover_casino_prev_month, 0)) * 100 > 0
      THEN CONCAT('+', ROUND(((turnover_casino_estimation - turnover_casino_prev_month) / NULLIF(turnover_casino_prev_month, 0)) * 100, 1), '%')
      ELSE CONCAT(ROUND(((turnover_casino_estimation - turnover_casino_prev_month) / NULLIF(turnover_casino_prev_month, 0)) * 100, 1), '%')
    END
  FROM ngr_calculations

  UNION ALL

  -- 9. CASH GGR
  SELECT 9, 'CASH GGR',
    CONCAT('€', TO_CHAR(ROUND(cash_ggr_yesterday, 0), 'FM999,999,999')),
    CONCAT('€', TO_CHAR(ROUND(cash_ggr_mtd, 0), 'FM999,999,999')),
    CONCAT('€', TO_CHAR(cash_ggr_estimation, 'FM999,999,999')),
    CONCAT('€', TO_CHAR(ROUND(cash_ggr_prev_month, 0), 'FM999,999,999')),
    CASE
      WHEN ((cash_ggr_estimation - cash_ggr_prev_month) / NULLIF(cash_ggr_prev_month, 0)) * 100 > 0
      THEN CONCAT('+', ROUND(((cash_ggr_estimation - cash_ggr_prev_month) / NULLIF(cash_ggr_prev_month, 0)) * 100, 1), '%')
      ELSE CONCAT(ROUND(((cash_ggr_estimation - cash_ggr_prev_month) / NULLIF(cash_ggr_prev_month, 0)) * 100, 1), '%')
    END
  FROM ngr_calculations

  UNION ALL

  -- 10. CASH GGR CASINO
  SELECT 10, 'CASH GGR CASINO',
    CONCAT('€', TO_CHAR(ROUND(cash_ggr_yesterday, 0), 'FM999,999,999')),
    CONCAT('€', TO_CHAR(ROUND(cash_ggr_mtd, 0), 'FM999,999,999')),
    CONCAT('€', TO_CHAR(cash_ggr_estimation, 'FM999,999,999')),
    CONCAT('€', TO_CHAR(ROUND(cash_ggr_prev_month, 0), 'FM999,999,999')),
    CASE
      WHEN ((cash_ggr_estimation - cash_ggr_prev_month) / NULLIF(cash_ggr_prev_month, 0)) * 100 > 0
      THEN CONCAT('+', ROUND(((cash_ggr_estimation - cash_ggr_prev_month) / NULLIF(cash_ggr_prev_month, 0)) * 100, 1), '%')
      ELSE CONCAT(ROUND(((cash_ggr_estimation - cash_ggr_prev_month) / NULLIF(cash_ggr_prev_month, 0)) * 100, 1), '%')
    END
  FROM ngr_calculations

  UNION ALL

  -- 11. GGR CASINO
  SELECT 11, 'GGR CASINO',
    CONCAT('€', TO_CHAR(ROUND(ggr_casino_yesterday, 0), 'FM999,999,999')),
    CONCAT('€', TO_CHAR(ROUND(ggr_casino_mtd, 0), 'FM999,999,999')),
    CONCAT('€', TO_CHAR(ggr_casino_estimation, 'FM999,999,999')),
    CONCAT('€', TO_CHAR(ROUND(ggr_casino_prev_month, 0), 'FM999,999,999')),
    CASE
      WHEN ((ggr_casino_estimation - ggr_casino_prev_month) / NULLIF(ggr_casino_prev_month, 0)) * 100 > 0
      THEN CONCAT('+', ROUND(((ggr_casino_estimation - ggr_casino_prev_month) / NULLIF(ggr_casino_prev_month, 0)) * 100, 1), '%')
      ELSE CONCAT(ROUND(((ggr_casino_estimation - ggr_casino_prev_month) / NULLIF(ggr_casino_prev_month, 0)) * 100, 1), '%')
    END
  FROM ngr_calculations

  UNION ALL

  -- 12. PLATFORM FEE
  SELECT 12, 'PLATFORM FEE',
    CONCAT('€', TO_CHAR(ROUND(platform_fee_yesterday, 0), 'FM999,999,999')),
    CONCAT('€', TO_CHAR(ROUND(platform_fee_mtd, 0), 'FM999,999,999')),
    CONCAT('€', TO_CHAR(ROUND(platform_fee_estimation, 0), 'FM999,999,999')),
    CONCAT('€', TO_CHAR(ROUND(platform_fee_prev_month, 0), 'FM999,999,999')),
    CASE
      WHEN ((platform_fee_estimation - platform_fee_prev_month) / NULLIF(platform_fee_prev_month, 0)) * 100 > 0
      THEN CONCAT('+', ROUND(((platform_fee_estimation - platform_fee_prev_month) / NULLIF(platform_fee_prev_month, 0)) * 100, 1), '%')
      ELSE CONCAT(ROUND(((platform_fee_estimation - platform_fee_prev_month) / NULLIF(platform_fee_prev_month, 0)) * 100, 1), '%')
    END
  FROM ngr_calculations

  UNION ALL

  -- 13. BONUS COST
  SELECT 13, 'BONUS COST',
    CONCAT('€', TO_CHAR(ROUND(bonus_cost_yesterday, 0), 'FM999,999,999')),
    CONCAT('€', TO_CHAR(ROUND(bonus_cost_mtd, 0), 'FM999,999,999')),
    CONCAT('€', TO_CHAR(bonus_cost_estimation, 'FM999,999,999')),
    CONCAT('€', TO_CHAR(ROUND(bonus_cost_prev_month, 0), 'FM999,999,999')),
    CASE
      WHEN ((bonus_cost_estimation - bonus_cost_prev_month) / NULLIF(bonus_cost_prev_month, 0)) * 100 > 0
      THEN CONCAT('+', ROUND(((bonus_cost_estimation - bonus_cost_prev_month) / NULLIF(bonus_cost_prev_month, 0)) * 100, 1), '%')
      ELSE CONCAT(ROUND(((bonus_cost_estimation - bonus_cost_prev_month) / NULLIF(bonus_cost_prev_month, 0)) * 100, 1), '%')
    END
  FROM ngr_calculations

  UNION ALL

  -- 14. GRANTED BONUS
  SELECT 14, 'GRANTED BONUS',
    CONCAT('€', TO_CHAR(ROUND(granted_bonus_yesterday, 0), 'FM999,999,999')),
    CONCAT('€', TO_CHAR(ROUND(granted_bonus_mtd, 0), 'FM999,999,999')),
    CONCAT('€', TO_CHAR(granted_bonus_estimation, 'FM999,999,999')),
    CONCAT('€', TO_CHAR(ROUND(granted_bonus_prev_month, 0), 'FM999,999,999')),
    CASE
      WHEN ((granted_bonus_estimation - granted_bonus_prev_month) / NULLIF(granted_bonus_prev_month, 0)) * 100 > 0
      THEN CONCAT('+', ROUND(((granted_bonus_estimation - granted_bonus_prev_month) / NULLIF(granted_bonus_prev_month, 0)) * 100, 1), '%')
      ELSE CONCAT(ROUND(((granted_bonus_estimation - granted_bonus_prev_month) / NULLIF(granted_bonus_prev_month, 0)) * 100, 1), '%')
    END
  FROM ngr_calculations

  UNION ALL

  -- 15. NGR
  SELECT 15, 'NGR',
    CONCAT('€', TO_CHAR(ROUND(ngr_yesterday, 0), 'FM999,999,999')),
    CONCAT('€', TO_CHAR(ROUND(ngr_mtd, 0), 'FM999,999,999')),
    CONCAT('€', TO_CHAR(ROUND(ngr_estimation, 0), 'FM999,999,999')),
    CONCAT('€', TO_CHAR(ROUND(ngr_prev_month, 0), 'FM999,999,999')),
    CASE
      WHEN ((ngr_estimation - ngr_prev_month) / NULLIF(ngr_prev_month, 0)) * 100 > 0
      THEN CONCAT('+', ROUND(((ngr_estimation - ngr_prev_month) / NULLIF(ngr_prev_month, 0)) * 100, 1), '%')
      ELSE CONCAT(ROUND(((ngr_estimation - ngr_prev_month) / NULLIF(ngr_prev_month, 0)) * 100, 1), '%')
    END
  FROM ngr_calculations

  UNION ALL

  -- 16. HOLD % (CASH)
  SELECT 16, 'HOLD % (CASH)',
    CASE WHEN cash_bets_yesterday > 0
         THEN CONCAT(ROUND((cash_ggr_yesterday / cash_bets_yesterday) * 100, 1), '%')
         ELSE '0.0%' END,
    CASE WHEN cash_bets_mtd > 0
         THEN CONCAT(ROUND((cash_ggr_mtd / cash_bets_mtd) * 100, 1), '%')
         ELSE '0.0%' END,
    CASE WHEN cash_bets_estimation > 0
         THEN CONCAT(ROUND((cash_ggr_estimation / cash_bets_estimation) * 100, 1), '%')
         ELSE '0.0%' END,
    CASE WHEN cash_bets_prev_month > 0
         THEN CONCAT(ROUND((cash_ggr_prev_month / cash_bets_prev_month) * 100, 1), '%')
         ELSE '0.0%' END,
    '0.0%'
  FROM ngr_calculations

) daily_report
ORDER BY sort_order;
