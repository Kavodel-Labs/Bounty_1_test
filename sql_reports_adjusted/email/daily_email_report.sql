-- ===================================================
-- DAILY EMAIL REPORT - V5 (CTO-APPROVED)
-- ===================================================
-- Purpose: Aligned with STAKEHOLDER GUIDE V2 formulas
-- Cash GGR = Cash Bets - Cash Wins (withdrawable balance only)
-- Provider Fee = Cash GGR × 0.09 (9%)
-- Payment Fee = (Deposits + Withdrawals) × 0.08 (8%)
-- Platform Fee = Cash GGR × 0.01 (1%)
-- NGR = Cash GGR - Provider Fee - Payment Fee - Platform Fee - Bonus Cost
-- Hold% = Cash GGR / Cash Turnover × 100
-- Updated: November 2025 (Aligned with V2 Formula Standards)
-- Currency: EUR

WITH temporal_calculations AS (
  SELECT
    -- Date context
    CURRENT_DATE as report_date,
    EXTRACT(day FROM CURRENT_DATE) as days_elapsed_mtd,
    EXTRACT(day FROM DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day') as total_days_month,

    -- YESTERDAY VALUES (EUR CONVERSION)
    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('day', created_at) = CURRENT_DATE - INTERVAL '1 day'
      AND transaction_category = 'deposit' AND transaction_type = 'credit'
      AND status = 'completed' AND balance_type = 'withdrawable'
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as deposits_yesterday,

    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('day', created_at) = CURRENT_DATE - INTERVAL '1 day'
      AND transaction_category = 'withdrawal' AND transaction_type = 'debit'
      AND status = 'completed' AND balance_type = 'withdrawable'
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as withdrawals_yesterday,

    -- CASH BETS (WITHDRAWABLE ONLY) - YESTERDAY (EUR CONVERSION)
    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('day', created_at) = CURRENT_DATE - INTERVAL '1 day'
      AND transaction_category = 'game_bet' AND transaction_type = 'debit'
      AND status = 'completed' AND balance_type = 'withdrawable'
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as cash_bets_yesterday,

    -- CASH WINS (WITHDRAWABLE ONLY) - YESTERDAY (EUR CONVERSION)
    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('day', created_at) = CURRENT_DATE - INTERVAL '1 day'
      AND transaction_category = 'game_bet' AND transaction_type = 'credit'
      AND status = 'completed' AND balance_type = 'withdrawable'
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as cash_wins_yesterday,

    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('day', created_at) = CURRENT_DATE - INTERVAL '1 day'
      AND transaction_category = 'bonus_completion' AND transaction_type = 'credit'
      AND status = 'completed' AND balance_type = 'withdrawable'
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as bonus_cost_yesterday,

    -- MTD VALUES (EUR CONVERSION)
    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE)
      AND transaction_category = 'deposit' AND transaction_type = 'credit'
      AND status = 'completed' AND balance_type = 'withdrawable'
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as deposits_mtd,

    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE)
      AND transaction_category = 'withdrawal' AND transaction_type = 'debit'
      AND status = 'completed' AND balance_type = 'withdrawable'
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as withdrawals_mtd,

    -- CASH BETS (WITHDRAWABLE ONLY) - MTD (EUR CONVERSION)
    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE)
      AND transaction_category = 'game_bet' AND transaction_type = 'debit'
      AND status = 'completed' AND balance_type = 'withdrawable'
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as cash_bets_mtd,

    -- CASH WINS (WITHDRAWABLE ONLY) - MTD (EUR CONVERSION)
    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE)
      AND transaction_category = 'game_bet' AND transaction_type = 'credit'
      AND status = 'completed' AND balance_type = 'withdrawable'
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as cash_wins_mtd,

    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE)
      AND transaction_category = 'bonus_completion' AND transaction_type = 'credit'
      AND status = 'completed' AND balance_type = 'withdrawable'
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as bonus_cost_mtd,

    -- PREVIOUS MONTH VALUES (EUR CONVERSION)
    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
      AND transaction_category = 'deposit' AND transaction_type = 'credit'
      AND status = 'completed' AND balance_type = 'withdrawable'
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as deposits_prev_month,

    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
      AND transaction_category = 'withdrawal' AND transaction_type = 'debit'
      AND status = 'completed' AND balance_type = 'withdrawable'
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as withdrawals_prev_month,

    -- CASH BETS (WITHDRAWABLE ONLY) - PREVIOUS MONTH (EUR CONVERSION)
    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
      AND transaction_category = 'game_bet' AND transaction_type = 'debit'
      AND status = 'completed' AND balance_type = 'withdrawable'
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as cash_bets_prev_month,

    -- CASH WINS (WITHDRAWABLE ONLY) - PREVIOUS MONTH (EUR CONVERSION)
    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
      AND transaction_category = 'game_bet' AND transaction_type = 'credit'
      AND status = 'completed' AND balance_type = 'withdrawable'
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as cash_wins_prev_month,

    COALESCE(SUM(CASE
      WHEN DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
      AND transaction_category = 'bonus_completion' AND transaction_type = 'credit'
      AND status = 'completed' AND balance_type = 'withdrawable'
      THEN COALESCE(eur_amount, amount) ELSE 0 END), 0) as bonus_cost_prev_month

  FROM transactions
),

