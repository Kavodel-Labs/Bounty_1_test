# EXISTING DEPOSITORS COHORT

/\* \============================================  
   EXISTING DEPOSITORS COHORT \- PRODUCTION QUERY  
   Full dataset aggregation by months with complete filter suite  
   Shows unique count of existing depositors reaching deposit milestones within each month  
   One row per month across entire available data  
     
   Existing Depositor \= first\_ever\_deposit BEFORE that month  
   Deposit count \= number of deposits made DURING each month  
     
   FILTERS: Brand, Country, Traffic Source, Affiliate, Registration Launcher, Test Account, Currency  
   DATE RANGE: Optional start\_date and end\_date (defaults to all available data)  
   PARAMETERS: start\_date, end\_date, currency\_filter, brand, country, traffic\_source, affiliate\_id, affiliate\_name, registration\_launcher, is\_test\_account  
   \============================================ \*/

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

/\* \--- Normalize window (no inputs → all available data) \--- \*/  
bounds\_raw AS (  
  SELECT    
    COALESCE((SELECT MAX(end\_date) FROM end\_input), CURRENT\_DATE) AS end\_date\_raw,  
    (SELECT MAX(start\_date) FROM start\_input) AS start\_date\_raw  
),  
bounds AS (  
  SELECT    
    end\_date\_raw AS end\_date,  
    /\* default start \= beginning of all data; if user set start, use it \*/  
    CASE  
      WHEN start\_date\_raw IS NULL THEN (SELECT MIN(DATE\_TRUNC('month', created\_at))::date FROM transactions WHERE transaction\_category \= 'deposit')  
      WHEN start\_date\_raw \> end\_date\_raw THEN end\_date\_raw  
      ELSE start\_date\_raw  
    END AS start\_date    
  FROM bounds\_raw  
),

