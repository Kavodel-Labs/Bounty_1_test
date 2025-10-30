# monthly full sql

/\* \=========================  
   MONTHLY KPIs — MULTI-MONTH VIEW with COMPLETE SUMMARY ROW  
   Each row represents a complete calendar month  
   Summary row properly calculates unique counts and percentages  
     
   BONUS LOGIC:  
   \- Bonus Converted \= Original bonus amounts that converted to real money  
   \- Bonus Cost \= Total cost including converted bonuses \+ wins generated from bonus play  
   \========================= \*/

WITH  
/\* \--- Optional inputs: empty by default, 1 row when provided \--- \*/  
start\_input AS (  
  SELECT NULL::date AS start\_date WHERE FALSE  
  \[\[ UNION ALL SELECT {{start\_date}}::date \]\]  
),  
end\_input AS (  
  SELECT NULL::date AS end\_date WHERE FALSE  
  \[\[ UNION ALL SELECT {{end\_date}}::date \]\]  
),

/\* \--- Normalize window (no inputs → last 12 months to current month) \--- \*/  
bounds\_raw AS (  
  SELECT  
    COALESCE((SELECT MAX(end\_date) FROM end\_input), CURRENT\_DATE) AS end\_date\_raw,  
    (SELECT MAX(start\_date) FROM start\_input) AS start\_date\_raw  
),  
bounds AS (  
  SELECT  
    DATE\_TRUNC('month', end\_date\_raw) \+ INTERVAL '1 month' \- INTERVAL '1 day' AS end\_date,  
    /\* default start \= beginning of month 12 months ago \*/  
    CASE  
      WHEN start\_date\_raw IS NULL THEN DATE\_TRUNC('month', end\_date\_raw \- INTERVAL '12 months')  
      WHEN start\_date\_raw \> end\_date\_raw THEN DATE\_TRUNC('month', end\_date\_raw)  
      ELSE DATE\_TRUNC('month', start\_date\_raw)  
    END AS start\_date  
  FROM bounds\_raw  
),

/\* \--- Monthly series over the chosen window \--- \*/  
month\_series AS (  
  SELECT   
    DATE\_TRUNC('month', d)::date AS report\_month,  
    DATE\_TRUNC('month', d) AS start\_ts,  
    LEAST(DATE\_TRUNC('month', d) \+ INTERVAL '1 month', NOW()) AS end\_ts  
  FROM generate\_series(  
         (SELECT start\_date FROM bounds),  
         (SELECT end\_date FROM bounds),  
         INTERVAL '1 month'  
       ) AS d  
),

/\* \---------- FILTERED PLAYERS (NO ALIASES for Field Filters) \---------- \*/  
filtered\_players AS (  
  SELECT DISTINCT players.id AS player\_id  
  FROM players  
  LEFT JOIN companies ON companies.id \= players.company\_id  
  WHERE 1=1  
    \[\[ AND {{brand}} \]\]              \-- Field Filter → Companies.name  
    \[\[ AND players.country \= CASE {{country}}  
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
END \]\]

    \-- Text/Category variables (optional)  
    \[\[ AND CASE  
           WHEN {{traffic\_source}} \= 'Organic'   THEN players.affiliate\_id IS NULL  
           WHEN {{traffic\_source}} \= 'Affiliate' THEN players.affiliate\_id IS NOT NULL  
           ELSE TRUE  
         END \]\]  
    \[\[ AND {{affiliate\_id}} \]\]
    \[\[ AND {{affiliate\_name}} \]\]
    \[\[ AND CONCAT(players.os, ' / ', players.browser) \= {{registration\_launcher}} \]\]

    \-- TEST ACCOUNT as a Field Filter → Players.is\_test\_account (boolean)  
    \[\[ AND {{is\_test\_account}} \]\]  
),

