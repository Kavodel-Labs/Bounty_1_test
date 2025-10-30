# NEW DEPOSITORS COHORT \- PERCENTAGE

/\* \============================================  
   NEW DEPOSITORS COHORT \- PERCENTAGE DISTRIBUTION  
   Shows percentage of new depositors reaching each deposit milestone  
   One row per month within user-selected date range  
   New Depositor \= first\_ever\_deposit in that specific month  
     
   FILTERS: Brand, Country, Traffic Source, Affiliate, Registration Launcher, Test Account, Currency  
   PARAMETERS: start\_month, end\_month (DATE), currency\_filter, brand, country, traffic\_source, affiliate\_id, affiliate\_name, registration\_launcher, is\_test\_account  
   \============================================ \*/

WITH

/\* \--- Month range inputs (user-selectable) \--- \*/  
start\_input AS (  
  SELECT NULL::date AS start\_month WHERE FALSE  
  \[\[ UNION ALL SELECT {{start\_month}}::date \]\]  
),  
end\_input AS (  
  SELECT NULL::date AS end\_month WHERE FALSE  
  \[\[ UNION ALL SELECT {{end\_month}}::date \]\]  
),

/\* \--- Normalize analysis window (defaults to last 12 months if not specified) \--- \*/  
analysis\_period AS (  
  SELECT   
    COALESCE(  
      (SELECT start\_month FROM start\_input),  
      (SELECT DATE\_TRUNC('month', MAX(created\_at) \- INTERVAL '11 months')::date FROM transactions)  
    ) AS month\_start,  
    COALESCE(  
      (SELECT end\_month FROM end\_input),  
      (SELECT DATE\_TRUNC('month', MAX(created\_at))::date FROM transactions)  
    ) AS month\_end  
),