calculated_metrics AS (
  SELECT
    *,
    -- CASH GGR CALCULATIONS (Cash Bets - Cash Wins)
    (cash_bets_yesterday - cash_wins_yesterday) as cash_ggr_yesterday,
    (cash_bets_mtd - cash_wins_mtd) as cash_ggr_mtd,
    (cash_bets_prev_month - cash_wins_prev_month) as cash_ggr_prev_month,

    -- OTHER CALCULATED VALUES
    (deposits_yesterday - withdrawals_yesterday) as cashflow_yesterday,
    (deposits_mtd - withdrawals_mtd) as cashflow_mtd,
    (deposits_prev_month - withdrawals_prev_month) as cashflow_prev_month,

    -- ESTIMATIONS (Linear Projection)
    ROUND((deposits_mtd / NULLIF(days_elapsed_mtd, 0)) * total_days_month, 0) as deposits_estimation,
    ROUND((withdrawals_mtd / NULLIF(days_elapsed_mtd, 0)) * total_days_month, 0) as withdrawals_estimation,
    ROUND((cash_bets_mtd / NULLIF(days_elapsed_mtd, 0)) * total_days_month, 0) as cash_bets_estimation,
    ROUND((cash_wins_mtd / NULLIF(days_elapsed_mtd, 0)) * total_days_month, 0) as cash_wins_estimation,
    ROUND((bonus_cost_mtd / NULLIF(days_elapsed_mtd, 0)) * total_days_month, 0) as bonus_cost_estimation

  FROM temporal_calculations
),

fee_calculations AS (
  SELECT
    *,
    -- ESTIMATED CASH GGR
    (cash_bets_estimation - cash_wins_estimation) as cash_ggr_estimation,

    -- PROVIDER FEE (9% of Cash GGR) - CTO-APPROVED
    ROUND((cash_bets_yesterday - cash_wins_yesterday) * 0.09, 2) as provider_fee_yesterday,
    ROUND((cash_bets_mtd - cash_wins_mtd) * 0.09, 2) as provider_fee_mtd,
    ROUND((cash_bets_prev_month - cash_wins_prev_month) * 0.09, 2) as provider_fee_prev_month,
    ROUND(((cash_bets_mtd / NULLIF(days_elapsed_mtd, 0)) * total_days_month - (cash_wins_mtd / NULLIF(days_elapsed_mtd, 0)) * total_days_month) * 0.09, 2) as provider_fee_estimation,

    -- PAYMENT FEE (8% of Deposits + Withdrawals) - CTO-APPROVED
    ROUND((deposits_yesterday + withdrawals_yesterday) * 0.08, 2) as payment_fee_yesterday,
    ROUND((deposits_mtd + withdrawals_mtd) * 0.08, 2) as payment_fee_mtd,
    ROUND((deposits_prev_month + withdrawals_prev_month) * 0.08, 2) as payment_fee_prev_month,
    ROUND(((deposits_mtd / NULLIF(days_elapsed_mtd, 0)) * total_days_month + (withdrawals_mtd / NULLIF(days_elapsed_mtd, 0)) * total_days_month) * 0.08, 2) as payment_fee_estimation,

    -- PLATFORM FEE (1% of Cash GGR) - CTO-APPROVED
    ROUND((cash_bets_yesterday - cash_wins_yesterday) * 0.01, 2) as platform_fee_yesterday,
    ROUND((cash_bets_mtd - cash_wins_mtd) * 0.01, 2) as platform_fee_mtd,
    ROUND((cash_bets_prev_month - cash_wins_prev_month) * 0.01, 2) as platform_fee_prev_month,
    ROUND(((cash_bets_mtd / NULLIF(days_elapsed_mtd, 0)) * total_days_month - (cash_wins_mtd / NULLIF(days_elapsed_mtd, 0)) * total_days_month) * 0.01, 2) as platform_fee_estimation

  FROM calculated_metrics
),