/\* \---------- GLOBAL FTD \---------- \*/  
ftd\_first AS (  
  SELECT  
    t.player\_id,  
    MIN(t.created\_at) AS first\_deposit\_ts  
  FROM transactions t  
  INNER JOIN filtered\_players fp ON t.player\_id \= fp.player\_id  
  /\* bring players/companies (not aliased) for currency fallback \+ widget \*/  
  JOIN players   ON players.id   \= t.player\_id  
  JOIN companies ON companies.id \= players.company\_id  
  WHERE t.transaction\_category \= 'deposit'  
    AND t.transaction\_type     \= 'credit'  
    AND t.status               \= 'completed'  
    AND t.balance\_type         \= 'withdrawable'  
    AND t.created\_at \>= (SELECT start\_date FROM bounds)  
    AND t.created\_at \<  (SELECT end\_date FROM bounds) \+ INTERVAL '1 day'  
    \[\[ AND UPPER(COALESCE(  
           t.metadata-\>\>'currency',  
           t.cash\_currency,  
           players.wallet\_currency,  
           companies.currency  
         )) IN ({{currency\_filter}}) \]\]  
  GROUP BY t.player\_id  
),

player\_reg AS (  
  SELECT  
    p.id AS player\_id,  
    p.created\_at AS registration\_ts,  
    p.email\_verified,  
    c.name AS brand\_name  
  FROM players p  
  INNER JOIN filtered\_players fp ON p.id \= fp.player\_id  
  LEFT JOIN companies c ON p.company\_id \= c.id  
),

registrations AS (  
  SELECT  
    ms.report\_month,  
    COUNT(pr.\*) AS total\_registrations,  
    COUNT(CASE WHEN pr.email\_verified \= TRUE THEN 1 END) AS complete\_registrations  
  FROM month\_series ms  
  LEFT JOIN player\_reg pr  
         ON pr.registration\_ts \>= ms.start\_ts  
        AND pr.registration\_ts \<  ms.end\_ts  
  GROUP BY ms.report\_month  
),

ftds AS (  
  SELECT  
    DATE\_TRUNC('month', ff.first\_deposit\_ts)::date AS report\_month,  
    pr.player\_id,  
    pr.registration\_ts,  
    ff.first\_deposit\_ts  
  FROM ftd\_first ff  
  JOIN player\_reg pr ON pr.player\_id \= ff.player\_id  
),

ftd\_metrics AS (  
  SELECT  
    ms.report\_month  
  , COUNT(DISTINCT f.player\_id) AS ftds\_count  
  , COUNT(\*) FILTER (WHERE DATE\_TRUNC('month', f.registration\_ts) \= DATE\_TRUNC('month', f.first\_deposit\_ts)) AS new\_ftds  
  , COUNT(\*) FILTER (WHERE DATE\_TRUNC('month', f.registration\_ts) \< DATE\_TRUNC('month', f.first\_deposit\_ts)) AS old\_ftds  
  , COUNT(\*) FILTER (WHERE DATE\_TRUNC('day',   f.registration\_ts) \= DATE\_TRUNC('day',   f.first\_deposit\_ts)) AS d0\_ftds  
  , COUNT(\*) FILTER (WHERE DATE\_TRUNC('day',   f.registration\_ts) \<\> DATE\_TRUNC('day',   f.first\_deposit\_ts)) AS late\_ftds  
  FROM month\_series ms  
  LEFT JOIN ftds f ON f.report\_month \= ms.report\_month  
  GROUP BY ms.report\_month  
),

/\* \---------- DEPOSITS \---------- \*/  
deposit\_metrics AS (  
  SELECT  
    ms.report\_month,  
    COUNT(DISTINCT t.player\_id) FILTER (  
      WHERE t.transaction\_category='deposit'  
        AND t.transaction\_type='credit'  
        AND t.status='completed'  
        AND t.balance\_type='withdrawable'  
    ) AS unique\_depositors,  
    COUNT(\*) FILTER (  
      WHERE t.transaction\_category='deposit'  
        AND t.transaction\_type='credit'  
        AND t.status='completed'  
        AND t.balance\_type='withdrawable'  
    ) AS deposits\_count,  
    COALESCE(SUM(CASE  
      WHEN t.transaction\_category='deposit'  
       AND t.transaction\_type='credit'  
       AND t.status='completed'  
       AND t.balance\_type='withdrawable'  
      THEN t.amount END), 0\) AS deposits\_amount  
  FROM month\_series ms  
  LEFT JOIN transactions t  
         ON t.created\_at \>= ms.start\_ts  
        AND t.created\_at \<  ms.end\_ts  
  INNER JOIN filtered\_players fp ON t.player\_id \= fp.player\_id  
  JOIN players   ON players.id   \= t.player\_id  
  JOIN companies ON companies.id \= players.company\_id  
  WHERE 1=1  
    \[\[ AND UPPER(COALESCE(  
           t.metadata-\>\>'currency',  
           t.cash\_currency,  
           players.wallet\_currency,  
           companies.currency  
         )) IN ({{currency\_filter}}) \]\]  
  GROUP BY ms.report\_month  
),

