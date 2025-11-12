/* =========================
   DAILY KPIs — MULTI-DAY with SUMMARY ROW
   [NEW] FTD discovery uses ROW_NUMBER() for accurate first deposits
   [NEW] Implements standardized EUR currency conversion with NULL safety
   ========================= */

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

/* --- Normalize window (no inputs → last 31 days to today) --- */
bounds_raw AS (
  SELECT
    COALESCE((SELECT MAX(end_date) FROM end_input), CURRENT_DATE) AS end_date_raw,
    (SELECT MAX(start_date) FROM start_input) AS start_date_raw
),
bounds AS (
  SELECT
    end_date_raw AS end_date,
    CASE
      WHEN start_date_raw IS NULL THEN end_date_raw - INTERVAL '31 day'
      WHEN start_date_raw > end_date_raw THEN end_date_raw
      ELSE start_date_raw
    END AS start_date
  FROM bounds_raw
),

/* --- Daily series over the chosen window --- */
date_series AS (
  SELECT 
    d::date AS report_date,
    d AS start_ts,
    LEAST(d + INTERVAL '1 day', NOW()) AS end_ts
  FROM generate_series(
    (SELECT start_date FROM bounds),
    (SELECT end_date FROM bounds),
    INTERVAL '1 day'
  ) AS d
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
      WHEN {{traffic_source}} = 'Organic' THEN players.affiliate_id IS NULL
      WHEN {{traffic_source}} = 'Affiliate' THEN players.affiliate_id IS NOT NULL
      ELSE TRUE
    END ]]
    [[ AND {{affiliate_id}} ]]
    [[ AND {{affiliate_name}} ]]
    [[ AND CONCAT(players.os, ' / ', players.browser) = {{registration_launcher}} ]]
    [[ AND {{is_test_account}} ]]
),

/* ---------- REGISTRATION SNAPSHOT ---------- */
player_reg AS (
  SELECT
    p.id AS player_id,
    p.created_at AS registration_ts,
    p.email_verified,
    c.name AS brand_name
  FROM players p
  INNER JOIN filtered_players fp ON p.id = fp.player_id
  LEFT JOIN companies c ON p.company_id = c.id
),

registrations AS (
  SELECT
    ds.report_date,
    COUNT(pr.*) AS total_registrations,
    COUNT(CASE WHEN pr.email_verified = TRUE THEN 1 END) AS complete_registrations
  FROM date_series ds
  LEFT JOIN player_reg pr
    ON pr.registration_ts >= ds.start_ts
    AND pr.registration_ts < ds.end_ts
  GROUP BY ds.report_date
),