/\* \--- Step 1: Get all months in analysis period \--- \*/  
all\_months AS (  
  SELECT DISTINCT DATE\_TRUNC('month', d)::date AS month\_start  
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

/\* Step 2: Identify first deposit date for all filtered players \--- \*/  
player\_first\_deposit AS (  
  SELECT   
    transactions.player\_id,  
    MIN(transactions.created\_at) as first\_deposit\_date  
  FROM transactions  
  INNER JOIN filtered\_players fp ON transactions.player\_id \= fp.player\_id  
  JOIN players ON players.id \= transactions.player\_id  
  JOIN companies ON companies.id \= players.company\_id  
  WHERE transactions.transaction\_category \= 'deposit'  
    AND transactions.transaction\_type \= 'credit'  
    AND transactions.balance\_type \= 'withdrawable'  
    AND transactions.status \= 'completed'  
    AND transactions.created\_at \>= (SELECT start\_date FROM bounds)  
    AND transactions.created\_at \< (SELECT end\_date FROM bounds) \+ INTERVAL '1 day'  
    \-- Currency filter using standard hierarchy  
    \[\[ AND UPPER(COALESCE(  
           transactions.metadata-\>\>'currency',  
           transactions.cash\_currency,  
           players.wallet\_currency,  
           companies.currency  
         )) IN ({{currency\_filter}}) \]\]  
  GROUP BY transactions.player\_id  
),

/\* \--- Step 3: Filter to EXISTING DEPOSITORS for each month \--- \*/  
/\* Existing \= first deposit occurred BEFORE the month being analyzed \*/  
existing\_depositors\_by\_month AS (  
  SELECT   
    am.month\_start,  
    pfd.player\_id,  
    pfd.first\_deposit\_date  
  FROM all\_months am  
  CROSS JOIN player\_first\_deposit pfd  
  INNER JOIN filtered\_players fp ON pfd.player\_id \= fp.player\_id  
  WHERE pfd.first\_deposit\_date \< am.month\_start  
),

/\* \--- Step 4: Count deposits per existing depositor per month with currency filter \--- \*/  
monthly\_deposit\_counts AS (  
  SELECT   
    edbm.month\_start,  
    edbm.player\_id,  
    COUNT(\*) as deposits\_in\_month  
  FROM existing\_depositors\_by\_month edbm  
  INNER JOIN transactions t ON edbm.player\_id \= t.player\_id  
  JOIN players ON players.id \= t.player\_id  
  JOIN companies ON companies.id \= players.company\_id  
  WHERE t.transaction\_category \= 'deposit'  
    AND t.transaction\_type \= 'credit'  
    AND t.balance\_type \= 'withdrawable'  
    AND t.status \= 'completed'  
    AND DATE\_TRUNC('month', t.created\_at)::date \= edbm.month\_start  
    \-- Currency filter using standard hierarchy  
    \[\[ AND UPPER(COALESCE(  
           t.metadata-\>\>'currency',  
           t.cash\_currency,  
           players.wallet\_currency,  
           companies.currency  
         )) IN ({{currency\_filter}}) \]\]  
  GROUP BY edbm.month\_start, edbm.player\_id  
),

/\* \--- Step 5: Calculate bucket distribution for each month \--- \*/  
monthly\_bucket\_counts AS (  
  SELECT  
    month\_start,  
    \-- Individual buckets 1-10  
    COUNT(CASE WHEN deposits\_in\_month \>= 1 THEN 1 END) as bucket\_1,  
    COUNT(CASE WHEN deposits\_in\_month \>= 2 THEN 1 END) as bucket\_2,  
    COUNT(CASE WHEN deposits\_in\_month \>= 3 THEN 1 END) as bucket\_3,  
    COUNT(CASE WHEN deposits\_in\_month \>= 4 THEN 1 END) as bucket\_4,  
    COUNT(CASE WHEN deposits\_in\_month \>= 5 THEN 1 END) as bucket\_5,  
    COUNT(CASE WHEN deposits\_in\_month \>= 6 THEN 1 END) as bucket\_6,  
    COUNT(CASE WHEN deposits\_in\_month \>= 7 THEN 1 END) as bucket\_7,  
    COUNT(CASE WHEN deposits\_in\_month \>= 8 THEN 1 END) as bucket\_8,  
    COUNT(CASE WHEN deposits\_in\_month \>= 9 THEN 1 END) as bucket\_9,  
    COUNT(CASE WHEN deposits\_in\_month \>= 10 THEN 1 END) as bucket\_10,  
    \-- Grouped buckets  
    COUNT(CASE WHEN deposits\_in\_month \>= 11 AND deposits\_in\_month \<= 15 THEN 1 END) as bucket\_11\_15,  
    COUNT(CASE WHEN deposits\_in\_month \>= 16 AND deposits\_in\_month \<= 20 THEN 1 END) as bucket\_16\_20,  
    COUNT(CASE WHEN deposits\_in\_month \> 20 THEN 1 END) as bucket\_over\_20,  
    \-- Total active existing depositors  
    COUNT(\*) as total\_active  
  FROM monthly\_deposit\_counts  
  GROUP BY month\_start  
)

/\* \--- Final Output: One row per month across all available data \--- \*/  
SELECT   
  TO\_CHAR(month\_start, 'FMMonth YYYY') as "Month",  
  month\_start as "month\_sort\_key",  
  bucket\_1 as "1 deposit",  
  bucket\_2 as "2 deposits",  
  bucket\_3 as "3 deposits",  
  bucket\_4 as "4 deposits",  
  bucket\_5 as "5 deposits",  
  bucket\_6 as "6 deposits",  
  bucket\_7 as "7 deposits",  
  bucket\_8 as "8 deposits",  
  bucket\_9 as "9 deposits",  
  bucket\_10 as "10 deposits",  
  bucket\_11\_15 as "11-15 deposits",  
  bucket\_16\_20 as "16-20 deposits",  
  bucket\_over\_20 as "\>20 deposits",  
  total\_active as "Total Active Existing Depositors"  
FROM monthly\_bucket\_counts  
WHERE total\_active \> 0  \-- Exclude empty months  
ORDER BY month\_start DESC;