/\* \---------- WITHDRAWALS \---------- \*/  
withdrawal\_metrics AS (  
  SELECT  
    ms.report\_month,  
    COUNT(t.id) FILTER (  
      WHERE t.transaction\_category='withdrawal'  
        AND t.transaction\_type='debit'  
        AND t.balance\_type='withdrawable'  
        AND t.status='completed'  
    ) AS withdrawals\_count,  
    COALESCE(SUM(ABS(t.amount)) FILTER (  
      WHERE t.transaction\_category='withdrawal'  
        AND t.transaction\_type='debit'  
        AND t.balance\_type='withdrawable'  
        AND t.status='completed'  
    ), 0\) AS withdrawals\_amount,  
    COALESCE(SUM(ABS(t.amount)) FILTER (  
      WHERE t.transaction\_category='withdrawal'  
        AND t.transaction\_type='debit'  
        AND t.balance\_type='withdrawable'  
        AND t.status='cancelled'  
    ), 0\) AS withdrawals\_cancelled  
  FROM month\_series ms  
  LEFT JOIN transactions t  
         ON t.created\_at \>= ms.start\_ts  
        AND t.created\_at \<  ms.end\_ts  
  INNER JOIN filtered\_players fp ON t.player\_id \= fp.player\_id  
  JOIN players   ON players.id   \= t.player\_id  
  JOIN companies ON companies.id \= players.company\_id  
  WHERE 1=1  
    \[\[ AND UPPER(COALESCE(  
           t.metadata-\>\>'currency',  
           t.cash\_currency,  
           players.wallet\_currency,  
           companies.currency  
         )) IN ({{currency\_filter}}) \]\]  
  GROUP BY ms.report\_month  
),

/\* \---------- ACTIVE PLAYERS & BETTING \---------- \*/  
active\_players AS (  
  SELECT  
    ms.report\_month,  
    COUNT(DISTINCT CASE WHEN t.transaction\_category='game\_bet' THEN t.player\_id END) AS active\_players\_count,  
    COUNT(DISTINCT CASE WHEN t.transaction\_category='game\_bet' AND t.balance\_type='withdrawable' THEN t.player\_id END) AS real\_active\_players  
  FROM month\_series ms  
  LEFT JOIN transactions t  
         ON t.created\_at \>= ms.start\_ts  
        AND t.created\_at \<  ms.end\_ts  
  INNER JOIN filtered\_players fp ON t.player\_id \= fp.player\_id  
  JOIN players   ON players.id   \= t.player\_id  
  JOIN companies ON companies.id \= players.company\_id  
  WHERE 1=1  
    \[\[ AND UPPER(COALESCE(  
           t.metadata-\>\>'currency',  
           t.cash\_currency,  
           players.wallet\_currency,  
           companies.currency  
         )) IN ({{currency\_filter}}) \]\]  
  GROUP BY ms.report\_month  
),