final_calculations AS (
  SELECT
    *,
    -- NGR CALCULATIONS (CTO-APPROVED FORMULA)
    -- NGR = Cash GGR - Provider Fee - Payment Fee - Platform Fee - Bonus Cost
    (cash_ggr_yesterday - provider_fee_yesterday - payment_fee_yesterday - platform_fee_yesterday - bonus_cost_yesterday) as ngr_yesterday,
    (cash_ggr_mtd - provider_fee_mtd - payment_fee_mtd - platform_fee_mtd - bonus_cost_mtd) as ngr_mtd,
    (cash_ggr_prev_month - provider_fee_prev_month - payment_fee_prev_month - platform_fee_prev_month - bonus_cost_prev_month) as ngr_prev_month

  FROM fee_calculations
),

ngr_estimations AS (
  SELECT
    *,
    (cash_ggr_estimation - provider_fee_estimation - payment_fee_estimation - platform_fee_estimation - bonus_cost_estimation) as ngr_estimation
  FROM final_calculations
)

-- FINAL OUTPUT: Daily Report Table Format
SELECT
  metric_name,
  yesterday_value,
  mtd_value,
  estimation_value,
  actual_prev_month,
  percentage_difference
FROM (
  SELECT 1 as sort_order, 'DEPOSITS' as metric_name,
    CONCAT('€', ROUND(deposits_yesterday, 0)) as yesterday_value,
    CONCAT('€', ROUND(deposits_mtd, 0)) as mtd_value,
    CONCAT('€', deposits_estimation) as estimation_value,
    CONCAT('€', ROUND(deposits_prev_month, 0)) as actual_prev_month,
    CONCAT(ROUND(((deposits_estimation - deposits_prev_month) / NULLIF(deposits_prev_month, 0)) * 100, 1), '%') as percentage_difference
  FROM ngr_estimations

  UNION ALL

  SELECT 2, 'PAID WITHDRAWALS',
    CONCAT('€', ROUND(withdrawals_yesterday, 0)),
    CONCAT('€', ROUND(withdrawals_mtd, 0)),
    CONCAT('€', withdrawals_estimation),
    CONCAT('€', ROUND(withdrawals_prev_month, 0)),
    CONCAT(ROUND(((withdrawals_estimation - withdrawals_prev_month) / NULLIF(withdrawals_prev_month, 0)) * 100, 1), '%')
  FROM ngr_estimations

  UNION ALL

  SELECT 3, 'CASHFLOW',
    CONCAT('€', ROUND(cashflow_yesterday, 0)),
    CONCAT('€', ROUND(cashflow_mtd, 0)),
    CONCAT('€', ROUND((deposits_estimation - withdrawals_estimation), 0)),
    CONCAT('€', ROUND(cashflow_prev_month, 0)),
    CONCAT(ROUND((((deposits_estimation - withdrawals_estimation) - cashflow_prev_month) / NULLIF(cashflow_prev_month, 0)) * 100, 1), '%')
  FROM ngr_estimations

  UNION ALL

  SELECT 4, 'CASH TURNOVER',
    CONCAT('€', ROUND(cash_bets_yesterday, 0)),
    CONCAT('€', ROUND(cash_bets_mtd, 0)),
    CONCAT('€', cash_bets_estimation),
    CONCAT('€', ROUND(cash_bets_prev_month, 0)),
    CONCAT(ROUND(((cash_bets_estimation - cash_bets_prev_month) / NULLIF(cash_bets_prev_month, 0)) * 100, 1), '%')
  FROM ngr_estimations

  UNION ALL

  SELECT 5, 'CASH GGR',
    CONCAT('€', ROUND(cash_ggr_yesterday, 0)),
    CONCAT('€', ROUND(cash_ggr_mtd, 0)),
    CONCAT('€', cash_ggr_estimation),
    CONCAT('€', ROUND(cash_ggr_prev_month, 0)),
    CONCAT(ROUND(((cash_ggr_estimation - cash_ggr_prev_month) / NULLIF(cash_ggr_prev_month, 0)) * 100, 1), '%')
  FROM ngr_estimations

  UNION ALL

  SELECT 6, 'PROVIDER FEE (9%)',
    CONCAT('€', ROUND(provider_fee_yesterday, 0)),
    CONCAT('€', ROUND(provider_fee_mtd, 0)),
    CONCAT('€', ROUND(provider_fee_estimation, 0)),
    CONCAT('€', ROUND(provider_fee_prev_month, 0)),
    CONCAT(ROUND(((provider_fee_estimation - provider_fee_prev_month) / NULLIF(provider_fee_prev_month, 0)) * 100, 1), '%')
  FROM ngr_estimations

  UNION ALL

  SELECT 7, 'PAYMENT FEE (8%)',
    CONCAT('€', ROUND(payment_fee_yesterday, 0)),
    CONCAT('€', ROUND(payment_fee_mtd, 0)),
    CONCAT('€', ROUND(payment_fee_estimation, 0)),
    CONCAT('€', ROUND(payment_fee_prev_month, 0)),
    CONCAT(ROUND(((payment_fee_estimation - payment_fee_prev_month) / NULLIF(payment_fee_prev_month, 0)) * 100, 1), '%')
  FROM ngr_estimations

  UNION ALL

  SELECT 8, 'PLATFORM FEE (1%)',
    CONCAT('€', ROUND(platform_fee_yesterday, 0)),
    CONCAT('€', ROUND(platform_fee_mtd, 0)),
    CONCAT('€', ROUND(platform_fee_estimation, 0)),
    CONCAT('€', ROUND(platform_fee_prev_month, 0)),
    CONCAT(ROUND(((platform_fee_estimation - platform_fee_prev_month) / NULLIF(platform_fee_prev_month, 0)) * 100, 1), '%')
  FROM ngr_estimations

  UNION ALL

  SELECT 9, 'BONUS COST',
    CONCAT('€', ROUND(bonus_cost_yesterday, 0)),
    CONCAT('€', ROUND(bonus_cost_mtd, 0)),
    CONCAT('€', bonus_cost_estimation),
    CONCAT('€', ROUND(bonus_cost_prev_month, 0)),
    CONCAT(ROUND(((bonus_cost_estimation - bonus_cost_prev_month) / NULLIF(bonus_cost_prev_month, 0)) * 100, 1), '%')
  FROM ngr_estimations

  UNION ALL

  SELECT 10, 'NGR',
    CONCAT('€', ROUND(ngr_yesterday, 0)),
    CONCAT('€', ROUND(ngr_mtd, 0)),
    CONCAT('€', ROUND(ngr_estimation, 0)),
    CONCAT('€', ROUND(ngr_prev_month, 0)),
    CONCAT(ROUND(((ngr_estimation - ngr_prev_month) / NULLIF(ngr_prev_month, 0)) * 100, 1), '%')
  FROM ngr_estimations

  UNION ALL

  SELECT 11, 'HOLD % (CASH)',
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
  FROM ngr_estimations

) daily_report
ORDER BY sort_order;
