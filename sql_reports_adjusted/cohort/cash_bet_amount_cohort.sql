# CASH BET AMOUNT COHORT

/\* \============================================  
   CASH BET AMOUNTS COHORT \- ALIGNED WITH DAILY/MONTHLY FILTERS  
   Shows total bet amounts by cohort over time  
   \============================================ \*/

WITH  
/\* \--- Optional date inputs for cohort window \--- \*/  
start\_input AS (  
  SELECT NULL::date AS start\_date WHERE FALSE  
  \[\[ UNION ALL SELECT {{start\_date}}::date \]\]  
),  
end\_input AS (  
  SELECT NULL::date AS end\_date WHERE FALSE  
  \[\[ UNION ALL SELECT {{end\_date}}::date \]\]  
),

/\* \--- Normalize cohort window (default: last 12 months to current month) \--- \*/  
bounds AS (  
  SELECT  
    COALESCE((SELECT start\_date FROM start\_input),   
             DATE\_TRUNC('month', CURRENT\_DATE \- INTERVAL '12 months')) AS start\_date,  
    COALESCE((SELECT end\_date FROM end\_input),   
             DATE\_TRUNC('month', CURRENT\_DATE)) AS end\_date  
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

/\* Step 1: Identify first cash bets with currency filter \*/  
first\_cash\_bets AS (  
  SELECT   
    t.player\_id,  
    DATE\_TRUNC('month', MIN(t.created\_at)) as first\_cash\_bet\_month,  
    MIN(t.created\_at) as first\_cash\_bet\_date  
  FROM transactions t  
  INNER JOIN filtered\_players fp ON t.player\_id \= fp.player\_id  
  JOIN players ON players.id \= t.player\_id  
  JOIN companies ON companies.id \= players.company\_id  
  WHERE t.transaction\_category \= 'game\_bet'   
    AND t.transaction\_type \= 'debit'   
    AND t.balance\_type \= 'withdrawable'  
    AND t.status \= 'completed'  
    \-- Apply cohort date bounds  
    AND t.created\_at \>= (SELECT start\_date FROM bounds)  
    AND t.created\_at \< (SELECT end\_date FROM bounds) \+ INTERVAL '1 day'  
    \-- Currency filter using same resolution as daily/monthly  
    \[\[ AND UPPER(COALESCE(  
           t.metadata-\>\>'currency',  
           t.cash\_currency,  
           players.wallet\_currency,  
           companies.currency  
         )) IN ({{currency\_filter}}) \]\]  
  GROUP BY t.player\_id  
),

/\* Step 2: Calculate cohort sizes \*/  
cohort\_sizes AS (  
  SELECT   
    first\_cash\_bet\_month as cohort\_month,  
    COUNT(DISTINCT player\_id) as cohort\_size  
  FROM first\_cash\_bets  
  GROUP BY first\_cash\_bet\_month  
),

/\* Step 3: Calculate TOTAL BET AMOUNTS for each cohort across months \*/  
cohort\_bet\_amounts AS (  
  SELECT   
    fcb.first\_cash\_bet\_month as cohort\_month,  
    DATE\_TRUNC('month', t.created\_at) as activity\_month,  
    SUM(ABS(t.amount)) as total\_amount\_wagered,  \-- Using ABS for debits  
    COUNT(t.id) as total\_bets,  
    COUNT(DISTINCT t.player\_id) as active\_players  
  FROM first\_cash\_bets fcb  
  INNER JOIN transactions t ON fcb.player\_id \= t.player\_id  
  JOIN players ON players.id \= t.player\_id  
  JOIN companies ON companies.id \= players.company\_id  
  WHERE t.transaction\_category \= 'game\_bet'   
    AND t.transaction\_type \= 'debit'   
    AND t.balance\_type \= 'withdrawable'  
    AND t.status \= 'completed'  
    AND t.created\_at \>= fcb.first\_cash\_bet\_date  
    \-- Apply same currency filter  
    \[\[ AND UPPER(COALESCE(  
           t.metadata-\>\>'currency',  
           t.cash\_currency,  
           players.wallet\_currency,  
           companies.currency  
         )) IN ({{currency\_filter}}) \]\]  
  GROUP BY fcb.first\_cash\_bet\_month, DATE\_TRUNC('month', t.created\_at)  
),

/\* Step 4: Calculate months since first bet \*/  
cohort\_retention AS (  
  SELECT   
    cba.cohort\_month,  
    cba.activity\_month,  
    cba.total\_amount\_wagered,  
    cba.total\_bets,  
    cba.active\_players,  
    cs.cohort\_size,  
    EXTRACT(YEAR FROM AGE(cba.activity\_month, cba.cohort\_month)) \* 12 \+   
    EXTRACT(MONTH FROM AGE(cba.activity\_month, cba.cohort\_month)) as months\_since\_first\_bet  
  FROM cohort\_bet\_amounts cba  
  INNER JOIN cohort\_sizes cs ON cba.cohort\_month \= cs.cohort\_month  
  WHERE EXTRACT(YEAR FROM AGE(cba.activity\_month, cba.cohort\_month)) \* 12 \+   
        EXTRACT(MONTH FROM AGE(cba.activity\_month, cba.cohort\_month)) \<= 12  
)

/\* Step 5: Pivot showing NUMERIC AMOUNTS ONLY \*/  
SELECT   
  TO\_CHAR(cohort\_month, 'Month YYYY') as "FIRST CASH BET MONTH",  
  ROUND(MAX(CASE WHEN months\_since\_first\_bet \= 0 THEN total\_amount\_wagered END), 2\) as "Month 0",  
  ROUND(MAX(CASE WHEN months\_since\_first\_bet \= 1 THEN total\_amount\_wagered END), 2\) as "Month 1",  
  ROUND(MAX(CASE WHEN months\_since\_first\_bet \= 2 THEN total\_amount\_wagered END), 2\) as "Month 2",  
  ROUND(MAX(CASE WHEN months\_since\_first\_bet \= 3 THEN total\_amount\_wagered END), 2\) as "Month 3",  
  ROUND(MAX(CASE WHEN months\_since\_first\_bet \= 4 THEN total\_amount\_wagered END), 2\) as "Month 4",  
  ROUND(MAX(CASE WHEN months\_since\_first\_bet \= 5 THEN total\_amount\_wagered END), 2\) as "Month 5",  
  ROUND(MAX(CASE WHEN months\_since\_first\_bet \= 6 THEN total\_amount\_wagered END), 2\) as "Month 6",  
  ROUND(MAX(CASE WHEN months\_since\_first\_bet \= 7 THEN total\_amount\_wagered END), 2\) as "Month 7",  
  ROUND(MAX(CASE WHEN months\_since\_first\_bet \= 8 THEN total\_amount\_wagered END), 2\) as "Month 8",  
  ROUND(MAX(CASE WHEN months\_since\_first\_bet \= 9 THEN total\_amount\_wagered END), 2\) as "Month 9",  
  ROUND(MAX(CASE WHEN months\_since\_first\_bet \= 10 THEN total\_amount\_wagered END), 2\) as "Month 10",  
  ROUND(MAX(CASE WHEN months\_since\_first\_bet \= 11 THEN total\_amount\_wagered END), 2\) as "Month 11",  
  ROUND(MAX(CASE WHEN months\_since\_first\_bet \= 12 THEN total\_amount\_wagered END), 2\) as "Month 12"  
FROM cohort\_retention  
GROUP BY cohort\_month  
ORDER BY cohort\_month;