betting\_metrics AS (  
  SELECT  
    ms.report\_month,  
    COALESCE(SUM(CASE  
      WHEN t.transaction\_type='debit'  
       AND t.transaction\_category='game\_bet'  
       AND t.balance\_type='withdrawable'  
       AND t.status='completed'  
    THEN t.amount END), 0\) AS cash\_bet,  
    COALESCE(SUM(CASE  
      WHEN t.transaction\_type='credit'  
       AND t.transaction\_category='game\_bet'  \-- Matching daily: game\_bet (not game\_win)  
       AND t.balance\_type='withdrawable'  
       AND t.status='completed'  
    THEN t.amount END), 0\) AS cash\_win,  
    \-- promo\_bet: matching daily report exactly  
    COALESCE(SUM(CASE  
      WHEN t.transaction\_type='debit'  
       AND t.transaction\_category='bonus'  \-- Matching daily: bonus category  
       AND t.balance\_type='non-withdrawable'  
       AND t.status='completed'  
    THEN t.amount END), 0\) AS promo\_bet,  
    \-- promo\_win: matching daily report exactly  
    COALESCE(SUM(CASE  
      WHEN t.transaction\_type='credit'  
       AND t.status='completed'  
       AND t.balance\_type='non-withdrawable'  
       AND t.transaction\_category \= 'bonus'  \-- Matching daily: bonus category  
    THEN t.amount END), 0\) AS promo\_win  
  FROM month\_series ms  
  LEFT JOIN transactions t  
         ON t.created\_at \>= ms.start\_ts  
        AND t.created\_at \<  ms.end\_ts  
  INNER JOIN filtered\_players fp ON t.player\_id \= fp.player\_id  
  JOIN players   ON players.id   \= t.player\_id  
  JOIN companies ON companies.id \= players.company\_id  
  WHERE 1=1  
    \[\[ AND UPPER(COALESCE(  
           t.metadata-\>\>'currency',  
           t.cash\_currency,  
           players.wallet\_currency,  
           companies.currency  
         )) IN ({{currency\_filter}}) \]\]  
  GROUP BY ms.report\_month  
),

/\* \---------- BONUS CONVERTED (wagering completions only) \---------- \*/  
/\* This represents the original bonus amounts that successfully converted to real money \*/  
bonus\_converted AS (  
  SELECT  
    ms.report\_month,  
    \-- For now, we use bonus\_completion as a proxy for converted bonuses  
    \-- In an ideal world, this would track only the original bonus portion  
    COALESCE(SUM(CASE  
      WHEN t.transaction\_type='credit'  
       AND t.transaction\_category='bonus\_completion'  
       AND t.status='completed'  
       AND t.balance\_type='withdrawable'  
    THEN t.amount END), 0\) AS bonus\_converted\_amount  
  FROM month\_series ms  
  LEFT JOIN transactions t  
         ON t.created\_at \>= ms.start\_ts  
        AND t.created\_at \<  ms.end\_ts  
  INNER JOIN filtered\_players fp ON t.player\_id \= fp.player\_id  
  JOIN players   ON players.id   \= t.player\_id  
  JOIN companies ON companies.id \= players.company\_id  
  WHERE 1=1  
    \[\[ AND UPPER(COALESCE(  
           t.metadata-\>\>'currency',  
           t.cash\_currency,  
           players.wallet\_currency,  
           companies.currency  
         )) IN ({{currency\_filter}}) \]\]  
  GROUP BY ms.report\_month  
),

/\* \---------- BONUS COST (Total cost \= converted bonuses \+ wins from bonus play) \---------- \*/  
/\* Since bonus\_completion includes both original bonus AND wins made with that bonus,  
   this is actually our total bonus cost \*/  
bonus\_cost AS (  
  SELECT  
    ms.report\_month,  
    \-- bonus\_completion represents the total amount that became withdrawable from bonus play  
    \-- This includes both the original bonus AND any wins generated while using that bonus  
    COALESCE(SUM(CASE  
      WHEN t.transaction\_type='credit'  
       AND t.transaction\_category='bonus\_completion'  
       AND t.status='completed'  
       AND t.balance\_type='withdrawable'  
    THEN t.amount END), 0\) AS total\_bonus\_cost  
  FROM month\_series ms  
  LEFT JOIN transactions t  
         ON t.created\_at \>= ms.start\_ts  
        AND t.created\_at \<  ms.end\_ts  
  INNER JOIN filtered\_players fp ON t.player\_id \= fp.player\_id  
  JOIN players   ON players.id   \= t.player\_id  
  JOIN companies ON companies.id \= players.company\_id  
  WHERE 1=1  
    \[\[ AND UPPER(COALESCE(  
           t.metadata-\>\>'currency',  
           t.cash\_currency,  
           players.wallet\_currency,  
           companies.currency  
         )) IN ({{currency\_filter}}) \]\]  
  GROUP BY ms.report\_month  
),

