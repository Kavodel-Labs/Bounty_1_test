# CASH BET AMOUNTS COHORT (%)

/\* \============================================  
   CASH BET AMOUNTS COHORT (%) \- NUMERIC VERSION FOR CONDITIONAL FORMATTING  
   Shows bet amounts as percentage of Month 0 (as numbers)  
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

/\* Step 2: Calculate TOTAL BET AMOUNTS for each cohort across months \*/  
cohort\_bet\_amounts AS (  
  SELECT   
    fcb.first\_cash\_bet\_month as cohort\_month,  
    DATE\_TRUNC('month', t.created\_at) as activity\_month,  
    SUM(ABS(t.amount)) as total\_amount\_wagered,  
    EXTRACT(YEAR FROM AGE(DATE\_TRUNC('month', t.created\_at), fcb.first\_cash\_bet\_month)) \* 12 \+   
    EXTRACT(MONTH FROM AGE(DATE\_TRUNC('month', t.created\_at), fcb.first\_cash\_bet\_month)) as months\_since\_first\_bet  
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

/\* Step 3: Get Month 0 amounts for baseline \*/  
month\_0\_amounts AS (  
  SELECT   
    cohort\_month,  
    total\_amount\_wagered as month\_0\_amount  
  FROM cohort\_bet\_amounts  
  WHERE months\_since\_first\_bet \= 0  
)

/\* Step 4: Pivot showing NUMERIC PERCENTAGES (no % symbol) \*/  
SELECT   
  TO\_CHAR(cba.cohort\_month, 'Month YYYY') as "FIRST CASH BET MONTH",  
  100::numeric as "Month 0",  \-- Always 100 for Month 0  
  ROUND(MAX(CASE WHEN months\_since\_first\_bet \= 1 THEN total\_amount\_wagered / NULLIF(m0.month\_0\_amount, 0\) \* 100 END), 1\) as "Month 1",  
  ROUND(MAX(CASE WHEN months\_since\_first\_bet \= 2 THEN total\_amount\_wagered / NULLIF(m0.month\_0\_amount, 0\) \* 100 END), 1\) as "Month 2",  
  ROUND(MAX(CASE WHEN months\_since\_first\_bet \= 3 THEN total\_amount\_wagered / NULLIF(m0.month\_0\_amount, 0\) \* 100 END), 1\) as "Month 3",  
  ROUND(MAX(CASE WHEN months\_since\_first\_bet \= 4 THEN total\_amount\_wagered / NULLIF(m0.month\_0\_amount, 0\) \* 100 END), 1\) as "Month 4",  
  ROUND(MAX(CASE WHEN months\_since\_first\_bet \= 5 THEN total\_amount\_wagered / NULLIF(m0.month\_0\_amount, 0\) \* 100 END), 1\) as "Month 5",  
  ROUND(MAX(CASE WHEN months\_since\_first\_bet \= 6 THEN total\_amount\_wagered / NULLIF(m0.month\_0\_amount, 0\) \* 100 END), 1\) as "Month 6",  
  ROUND(MAX(CASE WHEN months\_since\_first\_bet \= 7 THEN total\_amount\_wagered / NULLIF(m0.month\_0\_amount, 0\) \* 100 END), 1\) as "Month 7",  
  ROUND(MAX(CASE WHEN months\_since\_first\_bet \= 8 THEN total\_amount\_wagered / NULLIF(m0.month\_0\_amount, 0\) \* 100 END), 1\) as "Month 8",  
  ROUND(MAX(CASE WHEN months\_since\_first\_bet \= 9 THEN total\_amount\_wagered / NULLIF(m0.month\_0\_amount, 0\) \* 100 END), 1\) as "Month 9",  
  ROUND(MAX(CASE WHEN months\_since\_first\_bet \= 10 THEN total\_amount\_wagered / NULLIF(m0.month\_0\_amount, 0\) \* 100 END), 1\) as "Month 10",  
  ROUND(MAX(CASE WHEN months\_since\_first\_bet \= 11 THEN total\_amount\_wagered / NULLIF(m0.month\_0\_amount, 0\) \* 100 END), 1\) as "Month 11",  
  ROUND(MAX(CASE WHEN months\_since\_first\_bet \= 12 THEN total\_amount\_wagered / NULLIF(m0.month\_0\_amount, 0\) \* 100 END), 1\) as "Month 12"  
FROM cohort\_bet\_amounts cba  
JOIN month\_0\_amounts m0 ON cba.cohort\_month \= m0.cohort\_month  
WHERE months\_since\_first\_bet \<= 12  
GROUP BY cba.cohort\_month  
ORDER BY cba.cohort\_month;

