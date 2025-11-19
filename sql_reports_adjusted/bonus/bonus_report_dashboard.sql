-- =====================================================
-- BONUS REPORT DASHBOARD - CORRECTED v3.2 (CTO-APPROVED STANDARDS)
-- FIXED: Duplicate rows removed + company filter removed
-- FIXED: All currency calculations now use 3-level hierarchy (CTO-approved)
-- 25 filters working correctly
-- =====================================================

WITH pb_scope AS (
    SELECT DISTINCT ON (
      player_bonuses.id,
      bonuses.id,
      players.id,
      companies.id
    )
      player_bonuses.id AS player_bonus_id,
      player_bonuses.bonus_id AS bonus_id,
      player_bonuses.player_id AS player_id,
      player_bonuses.bonus_amount AS bonus_amount,
      COALESCE(player_bonuses.free_spins_count, 0) AS free_spins_granted,
      player_bonuses.activated_at AS activated_at,
      player_bonuses.status AS lifecycle_status,
      player_bonuses.trigger_transaction_id AS trigger_transaction_id,
      player_bonuses.wagering_multiplier AS wager_factor,
      player_bonuses.wagering_condition AS wagering_condition,
      bonuses.title AS campaign_name,
      bonuses.bonus_type AS campaign_category,
      bonuses.bonus_code,
      (bonuses.terms -> 'trigger' ->> 'type') AS bonus_trigger,
      (bonuses.terms -> 'expiry' ->> 'value') AS wager_time_value,
      (bonuses.terms -> 'expiry' ->> 'unit') AS wager_time_unit,
      (bonuses.terms -> 'unlock_expiration' ->> 'value') AS bonus_availability_value,
      (bonuses.terms -> 'unlock_expiration' ->> 'unit') AS bonus_availability_unit,
      (bonuses.terms -> 'reward' ->> 'max_reward') AS max_bonus_reward,
      (bonuses.terms -> 'wagering' ->> 'max_release') AS max_bonus_release,
      (bonuses.terms -> 'reward' ->> 'percentage_amount') AS percentage_amount,
      (bonuses.terms -> 'reward' ->> 'min_deposit') AS minimum_deposit,
      (bonuses.terms -> 'wagering' ->> 'max_bet') AS max_bet,
      bonuses.free_spins AS fs_wagering_factor,
      brands.name AS brand_name,
      companies.name AS company_name,
      players.country AS player_country,
      players.is_test_account,
      players.affiliate_id,
      COALESCE(pa.metadata::jsonb->>'affiliate_name', 'UNASSIGNED') AS affiliate_name,
      COALESCE(promotions.template_code, 'UNASSIGNED') AS template_code,
      CONCAT(players.os, ' / ', players.browser) AS registration_launcher,
      CASE 
        WHEN players.affiliate_id IS NOT NULL THEN 'AFFILIATE'
        ELSE 'ORGANIC'
      END AS traffic_source
    FROM
      player_bonuses
      JOIN bonuses ON bonuses.id = player_bonuses.bonus_id
      LEFT JOIN brands ON brands.id = player_bonuses.brand_id
      JOIN players ON players.id = player_bonuses.player_id
      JOIN companies ON companies.id = players.company_id
      LEFT JOIN player_affiliates pa ON pa.player_id = players.id
      LEFT JOIN promotion_bonuses ON promotion_bonuses.bonus_id = bonuses.id
      LEFT JOIN promotions ON promotions.id = promotion_bonuses.promotion_id
    WHERE
      1 = 1	

      -- Campaign filters (18)
      [[AND {{brand_filter}}]] 
      [[AND {{campaign_name_filter}}]] 
      [[AND {{promotion_name_filter}}]]
      [[AND {{template_code_filter}}]]
      [[AND {{player_filter}}]]
      [[AND {{campaign_category_filter}}]]
      [[AND {{bonus_trigger_filter}}]]
      [[AND {{lifecycle_filter}}]]
      [[AND {{wager_factor_filter}}]]
      [[AND {{wagering_condition_filter}}]]
      [[AND {{wager_time_filter}}]]
      [[AND {{bonus_availability_filter}}]]
      [[AND {{max_bonus_reward_filter}}]]
      [[AND {{max_bonus_release_filter}}]]
      [[AND {{percentage_amount_filter}}]]
      [[AND {{minimum_deposit_filter}}]]
      [[AND {{max_bet_filter}}]]
      [[AND {{fs_wagering_factor_filter}}]]
      
      -- Organizational filters (4)
      [[AND {{traffic_source_filter}}]]
      [[AND {{date_range_filter}}]]
      
      -- Player attribute filters (3)
      [[AND CONCAT(players.os, ' / ', players.browser) = {{registration_launcher_filter}}]]
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
      
      -- Affiliate filters (2)
      [[ AND {{affiliate_id}} ]]
      [[ AND {{affiliate_name}} ]]
      
      -- Test account filter
      [[ AND {{is_test_account}} ]]
    
    ORDER BY player_bonuses.id, bonuses.id, players.id, companies.id
  ),
  
  tx_scope_bonus AS (
    SELECT
      transactions.*,
      pb_scope.player_bonus_id,
      pb_scope.bonus_id AS pb_bonus_id,
      pb_scope.free_spins_granted
    FROM
      pb_scope
      JOIN transactions ON transactions.player_bonus_id = pb_scope.player_bonus_id
    WHERE
      1 = 1
  ),
  
  dep_tx_scope AS (
    SELECT
      transactions.*,
      pb_scope.player_bonus_id,
      pb_scope.bonus_id AS pb_bonus_id
    FROM
      pb_scope
      JOIN transactions ON transactions.id = pb_scope.trigger_transaction_id
    WHERE
      1 = 1
  ),
  
  -- DEPOSITS
  dep AS (
    SELECT
      dep_tx_scope.pb_bonus_id AS bonus_id,
      SUM(
        CASE
          WHEN dep_tx_scope.transaction_category = 'deposit'
          AND dep_tx_scope.transaction_type = 'credit'
          AND dep_tx_scope.status = 'completed'
          THEN CASE
            -- ✅ FIXED: 3-level currency hierarchy (CTO-approved)
            WHEN dep_tx_scope.currency_type = {{currency_filter}} THEN dep_tx_scope.amount
            WHEN {{currency_filter}} = 'EUR' THEN COALESCE(dep_tx_scope.eur_amount, dep_tx_scope.amount)
            ELSE dep_tx_scope.amount
          END
          ELSE 0
        END
      ) AS deposit_amount
    FROM dep_tx_scope
    GROUP BY dep_tx_scope.pb_bonus_id
  ),
  
  -- GRANTED CASH (from BO_DEPOSIT)
  granted_cash AS (
    SELECT
      tx_scope_bonus.pb_bonus_id AS bonus_id,
      SUM(
        CASE
          WHEN tx_scope_bonus.transaction_category = 'BO_DEPOSIT'
          AND tx_scope_bonus.transaction_type = 'credit'
          AND tx_scope_bonus.status = 'completed'
          AND tx_scope_bonus.balance_type = 'withdrawable'
          THEN CASE
            -- ✅ FIXED: 3-level currency hierarchy (CTO-approved)
            WHEN tx_scope_bonus.currency_type = {{currency_filter}} THEN tx_scope_bonus.amount
            WHEN {{currency_filter}} = 'EUR' THEN COALESCE(tx_scope_bonus.eur_amount, tx_scope_bonus.amount)
            ELSE tx_scope_bonus.amount
          END
          ELSE 0
        END
      ) AS granted_cash_amount
    FROM tx_scope_bonus
    GROUP BY tx_scope_bonus.pb_bonus_id
  ),
  
  -- GRANTED BONUS
  granted_bonus AS (
    SELECT
      tx_scope_bonus.pb_bonus_id AS bonus_id,
      SUM(
        CASE
          WHEN tx_scope_bonus.transaction_category = 'bonus'
          AND tx_scope_bonus.transaction_type = 'credit'
          AND tx_scope_bonus.status = 'completed'
          AND tx_scope_bonus.balance_type = 'non-withdrawable'
          THEN CASE
            -- ✅ FIXED: 3-level currency hierarchy (CTO-approved)
            WHEN tx_scope_bonus.currency_type = {{currency_filter}} THEN tx_scope_bonus.amount
            WHEN {{currency_filter}} = 'EUR' THEN COALESCE(tx_scope_bonus.eur_amount, tx_scope_bonus.amount)
            ELSE tx_scope_bonus.amount
          END

          WHEN tx_scope_bonus.transaction_category = 'free_spin_bonus'
          AND tx_scope_bonus.transaction_type = 'credit'
          AND tx_scope_bonus.status = 'completed'
          AND tx_scope_bonus.balance_type = 'non-withdrawable'
          THEN CASE
            WHEN tx_scope_bonus.currency_type = {{currency_filter}} THEN tx_scope_bonus.amount
            WHEN {{currency_filter}} = 'EUR' THEN COALESCE(tx_scope_bonus.eur_amount, tx_scope_bonus.amount)
            ELSE tx_scope_bonus.amount
          END

          WHEN tx_scope_bonus.transaction_category IN ('free_bet', 'free_bet_win', 'freebet_win')
          AND tx_scope_bonus.transaction_type = 'credit'
          AND tx_scope_bonus.status = 'completed'
          AND tx_scope_bonus.balance_type = 'non-withdrawable'
          THEN CASE
            WHEN tx_scope_bonus.currency_type = {{currency_filter}} THEN tx_scope_bonus.amount
            WHEN {{currency_filter}} = 'EUR' THEN COALESCE(tx_scope_bonus.eur_amount, tx_scope_bonus.amount)
            ELSE tx_scope_bonus.amount
          END

          WHEN tx_scope_bonus.transaction_category = 'bonus_completion'
          AND tx_scope_bonus.transaction_type = 'credit'
          AND tx_scope_bonus.status = 'completed'
          AND tx_scope_bonus.balance_type = 'non-withdrawable'
          THEN CASE
            WHEN tx_scope_bonus.currency_type = {{currency_filter}} THEN tx_scope_bonus.amount
            WHEN {{currency_filter}} = 'EUR' THEN COALESCE(tx_scope_bonus.eur_amount, tx_scope_bonus.amount)
            ELSE tx_scope_bonus.amount
          END

          ELSE 0
        END
      ) AS granted_bonus_amount
    FROM tx_scope_bonus
    GROUP BY tx_scope_bonus.pb_bonus_id
  ),
  
  -- BONUS CONVERTED TO CASH
  bonus_converted AS (
    SELECT
      tx_scope_bonus.pb_bonus_id AS bonus_id,
      SUM(
        CASE
          WHEN tx_scope_bonus.transaction_category = 'bonus_completion'
          AND tx_scope_bonus.transaction_type = 'credit'
          AND tx_scope_bonus.status = 'completed'
          AND tx_scope_bonus.balance_type = 'withdrawable'
          THEN CASE
            -- ✅ FIXED: 3-level currency hierarchy (CTO-approved)
            WHEN tx_scope_bonus.currency_type = {{currency_filter}} THEN tx_scope_bonus.amount
            WHEN {{currency_filter}} = 'EUR' THEN COALESCE(tx_scope_bonus.eur_amount, tx_scope_bonus.amount)
            ELSE tx_scope_bonus.amount
          END
          ELSE 0
        END
      ) AS bonus_converted_cash,
      COUNT(
        DISTINCT CASE
          WHEN tx_scope_bonus.transaction_category = 'bonus_completion'
          AND tx_scope_bonus.transaction_type = 'credit'
          AND tx_scope_bonus.status = 'completed'
          AND tx_scope_bonus.balance_type = 'withdrawable' THEN tx_scope_bonus.player_id
        END
      ) AS converted_players
    FROM tx_scope_bonus
    GROUP BY tx_scope_bonus.pb_bonus_id
  ),
  
  -- BONUS REVOKED
  bonus_revoked AS (
    SELECT
      bonus_id,
      COUNT(CASE WHEN lifecycle_status = 'cancelled' THEN 1 END) AS revoked_count,
      SUM(CASE WHEN lifecycle_status = 'cancelled' THEN bonus_amount ELSE 0 END) AS revoked_amount
    FROM pb_scope
    GROUP BY bonus_id
  ),
  
  -- FREE SPIN WINS
  free_spin_wins AS (
    SELECT
      tx_scope_bonus.pb_bonus_id AS bonus_id,
      SUM(
        CASE
          WHEN tx_scope_bonus.transaction_category = 'free_spin_bonus'
          AND tx_scope_bonus.transaction_type = 'credit'
          AND tx_scope_bonus.balance_type = 'non-withdrawable'
          AND tx_scope_bonus.status = 'completed'
          THEN CASE
            -- ✅ FIXED: 3-level currency hierarchy (CTO-approved)
            WHEN tx_scope_bonus.currency_type = {{currency_filter}} THEN tx_scope_bonus.amount
            WHEN {{currency_filter}} = 'EUR' THEN COALESCE(tx_scope_bonus.eur_amount, tx_scope_bonus.amount)
            ELSE tx_scope_bonus.amount
          END
          ELSE 0
        END
      ) AS free_spin_win_bonus,
      SUM(
        CASE
          WHEN tx_scope_bonus.transaction_category = 'free_spin_bonus'
          AND tx_scope_bonus.transaction_type = 'credit'
          AND tx_scope_bonus.balance_type = 'withdrawable'
          AND tx_scope_bonus.status = 'completed'
          THEN CASE
            WHEN tx_scope_bonus.currency_type = {{currency_filter}} THEN tx_scope_bonus.amount
            WHEN {{currency_filter}} = 'EUR' THEN COALESCE(tx_scope_bonus.eur_amount, tx_scope_bonus.amount)
            ELSE tx_scope_bonus.amount
          END
          ELSE 0
        END
      ) AS free_spin_win_cash
    FROM tx_scope_bonus
    GROUP BY tx_scope_bonus.pb_bonus_id
  ),
  
  -- BONUS COST
  bonus_cost AS (
    SELECT
      tx_scope_bonus.pb_bonus_id AS bonus_id,
      (
        SUM(
          CASE
            WHEN tx_scope_bonus.transaction_category = 'bonus'
            AND tx_scope_bonus.transaction_type = 'credit'
            AND tx_scope_bonus.status = 'completed'
            AND tx_scope_bonus.balance_type = 'withdrawable'
            THEN CASE
              -- ✅ FIXED: 3-level currency hierarchy (CTO-approved)
              WHEN tx_scope_bonus.currency_type = {{currency_filter}} THEN tx_scope_bonus.amount
              WHEN {{currency_filter}} = 'EUR' THEN COALESCE(tx_scope_bonus.eur_amount, tx_scope_bonus.amount)
              ELSE tx_scope_bonus.amount
            END
            ELSE 0
          END
        ) +
        SUM(
          CASE
            WHEN tx_scope_bonus.transaction_category = 'bonus_completion'
            AND tx_scope_bonus.transaction_type = 'credit'
            AND tx_scope_bonus.status = 'completed'
            AND tx_scope_bonus.balance_type = 'withdrawable'
            THEN CASE
              WHEN tx_scope_bonus.currency_type = {{currency_filter}} THEN tx_scope_bonus.amount
              WHEN {{currency_filter}} = 'EUR' THEN COALESCE(tx_scope_bonus.eur_amount, tx_scope_bonus.amount)
              ELSE tx_scope_bonus.amount
            END
            ELSE 0
          END
        ) +
        SUM(
          CASE
            WHEN tx_scope_bonus.transaction_category IN ('free_bet_win', 'free_bet', 'freebet_win')
            AND tx_scope_bonus.transaction_type = 'credit'
            AND tx_scope_bonus.status = 'completed'
            THEN CASE
              WHEN tx_scope_bonus.currency_type = {{currency_filter}} THEN tx_scope_bonus.amount
              WHEN {{currency_filter}} = 'EUR' THEN COALESCE(tx_scope_bonus.eur_amount, tx_scope_bonus.amount)
              ELSE tx_scope_bonus.amount
            END
            ELSE 0
          END
        ) +
        SUM(
          CASE
            WHEN tx_scope_bonus.transaction_category = 'BO_DEPOSIT'
            AND tx_scope_bonus.transaction_type = 'credit'
            AND tx_scope_bonus.status = 'completed'
            AND tx_scope_bonus.balance_type = 'withdrawable'
            THEN CASE
              WHEN tx_scope_bonus.currency_type = {{currency_filter}} THEN tx_scope_bonus.amount
              WHEN {{currency_filter}} = 'EUR' THEN COALESCE(tx_scope_bonus.eur_amount, tx_scope_bonus.amount)
              ELSE tx_scope_bonus.amount
            END
            ELSE 0
          END
        )
      ) AS bonus_cost
    FROM tx_scope_bonus
    GROUP BY tx_scope_bonus.pb_bonus_id
  ),
  
  -- AGGREGATED METRICS
  agg AS (
    SELECT
      pb_scope.bonus_id,
      MIN(pb_scope.campaign_name) AS campaign_name,
      MIN(pb_scope.campaign_category) AS campaign_category,
      COUNT(DISTINCT pb_scope.player_id) AS granted_players,
      SUM(pb_scope.bonus_amount) AS bonus_amount_granted,
      SUM(pb_scope.free_spins_granted) AS free_spins_granted,
      COALESCE(dep.deposit_amount, 0) AS deposit_amount,
      COALESCE(granted_cash.granted_cash_amount, 0) AS granted_cash,
      COALESCE(granted_bonus.granted_bonus_amount, 0) AS granted_bonus,
      COALESCE(bonus_revoked.revoked_amount, 0) AS bonus_revoked,
      COALESCE(bonus_converted.bonus_converted_cash, 0) AS bonus_converted_to_cash,
      COALESCE(bonus_converted.converted_players, 0) AS converted_players,
      COALESCE(free_spin_wins.free_spin_win_bonus, 0) AS free_spin_win_bonus,
      COALESCE(free_spin_wins.free_spin_win_cash, 0) AS free_spin_win_cash,
      COALESCE(bonus_cost.bonus_cost, 0) AS bonus_cost
    FROM
      pb_scope
      LEFT JOIN dep ON dep.bonus_id = pb_scope.bonus_id
      LEFT JOIN granted_cash ON granted_cash.bonus_id = pb_scope.bonus_id
      LEFT JOIN granted_bonus ON granted_bonus.bonus_id = pb_scope.bonus_id
      LEFT JOIN bonus_revoked ON bonus_revoked.bonus_id = pb_scope.bonus_id
      LEFT JOIN bonus_converted ON bonus_converted.bonus_id = pb_scope.bonus_id
      LEFT JOIN free_spin_wins ON free_spin_wins.bonus_id = pb_scope.bonus_id
      LEFT JOIN bonus_cost ON bonus_cost.bonus_id = pb_scope.bonus_id
    GROUP BY
      pb_scope.bonus_id,
      dep.deposit_amount,
      granted_cash.granted_cash_amount,
      granted_bonus.granted_bonus_amount,
      bonus_revoked.revoked_amount,
      bonus_converted.bonus_converted_cash,
      bonus_converted.converted_players,
      free_spin_wins.free_spin_win_bonus,
      free_spin_wins.free_spin_win_cash,
      bonus_cost.bonus_cost
  ),
  
  -- Detail Rows
  detail_rows AS (
    SELECT
      agg.campaign_name AS "CAMPAIGN NAME",
      agg.granted_players AS "BONUS GRANTED PLAYERS",
      ROUND(agg.bonus_cost, 2) AS "BONUS COST",
      ROUND(agg.deposit_amount, 2) AS "DEPOSIT AMOUNT",
      ROUND(
        CASE 
          WHEN agg.bonus_cost > 0 THEN ((agg.deposit_amount - agg.bonus_cost) / agg.bonus_cost) * 100
          ELSE NULL
        END, 1
      ) AS "ROI%",
      ROUND(agg.bonus_cost / NULLIF(agg.granted_players, 0), 2) AS "BONUS COST / PLAYER",
      ROUND(agg.deposit_amount / NULLIF(agg.granted_players, 0), 2) AS "DEPOSIT AMOUNT / PLAYER",
      ROUND(agg.granted_cash, 2) AS "GRANTED CASH",
      ROUND(agg.granted_bonus, 2) AS "GRANTED BONUS",
      ROUND(agg.bonus_revoked, 2) AS "BONUS REVOKED",
      ROUND(agg.bonus_converted_to_cash, 2) AS "BONUS CONVERTED (GROSS)",
      ROUND((agg.converted_players::numeric / NULLIF(agg.granted_players, 0)) * 100, 1) AS "% CONVERTED PLAYERS",
      ROUND(agg.granted_bonus / NULLIF(agg.granted_players, 0), 2) AS "GRANTED BONUS / PLAYER",
      ROUND(agg.bonus_converted_to_cash / NULLIF(agg.granted_players, 0), 2) AS "BONUS CONVERTED / PLAYER",
      agg.free_spins_granted AS "GRANTED FREESPINS",
      ROUND(agg.free_spin_win_bonus, 2) AS "FREESPINS WIN (BONUS)",
      ROUND(agg.free_spin_win_cash, 2) AS "FREESPINS WIN (CASH)",
      'N/A - No game_round data' AS "% FREESPINS PLAYED",
      agg.campaign_category::text AS "CAMPAIGN CATEGORY",
      1 AS sort_order
    FROM agg
    WHERE agg.granted_players > 0
  ),
  
  -- Totals Row
  totals_row AS (
    SELECT
      'TOTAL'::text AS "CAMPAIGN NAME",
      SUM(CAST(agg.granted_players AS NUMERIC))::INTEGER AS "BONUS GRANTED PLAYERS",
      ROUND(SUM(agg.bonus_cost), 2) AS "BONUS COST",
      ROUND(SUM(agg.deposit_amount), 2) AS "DEPOSIT AMOUNT",
      ROUND(
        CASE 
          WHEN SUM(agg.bonus_cost) > 0 THEN ((SUM(agg.deposit_amount) - SUM(agg.bonus_cost)) / SUM(agg.bonus_cost)) * 100
          ELSE NULL
        END, 1
      ) AS "ROI%",
      ROUND(SUM(agg.bonus_cost) / NULLIF(SUM(agg.granted_players), 0), 2) AS "BONUS COST / PLAYER",
      ROUND(SUM(agg.deposit_amount) / NULLIF(SUM(agg.granted_players), 0), 2) AS "DEPOSIT AMOUNT / PLAYER",
      ROUND(SUM(agg.granted_cash), 2) AS "GRANTED CASH",
      ROUND(SUM(agg.granted_bonus), 2) AS "GRANTED BONUS",
      ROUND(SUM(agg.bonus_revoked), 2) AS "BONUS REVOKED",
      ROUND(SUM(agg.bonus_converted_to_cash), 2) AS "BONUS CONVERTED (GROSS)",
      ROUND((SUM(agg.converted_players)::numeric / NULLIF(SUM(agg.granted_players), 0)) * 100, 1) AS "% CONVERTED PLAYERS",
      ROUND(SUM(agg.granted_bonus) / NULLIF(SUM(agg.granted_players), 0), 2) AS "GRANTED BONUS / PLAYER",
      ROUND(SUM(agg.bonus_converted_to_cash) / NULLIF(SUM(agg.granted_players), 0), 2) AS "BONUS CONVERTED / PLAYER",
      SUM(agg.free_spins_granted)::INTEGER AS "GRANTED FREESPINS",
      ROUND(SUM(agg.free_spin_win_bonus), 2) AS "FREESPINS WIN (BONUS)",
      ROUND(SUM(agg.free_spin_win_cash), 2) AS "FREESPINS WIN (CASH)",
      'N/A - No game_round data' AS "% FREESPINS PLAYED",
      'TOTAL'::text AS "CAMPAIGN CATEGORY",
      0 AS sort_order
    FROM agg
  ),
  
  -- Combined Results
  combined_results AS (
    SELECT * FROM totals_row
    UNION ALL
    SELECT * FROM detail_rows
  )

SELECT
  "CAMPAIGN NAME",
  "BONUS GRANTED PLAYERS",
  "BONUS COST",
  "DEPOSIT AMOUNT",
  "ROI%",
  "BONUS COST / PLAYER",
  "DEPOSIT AMOUNT / PLAYER",
  "GRANTED CASH",
  "GRANTED BONUS",
  "BONUS REVOKED",
  "BONUS CONVERTED (GROSS)",
  "% CONVERTED PLAYERS",
  "GRANTED BONUS / PLAYER",
  "BONUS CONVERTED / PLAYER",
  "GRANTED FREESPINS",
  "FREESPINS WIN (BONUS)",
  "FREESPINS WIN (CASH)",
  "% FREESPINS PLAYED",
  "CAMPAIGN CATEGORY"
FROM combined_results
ORDER BY sort_order ASC, "BONUS COST" DESC NULLS LAST;

--------------------------------