/\* \---------- PREPARE MONTHLY DATA \---------- \*/  
monthly\_data AS (  
  SELECT   
    0 as sort\_order,  
    TO\_CHAR(ms.report\_month, 'YYYY-MM') AS "Month",  
    COALESCE(r.total\_registrations, 0\) AS "\#Registrations",  
    COALESCE(fm.ftds\_count, 0\) AS "\#FTDs",  
    COALESCE(fm.new\_ftds, 0\) AS "\#New FTDs",  
    ROUND(CASE WHEN COALESCE(fm.ftds\_count,0) \> 0   
               THEN fm.new\_ftds::numeric / fm.ftds\_count \* 100 ELSE 0 END, 2\) AS "%New FTDs",  
    COALESCE(fm.old\_ftds, 0\) AS "\#Old FTDs",  
    ROUND(CASE WHEN COALESCE(fm.ftds\_count,0) \> 0   
               THEN fm.old\_ftds::numeric / fm.ftds\_count \* 100 ELSE 0 END, 2\) AS "% Old FTDs",  
    COALESCE(fm.d0\_ftds, 0\) AS "\#D0 FTDs",  
    ROUND(CASE WHEN COALESCE(fm.ftds\_count,0) \> 0   
               THEN fm.d0\_ftds::numeric / fm.ftds\_count \* 100 ELSE 0 END, 2\) AS "%D0 FTDs",  
    COALESCE(fm.late\_ftds, 0\) AS "\#Late FTDs",  
    ROUND(CASE WHEN COALESCE(r.total\_registrations,0) \> 0   
               THEN COALESCE(fm.ftds\_count,0)::numeric / r.total\_registrations \* 100 ELSE 0 END, 2\) AS "%Conversion total reg",  
    ROUND(CASE WHEN COALESCE(r.complete\_registrations,0) \> 0   
               THEN COALESCE(fm.ftds\_count,0)::numeric / r.complete\_registrations \* 100 ELSE 0 END, 2\) AS "%Conversion complete reg",  
    COALESCE(dm.unique\_depositors, 0\) AS "Unique Depositors",  
    COALESCE(dm.deposits\_count, 0\) AS "\#Deposits",  
    ROUND(COALESCE(dm.deposits\_amount, 0), 2\) AS "Deposits Amount",  
    COALESCE(wm.withdrawals\_count, 0\) AS "\#Withdrawals",  
    ROUND(COALESCE(wm.withdrawals\_amount, 0), 2\) AS "Withdrawals Amount",  
    ROUND(COALESCE(wm.withdrawals\_cancelled, 0), 2\) AS "Withdrawals Amount Canceled",  
    ROUND(CASE WHEN COALESCE(dm.deposits\_amount,0) \> 0   
               THEN COALESCE(wm.withdrawals\_amount,0) / dm.deposits\_amount \* 100 ELSE 0 END, 2\) AS "%Withdrawals/Deposits",  
    ROUND(COALESCE(dm.deposits\_amount,0) \- COALESCE(wm.withdrawals\_amount, 0), 2\) AS "CashFlow",  
    COALESCE(ap.active\_players\_count, 0\) AS "Active Players",  
    COALESCE(ap.real\_active\_players, 0\) AS "Real Active Players",  
    ROUND(COALESCE(bet.cash\_bet, 0), 2\) AS "Cash Bet",  
    ROUND(COALESCE(bet.cash\_win, 0), 2\) AS "Cash Win",  
    ROUND(COALESCE(bet.promo\_bet, 0), 2\) AS "Promo bet",  
    ROUND(COALESCE(bet.promo\_win, 0), 2\) AS "Promo Win",  
    ROUND(COALESCE(bet.cash\_bet,0) \+ COALESCE(bet.promo\_bet,0), 2\) AS "Turnover",  
    ROUND(COALESCE(bet.cash\_bet,0) \+ COALESCE(bet.promo\_bet,0), 2\) AS "Turnover Casino",  
    ROUND(COALESCE(bet.cash\_bet,0) \+ COALESCE(bet.promo\_bet,0)  
        \- COALESCE(bet.cash\_win,0)  
        \- COALESCE(bet.promo\_win,0), 2\) AS "GGR",  
    ROUND(COALESCE(bet.cash\_bet,0) \+ COALESCE(bet.promo\_bet,0)  
        \- COALESCE(bet.cash\_win,0)  
        \- COALESCE(bet.promo\_win,0), 2\) AS "GGR Casino",  
    ROUND(COALESCE(bet.cash\_bet,0) \- COALESCE(bet.cash\_win,0), 2\) AS "Cash GGR",  
    ROUND(COALESCE(bet.cash\_bet,0) \- COALESCE(bet.cash\_win,0), 2\) AS "Cash GGR Casino",  
    \-- Bonus Converted: Original bonus amounts that converted (currently using bonus\_completion as proxy)  
    ROUND(COALESCE(bc.bonus\_converted\_amount, 0), 2\) AS "Bonus Converted",  
    \-- Bonus Cost: Total cost including converted bonuses \+ wins (bonus\_completion includes both)  
    ROUND(COALESCE(bcost.total\_bonus\_cost, 0), 2\) AS "Bonus Cost",  
    ROUND(CASE   
        WHEN (COALESCE(bet.cash\_bet,0) \+ COALESCE(bet.promo\_bet,0)  
             \- COALESCE(bet.cash\_win,0)  
             \- COALESCE(bet.promo\_win,0)) \> 0   
        THEN COALESCE(bcost.total\_bonus\_cost,0) /   
             (COALESCE(bet.cash\_bet,0) \+ COALESCE(bet.promo\_bet,0)  
             \- COALESCE(bet.cash\_win,0)  
             \- COALESCE(bet.promo\_win,0)) \* 100   
        ELSE 0 END, 2\) AS "Bonus Ratio (GGR)",  
    ROUND(CASE WHEN COALESCE(dm.deposits\_amount,0) \> 0   
               THEN COALESCE(bcost.total\_bonus\_cost,0) / dm.deposits\_amount \* 100 ELSE 0 END, 2\) AS "Bonus Ratio (Deposits)",  
    ROUND(CASE   
        WHEN (COALESCE(bet.cash\_bet,0) \+ COALESCE(bet.promo\_bet,0)) \> 0   
        THEN (COALESCE(bet.cash\_win,0) \+ COALESCE(bet.promo\_win,0)) /   
             (COALESCE(bet.cash\_bet,0) \+ COALESCE(bet.promo\_bet,0)) \* 100   
        ELSE 0 END, 2\) AS "Payout %",  
    ROUND(CASE   
        WHEN (COALESCE(bet.cash\_bet,0) \+ COALESCE(bet.promo\_bet,0)  
             \- COALESCE(bet.cash\_win,0)  
             \- COALESCE(bet.promo\_win,0)) \> 0  
        THEN (COALESCE(dm.deposits\_amount,0) \- COALESCE(wm.withdrawals\_amount,0)) /  
             (COALESCE(bet.cash\_bet,0) \+ COALESCE(bet.promo\_bet,0)  
             \- COALESCE(bet.cash\_win,0)  
             \- COALESCE(bet.promo\_win,0)) \* 100  
        ELSE 0 END, 2\) AS "%CashFlow to GGR"  
  FROM month\_series ms  
  LEFT JOIN registrations    r   ON r.report\_month   \= ms.report\_month  
  LEFT JOIN ftd\_metrics      fm  ON fm.report\_month  \= ms.report\_month  
  LEFT JOIN deposit\_metrics  dm  ON dm.report\_month  \= ms.report\_month  
  LEFT JOIN withdrawal\_metrics wm ON wm.report\_month \= ms.report\_month  
  LEFT JOIN active\_players   ap  ON ap.report\_month  \= ms.report\_month  
  LEFT JOIN betting\_metrics  bet ON bet.report\_month \= ms.report\_month  
  LEFT JOIN bonus\_converted  bc  ON bc.report\_month  \= ms.report\_month  
  LEFT JOIN bonus\_cost       bcost ON bcost.report\_month \= ms.report\_month  
)