/* ---------- GLOBAL FTD (TRUE FIRST DEPOSIT EVER) ---------- */
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
ftd_first AS (
  SELECT
    fad.player_id,
    fad.created_at AS first_deposit_ts
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

ftds AS (
  SELECT
    DATE_TRUNC('day', ff.first_deposit_ts)::date AS report_date,
    pr.player_id,
    pr.registration_ts,
    ff.first_deposit_ts
  FROM ftd_first ff
  JOIN player_reg pr ON pr.player_id = ff.player_id
),

ftd_metrics AS (
  SELECT
    ds.report_date,
    COUNT(DISTINCT f.player_id) AS ftds_count,
    COUNT(*) FILTER (WHERE f.registration_ts >= (SELECT start_date FROM bounds)) AS new_ftds,
    COUNT(*) FILTER (WHERE f.registration_ts < (SELECT start_date FROM bounds)) AS old_ftds,
    COUNT(*) FILTER (WHERE DATE_TRUNC('day', f.registration_ts) = DATE_TRUNC('day', f.first_deposit_ts)) AS d0_ftds,
    COUNT(*) FILTER (WHERE DATE_TRUNC('day', f.registration_ts) <> DATE_TRUNC('day', f.first_deposit_ts)) AS late_ftds
  FROM date_series ds
  LEFT JOIN ftds f ON f.report_date = ds.report_date
  GROUP BY ds.report_date
),

/* ---------- DEPOSITS (WITH NULL-SAFE CURRENCY LOGIC) ---------- */
deposit_metrics AS (
  SELECT
    ds.report_date,
    COUNT(DISTINCT t.player_id) FILTER (
      WHERE t.transaction_category='deposit'
        AND t.transaction_type='credit'
        AND t.status='completed'
        AND t.balance_type='withdrawable'
    ) AS unique_depositors,
    COUNT(*) FILTER (
      WHERE t.transaction_category='deposit'
        AND t.transaction_type='credit'
        AND t.status='completed'
        AND t.balance_type='withdrawable'
    ) AS deposits_count,
    COALESCE(SUM(CASE
      WHEN t.transaction_category='deposit'
       AND t.transaction_type='credit'
       AND t.status='completed'
       AND t.balance_type='withdrawable'
      THEN CASE 
        WHEN {{currency_filter}} = 'EUR' 
        THEN COALESCE(t.eur_amount, 0)  -- NULL-safe EUR conversion
        ELSE t.amount 
      END 
    END), 0) AS deposits_amount
  FROM date_series ds
  LEFT JOIN transactions t
    ON t.created_at >= ds.start_ts
    AND t.created_at < ds.end_ts
  INNER JOIN filtered_players fp ON t.player_id = fp.player_id
  WHERE 1=1
    [[ AND CASE 
      WHEN {{currency_filter}} != 'EUR' 
      THEN UPPER(t.currency_type) IN ({{currency_filter}})
      ELSE TRUE
    END ]]
  GROUP BY ds.report_date
),

/* ---------- WITHDRAWALS (WITH NULL-SAFE CURRENCY LOGIC) ---------- */
withdrawal_metrics AS (
  SELECT
    ds.report_date,
    COUNT(t.id) FILTER (
      WHERE t.transaction_category='withdrawal'
        AND t.transaction_type='debit'
        AND t.balance_type='withdrawable'
        AND t.status='completed'
    ) AS withdrawals_count,
    COALESCE(SUM(ABS(
      CASE 
        WHEN {{currency_filter}} = 'EUR' 
        THEN COALESCE(t.eur_amount, t.amount)
        ELSE t.amount 
      END
    )) FILTER (
      WHERE t.transaction_category='withdrawal'
        AND t.transaction_type='debit'
        AND t.balance_type='withdrawable'
        AND t.status='completed'
    ), 0) AS withdrawals_amount,
    COALESCE(SUM(ABS(
      CASE 
        WHEN {{currency_filter}} = 'EUR' 
        THEN COALESCE(t.eur_amount, t.amount)
        ELSE t.amount 
      END
    )) FILTER (
      WHERE t.transaction_category='withdrawal'
        AND t.transaction_type='debit'
        AND t.balance_type='withdrawable'
        AND t.status='cancelled'
    ), 0) AS withdrawals_cancelled
  FROM date_series ds
  LEFT JOIN transactions t
    ON t.created_at >= ds.start_ts
    AND t.created_at < ds.end_ts
  INNER JOIN filtered_players fp ON t.player_id = fp.player_id
  WHERE 1=1
    [[ AND CASE 
      WHEN {{currency_filter}} != 'EUR' 
      THEN UPPER(t.currency_type) IN ({{currency_filter}})
      ELSE TRUE
    END ]]
  GROUP BY ds.report_date
),

/* ---------- ACTIVE PLAYERS ---------- */
active_players AS (
  SELECT
    ds.report_date,
    COUNT(DISTINCT CASE WHEN t.transaction_category='game_bet' THEN t.player_id END) AS active_players_count,
    COUNT(DISTINCT CASE WHEN t.transaction_category='game_bet' AND t.balance_type='withdrawable' THEN t.player_id END) AS real_active_players
  FROM date_series ds
  LEFT JOIN transactions t
    ON t.created_at >= ds.start_ts
    AND t.created_at < ds.end_ts
  INNER JOIN filtered_players fp ON t.player_id = fp.player_id
  WHERE 1=1
    [[ AND CASE 
      WHEN {{currency_filter}} != 'EUR' 
      THEN UPPER(t.currency_type) IN ({{currency_filter}})
      ELSE TRUE
    END ]]
  GROUP BY ds.report_date
),

/* ---------- BETTING METRICS (WITH NULL-SAFE CURRENCY LOGIC) ---------- */
betting_metrics AS (
  SELECT
    ds.report_date,
    COALESCE(SUM(CASE
      WHEN t.transaction_type='debit'
       AND t.transaction_category='game_bet'
       AND t.balance_type='withdrawable'
       AND t.status='completed'
      THEN CASE 
        WHEN {{currency_filter}} = 'EUR' 
        THEN COALESCE(t.eur_amount, t.amount)
        ELSE t.amount 
      END
    END), 0) AS cash_bet,
    COALESCE(SUM(CASE
      WHEN t.transaction_type='credit'
       AND t.transaction_category='game_bet'
       AND t.balance_type='withdrawable'
       AND t.status='completed'
      THEN CASE 
        WHEN {{currency_filter}} = 'EUR' 
        THEN COALESCE(t.eur_amount, t.amount)
        ELSE t.amount 
      END
    END), 0) AS cash_win,
    /* PROMO BET - Updated to use external_transaction_id per CTO requirements */
    COALESCE(SUM(CASE
      WHEN t.transaction_type='debit'
       AND t.transaction_category='bonus'
       AND t.status='completed'
       AND t.external_transaction_id IS NOT NULL
      THEN CASE
        WHEN {{currency_filter}} = 'EUR'
        THEN COALESCE(t.eur_amount, t.amount)
        ELSE t.amount
      END
    END), 0) AS promo_bet,
    /* PROMO WIN - Updated to use external_transaction_id per CTO requirements */
    COALESCE(SUM(CASE
      WHEN t.transaction_type='credit'
       AND t.transaction_category='bonus'
       AND t.status='completed'
       AND t.external_transaction_id IS NOT NULL
      THEN CASE
        WHEN {{currency_filter}} = 'EUR'
        THEN COALESCE(t.eur_amount, t.amount)
        ELSE t.amount
      END
    END), 0) AS promo_win
  FROM date_series ds
  LEFT JOIN transactions t
    ON t.created_at >= ds.start_ts
    AND t.created_at < ds.end_ts
  INNER JOIN filtered_players fp ON t.player_id = fp.player_id
  WHERE 1=1
    [[ AND CASE 
      WHEN {{currency_filter}} != 'EUR' 
      THEN UPPER(t.currency_type) IN ({{currency_filter}})
      ELSE TRUE
    END ]]
  GROUP BY ds.report_date
),

/* ---------- BONUS METRICS (WITH NULL-SAFE CURRENCY LOGIC) ---------- */
bonus_converted AS (
  SELECT
    ds.report_date,
    COALESCE(SUM(CASE
      WHEN t.transaction_type='credit'
       AND t.transaction_category='bonus_completion'
       AND t.status='completed'
       AND t.balance_type='withdrawable'
      THEN CASE 
        WHEN {{currency_filter}} = 'EUR' 
        THEN COALESCE(t.eur_amount, t.amount)
        ELSE t.amount 
      END
    END), 0) AS bonus_converted_amount
  FROM date_series ds
  LEFT JOIN transactions t
    ON t.created_at >= ds.start_ts
    AND t.created_at < ds.end_ts
  INNER JOIN filtered_players fp ON t.player_id = fp.player_id
  WHERE 1=1
    [[ AND CASE 
      WHEN {{currency_filter}} != 'EUR' 
      THEN UPPER(t.currency_type) IN ({{currency_filter}})
      ELSE TRUE
    END ]]
  GROUP BY ds.report_date
),

bonus_cost AS (
  SELECT
    ds.report_date,
    COALESCE(SUM(CASE
      WHEN t.transaction_type='credit'
       AND t.balance_type='withdrawable'
       AND t.status='completed'
       AND t.transaction_category='bonus_completion'
      THEN CASE
        WHEN {{currency_filter}} = 'EUR'
        THEN COALESCE(t.eur_amount, t.amount)
        ELSE t.amount
      END
    END), 0) AS total_bonus_cost
  FROM date_series ds
  LEFT JOIN transactions t
    ON t.created_at >= ds.start_ts
    AND t.created_at < ds.end_ts
  INNER JOIN filtered_players fp ON t.player_id = fp.player_id
  WHERE 1=1
    [[ AND CASE
      WHEN {{currency_filter}} != 'EUR'
      THEN UPPER(t.currency_type) IN ({{currency_filter}})
      ELSE TRUE
    END ]]
  GROUP BY ds.report_date
),

/* ---------- GRANTED BONUS (NEW COLUMN) ---------- */
granted_bonus AS (
  SELECT
    ds.report_date,
    COALESCE(SUM(CASE
      -- Regular bonus credits
      WHEN t.transaction_category = 'bonus'
       AND t.transaction_type = 'credit'
       AND t.status = 'completed'
       AND t.balance_type = 'non-withdrawable'
      THEN CASE
        WHEN {{currency_filter}} = 'EUR'
        THEN COALESCE(t.eur_amount, t.amount)
        ELSE t.amount
      END

      -- Free spin bonus
      WHEN t.transaction_category = 'free_spin_bonus'
       AND t.transaction_type = 'credit'
       AND t.status = 'completed'
       AND t.balance_type = 'non-withdrawable'
      THEN CASE
        WHEN {{currency_filter}} = 'EUR'
        THEN COALESCE(t.eur_amount, t.amount)
        ELSE t.amount
      END

      -- Free bet wins
      WHEN t.transaction_category IN ('free_bet', 'free_bet_win', 'freebet_win')
       AND t.transaction_type = 'credit'
       AND t.status = 'completed'
       AND t.balance_type = 'non-withdrawable'
      THEN CASE
        WHEN {{currency_filter}} = 'EUR'
        THEN COALESCE(t.eur_amount, t.amount)
        ELSE t.amount
      END

      -- Bonus completion (non-withdrawable portion)
      WHEN t.transaction_category = 'bonus_completion'
       AND t.transaction_type = 'credit'
       AND t.status = 'completed'
       AND t.balance_type = 'non-withdrawable'
      THEN CASE
        WHEN {{currency_filter}} = 'EUR'
        THEN COALESCE(t.eur_amount, t.amount)
        ELSE t.amount
      END
    END), 0) AS granted_bonus_amount
  FROM date_series ds
  LEFT JOIN transactions t
    ON t.created_at >= ds.start_ts
    AND t.created_at < ds.end_ts
  INNER JOIN filtered_players fp ON t.player_id = fp.player_id
  WHERE 1=1
    [[ AND CASE
      WHEN {{currency_filter}} != 'EUR'
      THEN UPPER(t.currency_type) IN ({{currency_filter}})
      ELSE TRUE
    END ]]
  GROUP BY ds.report_date
),

/* ---------- PREPARE DAILY DATA ---------- */
daily_data AS (
  SELECT 
    0 as sort_order,
    ds.report_date::text AS "Date",
    COALESCE(r.total_registrations, 0) AS "#Registrations",
    COALESCE(fm.ftds_count, 0) AS "#FTDs",
    COALESCE(fm.new_ftds, 0) AS "#New FTDs",
    ROUND(CASE WHEN COALESCE(fm.ftds_count,0) > 0 
               THEN fm.new_ftds::numeric / fm.ftds_count * 100 ELSE 0 END, 2) AS "%New FTDs",
    COALESCE(fm.old_ftds, 0) AS "#Old FTDs",
    ROUND(CASE WHEN COALESCE(fm.ftds_count,0) > 0 
               THEN fm.old_ftds::numeric / fm.ftds_count * 100 ELSE 0 END, 2) AS "% Old FTDs",
    COALESCE(fm.d0_ftds, 0) AS "#D0 FTDs",
    ROUND(CASE WHEN COALESCE(fm.ftds_count,0) > 0 
               THEN fm.d0_ftds::numeric / fm.ftds_count * 100 ELSE 0 END, 2) AS "%D0 FTDs",
    COALESCE(fm.late_ftds, 0) AS "#Late FTDs",
    ROUND(CASE WHEN COALESCE(r.total_registrations,0) > 0 
               THEN COALESCE(fm.ftds_count,0)::numeric / r.total_registrations * 100 ELSE 0 END, 2) AS "%Conversion total reg",
    ROUND(CASE WHEN COALESCE(r.complete_registrations,0) > 0 
               THEN COALESCE(fm.ftds_count,0)::numeric / r.complete_registrations * 100 ELSE 0 END, 2) AS "%Conversion complete reg",
    COALESCE(dm.unique_depositors, 0) AS "Unique Depositors",
    COALESCE(dm.deposits_count, 0) AS "#Deposits",
    ROUND(COALESCE(dm.deposits_amount, 0), 2) AS "Deposits Amount",
    COALESCE(wm.withdrawals_count, 0) AS "#Withdrawals",
    ROUND(COALESCE(wm.withdrawals_amount, 0), 2) AS "Withdrawals Amount",
    ROUND(COALESCE(wm.withdrawals_cancelled, 0), 2) AS "Withdrawals Amount Canceled",
    ROUND(CASE WHEN COALESCE(dm.deposits_amount,0) > 0 
               THEN COALESCE(wm.withdrawals_amount,0) / dm.deposits_amount * 100 ELSE 0 END, 2) AS "%Withdrawals/Deposits",
    ROUND(COALESCE(dm.deposits_amount,0) - COALESCE(wm.withdrawals_amount, 0), 2) AS "CashFlow",
    COALESCE(ap.active_players_count, 0) AS "Active Players",
    COALESCE(ap.real_active_players, 0) AS "Real Active Players",
    ROUND(COALESCE(bet.cash_bet, 0), 2) AS "Cash Bet",
    ROUND(COALESCE(bet.cash_win, 0), 2) AS "Cash Win",
    ROUND(COALESCE(bet.promo_bet, 0), 2) AS "Promo bet",
    ROUND(COALESCE(bet.promo_win, 0), 2) AS "Promo Win",
    ROUND(COALESCE(bet.cash_bet,0) + COALESCE(bet.promo_bet,0), 2) AS "Turnover",
    ROUND(COALESCE(bet.cash_bet,0) + COALESCE(bet.promo_bet,0), 2) AS "Turnover Casino",
    ROUND(COALESCE(bet.cash_bet,0) + COALESCE(bet.promo_bet,0)
        - COALESCE(bet.cash_win,0)
        - COALESCE(bet.promo_win,0), 2) AS "GGR",
    ROUND(COALESCE(bet.cash_bet,0) + COALESCE(bet.promo_bet,0)
        - COALESCE(bet.cash_win,0)
        - COALESCE(bet.promo_win,0), 2) AS "GGR Casino",
    ROUND(COALESCE(bet.cash_bet,0) - COALESCE(bet.cash_win,0), 2) AS "Cash GGR",
    ROUND(COALESCE(bet.cash_bet,0) - COALESCE(bet.cash_win,0), 2) AS "Cash GGR Casino",
    ROUND(COALESCE(bc.bonus_converted_amount, 0), 2) AS "Bonus Converted (Gross)",
    ROUND(COALESCE(bcost.total_bonus_cost, 0), 2) AS "Bonus Cost",
    ROUND(COALESCE(gb.granted_bonus_amount, 0), 2) AS "Granted Bonus",
    ROUND(CASE 
        WHEN (COALESCE(bet.cash_bet,0) + COALESCE(bet.promo_bet,0)
             - COALESCE(bet.cash_win,0)
             - COALESCE(bet.promo_win,0)) > 0 
        THEN COALESCE(bcost.total_bonus_cost,0) / 
             (COALESCE(bet.cash_bet,0) + COALESCE(bet.promo_bet,0)
             - COALESCE(bet.cash_win,0)
             - COALESCE(bet.promo_win,0)) * 100 
        ELSE 0 END, 2) AS "Bonus Ratio (GGR)",
    ROUND(CASE WHEN COALESCE(dm.deposits_amount,0) > 0 
               THEN COALESCE(bcost.total_bonus_cost,0) / dm.deposits_amount * 100 ELSE 0 END, 2) AS "Bonus Ratio (Deposits)",
    ROUND(CASE 
        WHEN (COALESCE(bet.cash_bet,0) + COALESCE(bet.promo_bet,0)) > 0 
        THEN (COALESCE(bet.cash_win,0) + COALESCE(bet.promo_win,0)) / 
             (COALESCE(bet.cash_bet,0) + COALESCE(bet.promo_bet,0)) * 100 
        ELSE 0 END, 2) AS "Payout %",
    ROUND(CASE 
        WHEN (COALESCE(bet.cash_bet,0) + COALESCE(bet.promo_bet,0)
             - COALESCE(bet.cash_win,0)
             - COALESCE(bet.promo_win,0)) > 0
        THEN (COALESCE(dm.deposits_amount,0) - COALESCE(wm.withdrawals_amount,0)) /
             (COALESCE(bet.cash_bet,0) + COALESCE(bet.promo_bet,0)
             - COALESCE(bet.cash_win,0)
             - COALESCE(bet.promo_win,0)) * 100
        ELSE 0 END, 2) AS "%CashFlow to GGR"
  FROM date_series ds
  LEFT JOIN registrations r ON r.report_date = ds.report_date
  LEFT JOIN ftd_metrics fm ON fm.report_date = ds.report_date
  LEFT JOIN deposit_metrics dm ON dm.report_date = ds.report_date
  LEFT JOIN withdrawal_metrics wm ON wm.report_date = ds.report_date
  LEFT JOIN active_players ap ON ap.report_date = ds.report_date
  LEFT JOIN betting_metrics bet ON bet.report_date = ds.report_date
  LEFT JOIN bonus_converted bc ON bc.report_date = ds.report_date
  LEFT JOIN bonus_cost bcost ON bcost.report_date = ds.report_date
  LEFT JOIN granted_bonus gb ON gb.report_date = ds.report_date
)

/* ========== FINAL OUTPUT WITH TOTAL ROW ========== */
SELECT 
  -1 as sort_order,
  'TOTAL' AS "Date",
  SUM("#Registrations") AS "#Registrations",
  SUM("#FTDs") AS "#FTDs",
  SUM("#New FTDs") AS "#New FTDs",
  ROUND(CASE WHEN SUM("#FTDs") > 0 
             THEN SUM("#New FTDs")::numeric / SUM("#FTDs") * 100 ELSE 0 END, 2) AS "%New FTDs",
  SUM("#Old FTDs") AS "#Old FTDs",
  ROUND(CASE WHEN SUM("#FTDs") > 0 
             THEN SUM("#Old FTDs")::numeric / SUM("#FTDs") * 100 ELSE 0 END, 2) AS "% Old FTDs",
  SUM("#D0 FTDs") AS "#D0 FTDs",
  ROUND(CASE WHEN SUM("#FTDs") > 0 
             THEN SUM("#D0 FTDs")::numeric / SUM("#FTDs") * 100 ELSE 0 END, 2) AS "%D0 FTDs",
  SUM("#Late FTDs") AS "#Late FTDs",
  ROUND(CASE WHEN SUM("#Registrations") > 0 
             THEN SUM("#FTDs")::numeric / SUM("#Registrations") * 100 ELSE 0 END, 2) AS "%Conversion total reg",
  
  -- Complete registration conversion for entire period
  (SELECT ROUND(
    CASE WHEN COUNT(CASE WHEN pr.email_verified = TRUE THEN 1 END) > 0
         THEN COUNT(DISTINCT CASE WHEN ff.first_deposit_ts IS NOT NULL THEN ff.player_id END)::numeric / 
              COUNT(CASE WHEN pr.email_verified = TRUE THEN 1 END) * 100 
         ELSE 0 END, 2)
   FROM player_reg pr
   LEFT JOIN ftd_first ff ON pr.player_id = ff.player_id
   WHERE pr.registration_ts >= (SELECT start_date FROM bounds)
     AND pr.registration_ts < (SELECT end_date FROM bounds) + INTERVAL '1 day'
  ) AS "%Conversion complete reg",
  
  -- Unique depositors for entire period
  (SELECT COUNT(DISTINCT t.player_id)
   FROM transactions t
   INNER JOIN filtered_players fp ON t.player_id = fp.player_id
   WHERE t.transaction_category='deposit'
     AND t.transaction_type='credit'
     AND t.status='completed'
     AND t.balance_type='withdrawable'
     AND t.created_at >= (SELECT start_date FROM bounds)
     AND t.created_at < (SELECT end_date FROM bounds) + INTERVAL '1 day'
     [[ AND CASE 
       WHEN {{currency_filter}} != 'EUR' 
       THEN UPPER(t.currency_type) IN ({{currency_filter}})
       ELSE TRUE
     END ]]
  ) AS "Unique Depositors",
  
  SUM("#Deposits") AS "#Deposits",
  ROUND(SUM("Deposits Amount"), 2) AS "Deposits Amount",
  SUM("#Withdrawals") AS "#Withdrawals",
  ROUND(SUM("Withdrawals Amount"), 2) AS "Withdrawals Amount",
  ROUND(SUM("Withdrawals Amount Canceled"), 2) AS "Withdrawals Amount Canceled",
  ROUND(CASE WHEN SUM("Deposits Amount") > 0 
             THEN SUM("Withdrawals Amount") / SUM("Deposits Amount") * 100 ELSE 0 END, 2) AS "%Withdrawals/Deposits",
  ROUND(SUM("CashFlow"), 2) AS "CashFlow",
  
  -- Active players for entire period  
  (SELECT COUNT(DISTINCT t.player_id)
   FROM transactions t
   INNER JOIN filtered_players fp ON t.player_id = fp.player_id
   WHERE t.transaction_category='game_bet'
     AND t.created_at >= (SELECT start_date FROM bounds)
     AND t.created_at < (SELECT end_date FROM bounds) + INTERVAL '1 day'
     [[ AND CASE 
       WHEN {{currency_filter}} != 'EUR' 
       THEN UPPER(t.currency_type) IN ({{currency_filter}})
       ELSE TRUE
     END ]]
  ) AS "Active Players",
  
  -- Real active players for entire period
  (SELECT COUNT(DISTINCT t.player_id)
   FROM transactions t
   INNER JOIN filtered_players fp ON t.player_id = fp.player_id
   WHERE t.transaction_category='game_bet'
     AND t.balance_type='withdrawable'
     AND t.created_at >= (SELECT start_date FROM bounds)
     AND t.created_at < (SELECT end_date FROM bounds) + INTERVAL '1 day'
     [[ AND CASE 
       WHEN {{currency_filter}} != 'EUR' 
       THEN UPPER(t.currency_type) IN ({{currency_filter}})
       ELSE TRUE
     END ]]
  ) AS "Real Active Players",
  
  ROUND(SUM("Cash Bet"), 2) AS "Cash Bet",
  ROUND(SUM("Cash Win"), 2) AS "Cash Win",
  ROUND(SUM("Promo bet"), 2) AS "Promo bet",
  ROUND(SUM("Promo Win"), 2) AS "Promo Win",
  ROUND(SUM("Turnover"), 2) AS "Turnover",
  ROUND(SUM("Turnover Casino"), 2) AS "Turnover Casino",
  ROUND(SUM("GGR"), 2) AS "GGR",
  ROUND(SUM("GGR Casino"), 2) AS "GGR Casino",
  ROUND(SUM("Cash GGR"), 2) AS "Cash GGR",
  ROUND(SUM("Cash GGR Casino"), 2) AS "Cash GGR Casino",
  ROUND(SUM("Bonus Converted (Gross)"), 2) AS "Bonus Converted (Gross)",
  ROUND(SUM("Bonus Cost"), 2) AS "Bonus Cost",
  ROUND(SUM("Granted Bonus"), 2) AS "Granted Bonus",
  ROUND(CASE WHEN SUM("GGR") > 0 
             THEN SUM("Bonus Cost") / SUM("GGR") * 100 ELSE 0 END, 2) AS "Bonus Ratio (GGR)",
  ROUND(CASE WHEN SUM("Deposits Amount") > 0 
             THEN SUM("Bonus Cost") / SUM("Deposits Amount") * 100 ELSE 0 END, 2) AS "Bonus Ratio (Deposits)",
  ROUND(CASE WHEN SUM("Turnover") > 0 
             THEN (SUM("Cash Win") + SUM("Promo Win")) / SUM("Turnover") * 100 ELSE 0 END, 2) AS "Payout %",
  ROUND(CASE WHEN SUM("GGR") > 0 
             THEN SUM("CashFlow") / SUM("GGR") * 100 ELSE 0 END, 2) AS "%CashFlow to GGR"
FROM daily_data

UNION ALL

SELECT * FROM daily_data

ORDER BY sort_order, "Date" DESC;