/\* \--- Get all months in the analysis period \--- \*/  
available\_months AS (  
  SELECT DATE\_TRUNC('month', d)::date AS month\_start  
  FROM GENERATE\_SERIES(  
    (SELECT month\_start FROM analysis\_period),  
    (SELECT month\_end FROM analysis\_period),  
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
    \[\[ AND players.os \= {{registration\_launcher}} \]\]  \-- Simplified to OS-only (matching daily report)

    \-- TEST ACCOUNT as a Field Filter → Players.is\_test\_account (boolean)  
    \[\[ AND {{is\_test\_account}} \]\]  
),

/\* Step 1: Calculate lifetime deposit count and first deposit date for ALL filtered players \*/  
player\_lifetime\_deposits AS (  
  SELECT   
    transactions.player\_id,  
    COUNT(\*) as lifetime\_deposit\_count,  
    MIN(transactions.created\_at) as first\_deposit\_date,  
    MAX(transactions.created\_at) as last\_deposit\_date  
  FROM transactions  
  INNER JOIN filtered\_players ON transactions.player\_id \= filtered\_players.player\_id  
  JOIN players ON players.id \= transactions.player\_id  
  JOIN companies ON companies.id \= players.company\_id  
  WHERE transactions.transaction\_category \= 'deposit'  
    AND transactions.transaction\_type \= 'credit'  
    AND transactions.balance\_type \= 'withdrawable'  
    AND transactions.status \= 'completed'  
    \-- Currency filter using standard hierarchy  
    \[\[ AND UPPER(COALESCE(  
           transactions.metadata-\>\>'currency',  
           transactions.cash\_currency,  
           players.wallet\_currency,  
           companies.currency  
         )) IN ({{currency\_filter}}) \]\]  
  GROUP BY transactions.player\_id  
),

/\* Step 2: For each month in analysis period, identify NEW DEPOSITORS (first deposit in that month) \*/  
monthly\_cohorts AS (  
  SELECT   
    DATE\_TRUNC('month', pld.first\_deposit\_date)::date AS cohort\_month,  
    pld.player\_id,  
    pld.lifetime\_deposit\_count  
  FROM player\_lifetime\_deposits pld  
  INNER JOIN available\_months am ON DATE\_TRUNC('month', pld.first\_deposit\_date)::date \= am.month\_start  
),

/\* Step 3: Calculate bucket counts and percentages for each month \*/  
monthly\_bucket\_counts AS (  
  SELECT  
    cohort\_month,  
    \-- Absolute counts  
    COUNT(\*) as total\_cohort,  
    COUNT(CASE WHEN lifetime\_deposit\_count \>= 1 THEN 1 END) as bucket\_1\_count,  
    COUNT(CASE WHEN lifetime\_deposit\_count \>= 2 THEN 1 END) as bucket\_2\_count,  
    COUNT(CASE WHEN lifetime\_deposit\_count \>= 3 THEN 1 END) as bucket\_3\_count,  
    COUNT(CASE WHEN lifetime\_deposit\_count \>= 4 THEN 1 END) as bucket\_4\_count,  
    COUNT(CASE WHEN lifetime\_deposit\_count \>= 5 THEN 1 END) as bucket\_5\_count,  
    COUNT(CASE WHEN lifetime\_deposit\_count \>= 6 THEN 1 END) as bucket\_6\_count,  
    COUNT(CASE WHEN lifetime\_deposit\_count \>= 7 THEN 1 END) as bucket\_7\_count,  
    COUNT(CASE WHEN lifetime\_deposit\_count \>= 8 THEN 1 END) as bucket\_8\_count,  
    COUNT(CASE WHEN lifetime\_deposit\_count \>= 9 THEN 1 END) as bucket\_9\_count,  
    COUNT(CASE WHEN lifetime\_deposit\_count \>= 10 THEN 1 END) as bucket\_10\_count,  
    COUNT(CASE WHEN lifetime\_deposit\_count \>= 11 AND lifetime\_deposit\_count \<= 15 THEN 1 END) as bucket\_11\_15\_count,  
    COUNT(CASE WHEN lifetime\_deposit\_count \>= 16 AND lifetime\_deposit\_count \<= 20 THEN 1 END) as bucket\_16\_20\_count,  
    COUNT(CASE WHEN lifetime\_deposit\_count \> 20 THEN 1 END) as bucket\_over\_20\_count  
  FROM monthly\_cohorts  
  GROUP BY cohort\_month  
)

/\* Final Output \- One row per month with percentages \*/  
SELECT   
  TO\_CHAR(cohort\_month, 'FMMonth YYYY') as "FTD\_Month",  
  ROUND(bucket\_1\_count::numeric / NULLIF(total\_cohort, 0\) \* 100, 1\) as "1 time",  
  ROUND(bucket\_2\_count::numeric / NULLIF(total\_cohort, 0\) \* 100, 1\) as "2 times",  
  ROUND(bucket\_3\_count::numeric / NULLIF(total\_cohort, 0\) \* 100, 1\) as "3 times",  
  ROUND(bucket\_4\_count::numeric / NULLIF(total\_cohort, 0\) \* 100, 1\) as "4 times",  
  ROUND(bucket\_5\_count::numeric / NULLIF(total\_cohort, 0\) \* 100, 1\) as "5 times",  
  ROUND(bucket\_6\_count::numeric / NULLIF(total\_cohort, 0\) \* 100, 1\) as "6 times",  
  ROUND(bucket\_7\_count::numeric / NULLIF(total\_cohort, 0\) \* 100, 1\) as "7 times",  
  ROUND(bucket\_8\_count::numeric / NULLIF(total\_cohort, 0\) \* 100, 1\) as "8 times",  
  ROUND(bucket\_9\_count::numeric / NULLIF(total\_cohort, 0\) \* 100, 1\) as "9 times",  
  ROUND(bucket\_10\_count::numeric / NULLIF(total\_cohort, 0\) \* 100, 1\) as "10 times",  
  ROUND(bucket\_11\_15\_count::numeric / NULLIF(total\_cohort, 0\) \* 100, 1\) as "11-15 times",  
  ROUND(bucket\_16\_20\_count::numeric / NULLIF(total\_cohort, 0\) \* 100, 1\) as "16-20 times",  
  ROUND(bucket\_over\_20\_count::numeric / NULLIF(total\_cohort, 0\) \* 100, 1\) as "\>20 times",  
  total\_cohort as "Total\_FTD"  
FROM monthly\_bucket\_counts  
ORDER BY cohort\_month DESC;