/\* \========== FINAL OUTPUT WITH COMPLETE SUMMARY ROW \========== \*/  
\-- Summary row with proper unique count calculations  
SELECT   
  \-1 as sort\_order,  
  'TOTAL' AS "Month",  
  SUM("\#Registrations") AS "\#Registrations",  
  SUM("\#FTDs") AS "\#FTDs",  
  SUM("\#New FTDs") AS "\#New FTDs",  
  ROUND(CASE WHEN SUM("\#FTDs") \> 0   
             THEN SUM("\#New FTDs")::numeric / SUM("\#FTDs") \* 100 ELSE 0 END, 2\) AS "%New FTDs",  
  SUM("\#Old FTDs") AS "\#Old FTDs",  
  ROUND(CASE WHEN SUM("\#FTDs") \> 0   
             THEN SUM("\#Old FTDs")::numeric / SUM("\#FTDs") \* 100 ELSE 0 END, 2\) AS "% Old FTDs",  
  SUM("\#D0 FTDs") AS "\#D0 FTDs",  
  ROUND(CASE WHEN SUM("\#FTDs") \> 0   
             THEN SUM("\#D0 FTDs")::numeric / SUM("\#FTDs") \* 100 ELSE 0 END, 2\) AS "%D0 FTDs",  
  SUM("\#Late FTDs") AS "\#Late FTDs",  
  ROUND(CASE WHEN SUM("\#Registrations") \> 0   
             THEN SUM("\#FTDs")::numeric / SUM("\#Registrations") \* 100 ELSE 0 END, 2\) AS "%Conversion total reg",  
    
  \-- FIX 1: Calculate complete registration conversion from totals  
  (SELECT ROUND(  
    CASE WHEN COUNT(CASE WHEN pr.email\_verified \= TRUE THEN 1 END) \> 0  
         THEN COUNT(DISTINCT CASE WHEN ff.first\_deposit\_ts IS NOT NULL THEN ff.player\_id END)::numeric /   
              COUNT(CASE WHEN pr.email\_verified \= TRUE THEN 1 END) \* 100   
         ELSE 0 END, 2\)  
   FROM player\_reg pr  
   LEFT JOIN ftd\_first ff ON pr.player\_id \= ff.player\_id  
   WHERE pr.registration\_ts \>= (SELECT start\_date FROM bounds)  
     AND pr.registration\_ts \< (SELECT end\_date FROM bounds) \+ INTERVAL '1 day'  
  ) AS "%Conversion complete reg",  
    
  \-- FIX 2: Calculate actual unique depositors for entire period  
  (SELECT COUNT(DISTINCT t.player\_id)  
   FROM transactions t  
   INNER JOIN filtered\_players fp ON t.player\_id \= fp.player\_id  
   JOIN players ON players.id \= t.player\_id  
   JOIN companies ON companies.id \= players.company\_id  
   WHERE t.transaction\_category='deposit'  
     AND t.transaction\_type='credit'  
     AND t.status='completed'  
     AND t.balance\_type='withdrawable'  
     AND t.created\_at \>= (SELECT start\_date FROM bounds)  
     AND t.created\_at \< (SELECT end\_date FROM bounds) \+ INTERVAL '1 day'  
     \[\[ AND UPPER(COALESCE(  
            t.metadata-\>\>'currency',  
            t.cash\_currency,  
            players.wallet\_currency,  
            companies.currency  
          )) IN ({{currency\_filter}}) \]\]  
  ) AS "Unique Depositors",  
    
  SUM("\#Deposits") AS "\#Deposits",  
  ROUND(SUM("Deposits Amount"), 2\) AS "Deposits Amount",  
  SUM("\#Withdrawals") AS "\#Withdrawals",  
  ROUND(SUM("Withdrawals Amount"), 2\) AS "Withdrawals Amount",  
  ROUND(SUM("Withdrawals Amount Canceled"), 2\) AS "Withdrawals Amount Canceled",  
  ROUND(CASE WHEN SUM("Deposits Amount") \> 0   
             THEN SUM("Withdrawals Amount") / SUM("Deposits Amount") \* 100 ELSE 0 END, 2\) AS "%Withdrawals/Deposits",  
  ROUND(SUM("CashFlow"), 2\) AS "CashFlow",  
    
  \-- FIX 3: Calculate actual active players for entire period  
  (SELECT COUNT(DISTINCT t.player\_id)  
   FROM transactions t  
   INNER JOIN filtered\_players fp ON t.player\_id \= fp.player\_id  
   JOIN players ON players.id \= t.player\_id  
   JOIN companies ON companies.id \= players.company\_id  
   WHERE t.transaction\_category='game\_bet'  
     AND t.created\_at \>= (SELECT start\_date FROM bounds)  
     AND t.created\_at \< (SELECT end\_date FROM bounds) \+ INTERVAL '1 day'  
     \[\[ AND UPPER(COALESCE(  
            t.metadata-\>\>'currency',  
            t.cash\_currency,  
            players.wallet\_currency,  
            companies.currency  
          )) IN ({{currency\_filter}}) \]\]  
  ) AS "Active Players",  
    
  \-- FIX 4: Calculate actual real active players for entire period  
  (SELECT COUNT(DISTINCT t.player\_id)  
   FROM transactions t  
   INNER JOIN filtered\_players fp ON t.player\_id \= fp.player\_id  
   JOIN players ON players.id \= t.player\_id  
   JOIN companies ON companies.id \= players.company\_id  
   WHERE t.transaction\_category='game\_bet'  
     AND t.balance\_type='withdrawable'  
     AND t.created\_at \>= (SELECT start\_date FROM bounds)  
     AND t.created\_at \< (SELECT end\_date FROM bounds) \+ INTERVAL '1 day'  
     \[\[ AND UPPER(COALESCE(  
            t.metadata-\>\>'currency',  
            t.cash\_currency,  
            players.wallet\_currency,  
            companies.currency  
          )) IN ({{currency\_filter}}) \]\]  
  ) AS "Real Active Players",  
    
  ROUND(SUM("Cash Bet"), 2\) AS "Cash Bet",  
  ROUND(SUM("Cash Win"), 2\) AS "Cash Win",  
  ROUND(SUM("Promo bet"), 2\) AS "Promo bet",  
  ROUND(SUM("Promo Win"), 2\) AS "Promo Win",  
  ROUND(SUM("Turnover"), 2\) AS "Turnover",  
  ROUND(SUM("Turnover Casino"), 2\) AS "Turnover Casino",  
  ROUND(SUM("GGR"), 2\) AS "GGR",  
  ROUND(SUM("GGR Casino"), 2\) AS "GGR Casino",  
  ROUND(SUM("Cash GGR"), 2\) AS "Cash GGR",  
  ROUND(SUM("Cash GGR Casino"), 2\) AS "Cash GGR Casino",  
  ROUND(SUM("Bonus Converted"), 2\) AS "Bonus Converted",  
  ROUND(SUM("Bonus Cost"), 2\) AS "Bonus Cost",  
  ROUND(CASE WHEN SUM("GGR") \> 0   
             THEN SUM("Bonus Cost") / SUM("GGR") \* 100 ELSE 0 END, 2\) AS "Bonus Ratio (GGR)",  
  ROUND(CASE WHEN SUM("Deposits Amount") \> 0   
             THEN SUM("Bonus Cost") / SUM("Deposits Amount") \* 100 ELSE 0 END, 2\) AS "Bonus Ratio (Deposits)",  
  ROUND(CASE WHEN SUM("Turnover") \> 0   
             THEN (SUM("Cash Win") \+ SUM("Promo Win")) / SUM("Turnover") \* 100 ELSE 0 END, 2\) AS "Payout %",  
  ROUND(CASE WHEN SUM("GGR") \> 0   
             THEN SUM("CashFlow") / SUM("GGR") \* 100 ELSE 0 END, 2\) AS "%CashFlow to GGR"  
FROM monthly\_data

UNION ALL

\-- Monthly rows  
SELECT \* FROM monthly\_data

ORDER BY sort\_order, "Month" DESC;

