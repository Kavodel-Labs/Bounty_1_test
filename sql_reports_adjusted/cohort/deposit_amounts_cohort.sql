# DEPOSIT AMOUNTS COHORT

/\* \============================================  
   DEPOSIT AMOUNTS COHORT \- ALIGNED WITH DAILY/MONTHLY FILTERS  
   Shows total deposit amounts by cohort over time  
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

/\* Step 1: Identify first deposits with currency filter \*/  
first\_deposits AS (  
  SELECT   
    t.player\_id,  
    DATE\_TRUNC('month', MIN(t.created\_at)) as first\_deposit\_month,  
    MIN(t.created\_at) as first\_deposit\_date  
  FROM transactions t  
  INNER JOIN filtered\_players fp ON t.player\_id \= fp.player\_id  
  JOIN players ON players.id \= t.player\_id  
  JOIN companies ON companies.id \= players.company\_id  
  WHERE t.transaction\_category \= 'deposit'   
    AND t.transaction\_type \= 'credit'   
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

/\* Step 2: Calculate cohort sizes (for reference) \*/  
cohort\_sizes AS (  
  SELECT   
    first\_deposit\_month as cohort\_month,  
    COUNT(DISTINCT player\_id) as cohort\_size  
  FROM first\_deposits  
  GROUP BY first\_deposit\_month  
),

/\* Step 3: Calculate TOTAL DEPOSIT AMOUNTS for each cohort across months \*/  
cohort\_deposit\_amounts AS (  
  SELECT   
    fd.first\_deposit\_month as cohort\_month,  
    DATE\_TRUNC('month', t.created\_at) as activity\_month,  
    SUM(t.amount) as total\_deposit\_amount,  
    COUNT(t.id) as total\_deposits,  
    COUNT(DISTINCT t.player\_id) as unique\_depositors  
  FROM first\_deposits fd  
  INNER JOIN transactions t ON fd.player\_id \= t.player\_id  
  JOIN players ON players.id \= t.player\_id  
  JOIN companies ON companies.id \= players.company\_id  
  WHERE t.transaction\_category \= 'deposit'   
    AND t.transaction\_type \= 'credit'   
    AND t.balance\_type \= 'withdrawable'  
    AND t.status \= 'completed'  
    AND t.created\_at \>= fd.first\_deposit\_date  
    \-- Apply same currency filter  
    \[\[ AND UPPER(COALESCE(  
           t.metadata-\>\>'currency',  
           t.cash\_currency,  
           players.wallet\_currency,  
           companies.currency  
         )) IN ({{currency\_filter}}) \]\]  
  GROUP BY fd.first\_deposit\_month, DATE\_TRUNC('month', t.created\_at)  
),

/\* Step 4: Calculate months since first deposit \*/  
cohort\_retention AS (  
  SELECT   
    cda.cohort\_month,  
    cda.activity\_month,  
    cda.total\_deposit\_amount,  
    cda.total\_deposits,  
    cda.unique\_depositors,  
    cs.cohort\_size,  
    EXTRACT(YEAR FROM AGE(cda.activity\_month, cda.cohort\_month)) \* 12 \+   
    EXTRACT(MONTH FROM AGE(cda.activity\_month, cda.cohort\_month)) as months\_since\_first\_deposit  
  FROM cohort\_deposit\_amounts cda  
  INNER JOIN cohort\_sizes cs ON cda.cohort\_month \= cs.cohort\_month  
  WHERE EXTRACT(YEAR FROM AGE(cda.activity\_month, cda.cohort\_month)) \* 12 \+   
        EXTRACT(MONTH FROM AGE(cda.activity\_month, cda.cohort\_month)) \<= 12  
)

/\* Step 5: Pivot showing NUMERIC AMOUNTS ONLY \*/  
SELECT   
  TO\_CHAR(cohort\_month, 'Month YYYY') as "FIRST DEPOSIT MONTH",  
  ROUND(MAX(CASE WHEN months\_since\_first\_deposit \= 0 THEN total\_deposit\_amount END), 2\) as "Month 0",  
  ROUND(MAX(CASE WHEN months\_since\_first\_deposit \= 1 THEN total\_deposit\_amount END), 2\) as "Month 1",  
  ROUND(MAX(CASE WHEN months\_since\_first\_deposit \= 2 THEN total\_deposit\_amount END), 2\) as "Month 2",  
  ROUND(MAX(CASE WHEN months\_since\_first\_deposit \= 3 THEN total\_deposit\_amount END), 2\) as "Month 3",  
  ROUND(MAX(CASE WHEN months\_since\_first\_deposit \= 4 THEN total\_deposit\_amount END), 2\) as "Month 4",  
  ROUND(MAX(CASE WHEN months\_since\_first\_deposit \= 5 THEN total\_deposit\_amount END), 2\) as "Month 5",  
  ROUND(MAX(CASE WHEN months\_since\_first\_deposit \= 6 THEN total\_deposit\_amount END), 2\) as "Month 6",  
  ROUND(MAX(CASE WHEN months\_since\_first\_deposit \= 7 THEN total\_deposit\_amount END), 2\) as "Month 7",  
  ROUND(MAX(CASE WHEN months\_since\_first\_deposit \= 8 THEN total\_deposit\_amount END), 2\) as "Month 8",  
  ROUND(MAX(CASE WHEN months\_since\_first\_deposit \= 9 THEN total\_deposit\_amount END), 2\) as "Month 9",  
  ROUND(MAX(CASE WHEN months\_since\_first\_deposit \= 10 THEN total\_deposit\_amount END), 2\) as "Month 10",  
  ROUND(MAX(CASE WHEN months\_since\_first\_deposit \= 11 THEN total\_deposit\_amount END), 2\) as "Month 11",  
  ROUND(MAX(CASE WHEN months\_since\_first\_deposit \= 12 THEN total\_deposit\_amount END), 2\) as "Month 12"  
FROM cohort\_retention  
GROUP BY cohort\_month  
ORDER BY cohort\_month;

