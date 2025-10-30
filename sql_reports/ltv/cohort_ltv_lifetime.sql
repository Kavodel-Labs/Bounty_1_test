# COHORT LTV LIFETIME REPORT

/\*\*  
\=============================================================================  
COHORT LTV LIFETIME REPORT \- PRODUCTION SQL  
Gaming/Casino Platform Analytics  
\=============================================================================

PURPOSE:  
Aggregate lifetime metrics for each player cohort (by registration month)  
showing: Registrations, FTDs, Conversion Rate, LTV, Deposits, Withdrawals,   
GGR, NGR, Bonus Cost, and Revenue

DATA MODEL:  
\- One row per registration\_month (across all global filters)  
\- Metrics aggregated from registration date through TODAY  
\- All registrations included (including non-FTDs)  
\- Bonus metrics included in GGR calculation  
\- Proper currency resolution cascade applied

OUTPUT COLUMNS:  
  month\_year           | YYYY-MM format registration month  
  REG                  | Total registrations in cohort  
  FTD                  | First-time depositors in cohort  
  conversion\_rate      | (FTD / REG) \* 100 %  
  ltv                  | Deposit per FTD (LTV proxy)  
  deposit              | Total deposits from cohort  
  wd                   | Total withdrawals from cohort  
  ggr                  | Gross Gaming Revenue (Cash Bet \+ Promo Bet \- Cash Win \- Promo Win)  
  ngr                  | Net Gaming Revenue (same as GGR in this setup)  
  bonus\_cost           | Total bonus completion amounts (costs)  
  revenue              | NGR \- bonus\_cost (final revenue)

FILTERS APPLIED (all optional via Metabase widgets):  
  {{brand}}                  \- Company filter  
  {{country}}                \- Player country mapping  
  {{traffic\_source}}         \- Organic vs Affiliate  
  {{affiliate\_id}}           \- Specific affiliate  
  {{affiliate\_name}}         \- Affiliate name search  
  {{registration\_launcher}}  \- OS / Browser combination  
  {{is\_test\_account}}        \- Exclude/include test accounts  
  {{currency\_filter}}        \- Currency code (EUR, USD, etc)  
  {{start\_date}}             \- Registration period start  
  {{end\_date}}               \- Registration period end

\=============================================================================  
\*/

WITH 

/\*\*  
\---------------------------------------------------------------------------  
STEP 1: DATE BOUNDS \- Determine reporting window  
\---------------------------------------------------------------------------  
Default: Last 24 months of registrations  
Allows user override via {{start\_date}} and {{end\_date}} filters

Why this structure:  
\- Two separate input CTEs allow independent filter application  
\- bounds CTE provides clean references throughout query  
\- Default to last 24 months for cohort depth  
\*/

start\_input AS (  
  SELECT NULL::date AS start\_date WHERE FALSE  
  \[\[ UNION ALL SELECT {{start\_date}}::date \]\]  
),

end\_input AS (  
  SELECT NULL::date AS end\_date WHERE FALSE  
  \[\[ UNION ALL SELECT {{end\_date}}::date \]\]  
),

bounds AS (  
  SELECT  
    COALESCE(  
      (SELECT MAX(end\_date) FROM end\_input),  
      CURRENT\_DATE  
    ) AS end\_date,  
    COALESCE(  
      (SELECT MAX(start\_date) FROM start\_input),  
      CURRENT\_DATE \- INTERVAL '24 months'  
    ) AS start\_date  
),

/\*\*  
\---------------------------------------------------------------------------  
STEP 2: FILTERED PLAYERS \- Apply all global filters as gatekeeper  
\---------------------------------------------------------------------------  
This CTE is the SINGLE SOURCE OF TRUTH for which players are included.  
Every metric calculation MUST inner join to this to inherit all filters.

Filters applied:  
  1\. Brand filter (companies.name via {{brand}} widget)  
  2\. Country filter (players.country with case mapping)  
  3\. Traffic source (organic \= no affiliate, affiliate \= has affiliate\_id)  
  4\. Specific affiliate ID or affiliate name  
  5\. Registration launcher (OS / Browser combination)  
  6\. Test account flag (boolean exclude)

Why INNER JOIN pattern:  
\- Ensures every metric only counts filtered players  
\- Single change to this CTE ripples through entire report  
\- Consistent with daily/monthly report architecture

Why NO ALIASES on company fields:  
\- Allows Metabase field filters to work automatically  
\- If you created an alias like "brand\_name", field filter breaks  
\*/

filtered\_players AS (  
  SELECT DISTINCT players.id AS player\_id  
  FROM players  
  LEFT JOIN companies ON companies.id \= players.company\_id  
  WHERE 1=1  
    /\* Brand filter \- Companies.name field filter in Metabase \*/  
    \[\[ AND {{brand}} \]\]  
      
    /\* Country filter with case mapping \- full EU country coverage \*/  
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
      
    /\* Traffic source filter \- Organic vs Affiliate \*/  
    \[\[ AND CASE  
      WHEN {{traffic\_source}} \= 'Organic' THEN players.affiliate\_id IS NULL  
      WHEN {{traffic\_source}} \= 'Affiliate' THEN players.affiliate\_id IS NOT NULL  
      ELSE TRUE  
    END \]\]  
      
    /\* Specific affiliate ID filter \*/  
    \[\[ AND {{affiliate\_id}} \]\]  
      
    /\* Affiliate name search/filter \*/  
    \[\[ AND {{affiliate\_name}} \]\]  
      
    /\* Device filter \- OS and Browser combination \*/  
    \[\[ AND CONCAT(players.os, ' / ', players.browser) \= {{registration\_launcher}} \]\]  
      
    /\* Test account filter \- boolean \*/  
    \[\[ AND {{is\_test\_account}} \]\]  
),

/\*\*  
\---------------------------------------------------------------------------  
STEP 3: PLAYER COHORTS \- Register all filtered players with their cohort  
\---------------------------------------------------------------------------  
This is our TRUTH TABLE for player counts by registration month.

Key decisions:  
  \- Uses actual registration date (p.created\_at) not bucket date  
  \- Truncates to month for cohort grouping (later queries will group by this)  
  \- Stores full timestamp for potential future use  
  \- Only includes players in bounds window  
  \- INNER JOIN to filtered\_players ensures all global filters apply

Why separate CTE:  
  \- Other CTEs join to this to get cohort membership  
  \- Keeps cohort logic in one place  
  \- Easier to debug cohort membership issues  
\*/

player\_cohorts AS (  
  SELECT  
    p.id AS player\_id,  
    p.created\_at AS registration\_ts,  
    DATE\_TRUNC('month', p.created\_at)::date AS registration\_month,  
    p.company\_id  
  FROM players p  
  INNER JOIN filtered\_players fp ON p.id \= fp.player\_id  
  WHERE p.created\_at \>= (SELECT start\_date FROM bounds)  
    AND p.created\_at \< (SELECT end\_date FROM bounds) \+ INTERVAL '1 day'  
),

/\*\*  
\---------------------------------------------------------------------------  
STEP 4: FTD DATA \- Identify first deposits per player  
\---------------------------------------------------------------------------  
This CTE finds each player's FIRST successful deposit.

Why separate CTE:  
  \- Used later to count unique FTDs per cohort  
  \- Can reuse for other metrics (deposit frequency, etc)  
  \- Clear separation of concerns

Key logic:  
  \- MIN(t.created\_at) gets first deposit chronologically  
  \- Filters: category=deposit, type=credit, status=completed, balance=withdrawable  
  \- Currency filter applied here too (must match global currency context)  
  \- INNER JOIN to player\_cohorts ensures only included players have FTD data

Why INNER JOIN instead of LEFT:  
  \- If player has no valid deposit, they won't appear  
  \- Later LEFT JOIN in aggregation allows counting as non-FTD  
  \- This separation is intentional and correct

Currency resolution cascade (FROM YOUR SCHEMA):  
  1\. t.metadata-\>\>'currency'      \- Most specific (transaction override)  
  2\. t.cash\_currency              \- Transaction default  
  3\. players.wallet\_currency      \- Player account default  
  4\. companies.currency           \- Company/brand default  
    
This ensures proper currency filtering across transaction types.  
\*/

ftd\_data AS (  
  SELECT  
    t.player\_id,  
    MIN(t.created\_at) AS first\_deposit\_ts  
  FROM transactions t  
  INNER JOIN player\_cohorts pc ON t.player\_id \= pc.player\_id  
  JOIN players ON players.id \= t.player\_id  
  JOIN companies ON companies.id \= players.company\_id  
  WHERE t.transaction\_category \= 'deposit'  
    AND t.transaction\_type \= 'credit'  
    AND t.status \= 'completed'  
    AND t.balance\_type \= 'withdrawable'  
    /\* Currency filter \- cascade through transaction hierarchy \*/  
    \[\[ AND UPPER(COALESCE(  
      t.metadata-\>\>'currency',  
      t.cash\_currency,  
      players.wallet\_currency,  
      companies.currency  
    )) IN ({{currency\_filter}}) \]\]  
  GROUP BY t.player\_id  
),

/\*\*  
\---------------------------------------------------------------------------  
STEP 5: DEPOSIT & WITHDRAWAL METRICS \- Aggregate cash flow per cohort  
\---------------------------------------------------------------------------  
Sums deposits and withdrawals grouped by registration cohort.

Why GROUP BY registration\_month:  
  \- We want one row per cohort month  
  \- All players in same registration\_month group together  
  \- Results in one row per registration month (our desired granularity)

LEFT JOIN pattern:  
  \- Some months may have no deposits (e.g., zero-deposit month)  
  \- LEFT JOIN ensures all cohort months appear (even if zero deposits)  
  \- COALESCE in final SELECT handles NULL → 0 conversion

Filters:  
  \- deposit: category=deposit, type=credit, status=completed, balance=withdrawable  
  \- withdrawal: category=withdrawal, type=debit, status=completed, balance=withdrawable  
  \- Currency filter applied  
  \- INNER JOIN to player\_cohorts ensures only filtered players

Why ABS() on withdrawals:  
  \- Withdrawals stored as negative amounts in some systems  
  \- ABS ensures we sum positive values  
  \- May not be needed in your schema, but safe to include  
\*/

deposit\_withdrawal\_metrics AS (  
  SELECT  
    pc.registration\_month,  
    COALESCE(SUM(CASE  
      WHEN t.transaction\_category \= 'deposit'  
        AND t.transaction\_type \= 'credit'  
        AND t.status \= 'completed'  
        AND t.balance\_type \= 'withdrawable'  
      THEN t.amount  
    END), 0\) AS total\_deposits,  
    COALESCE(SUM(CASE  
      WHEN t.transaction\_category \= 'withdrawal'  
        AND t.transaction\_type \= 'debit'  
        AND t.status \= 'completed'  
        AND t.balance\_type \= 'withdrawable'  
      THEN ABS(t.amount)  
    END), 0\) AS total\_withdrawals  
  FROM player\_cohorts pc  
  LEFT JOIN transactions t ON pc.player\_id \= t.player\_id  
  JOIN players ON players.id \= pc.player\_id  
  JOIN companies ON companies.id \= players.company\_id  
  WHERE 1=1  
    \[\[ AND UPPER(COALESCE(  
      t.metadata-\>\>'currency',  
      t.cash\_currency,  
      players.wallet\_currency,  
      companies.currency  
    )) IN ({{currency\_filter}}) \]\]  
  GROUP BY pc.registration\_month  
),

/\*\*  
\---------------------------------------------------------------------------  
STEP 6: GGR/NGR METRICS \- Aggregate betting metrics per cohort  
\---------------------------------------------------------------------------  
Calculates Gross Gaming Revenue components by cohort.

GGR Formula (Gaming Industry Standard):  
  GGR \= (Cash Bet \+ Promo Bet) \- (Cash Win \+ Promo Win)  
    
Where:  
  \- Cash Bet:    game\_bet category, debit, withdrawable balance, completed  
  \- Cash Win:    game\_bet category, credit, withdrawable balance, completed  
  \- Promo Bet:   bonus category, debit, non-withdrawable balance, completed  
  \- Promo Win:   bonus category, credit, non-withdrawable balance, completed

Why separate Cash and Promo:  
  \- Bonus play tracked separately per gaming platform conventions  
  \- Allows analysis of bonus impact vs cash play  
  \- Both contribute to GGR (total revenue)

Why 'non-withdrawable' for bonus:  
  \- Bonus balance can't be withdrawn directly  
  \- Must be wagered/converted to cash  
  \- Separate lifecycle from cash balance

Key insight:  
  NGR in this report \= GGR (your platform doesn't deduct taxes in transaction layer)  
  \- Some platforms calculate: NGR \= GGR \- Taxes \- Fees  
  \- Your taxes/fees calculated downstream in revenue calc  
  \- So GGR \= NGR for transaction aggregation purposes  
\*/

ggr\_ngr\_metrics AS (  
  SELECT  
    pc.registration\_month,  
    COALESCE(SUM(CASE  
      WHEN t.transaction\_type \= 'debit'  
        AND t.transaction\_category \= 'game\_bet'  
        AND t.balance\_type \= 'withdrawable'  
        AND t.status \= 'completed'  
      THEN ABS(t.amount)  
    END), 0\) AS cash\_bet,  
    COALESCE(SUM(CASE  
      WHEN t.transaction\_type \= 'credit'  
        AND t.transaction\_category \= 'game\_bet'  
        AND t.balance\_type \= 'withdrawable'  
        AND t.status \= 'completed'  
      THEN t.amount  
    END), 0\) AS cash\_win,  
    COALESCE(SUM(CASE  
      WHEN t.transaction\_type \= 'debit'  
        AND t.transaction\_category \= 'bonus'  
        AND t.balance\_type \= 'non-withdrawable'  
        AND t.status \= 'completed'  
      THEN ABS(t.amount)  
    END), 0\) AS promo\_bet,  
    COALESCE(SUM(CASE  
      WHEN t.transaction\_type \= 'credit'  
        AND t.transaction\_category \= 'bonus'  
        AND t.balance\_type \= 'non-withdrawable'  
        AND t.status \= 'completed'  
      THEN t.amount  
    END), 0\) AS promo\_win  
  FROM player\_cohorts pc  
  LEFT JOIN transactions t ON pc.player\_id \= t.player\_id  
  JOIN players ON players.id \= pc.player\_id  
  JOIN companies ON companies.id \= players.company\_id  
  WHERE 1=1  
    \[\[ AND UPPER(COALESCE(  
      t.metadata-\>\>'currency',  
      t.cash\_currency,  
      players.wallet\_currency,  
      companies.currency  
    )) IN ({{currency\_filter}}) \]\]  
  GROUP BY pc.registration\_month  
),

/\*\*  
\---------------------------------------------------------------------------  
STEP 7: BONUS COST METRICS \- Aggregate bonus costs per cohort  
\---------------------------------------------------------------------------  
Sums all bonus completion amounts (bonuses that converted to real money).

Bonus Cost Definition:  
  \- All bonus\_completion transactions that became withdrawable  
  \- Represents the COST to platform of bonus promotions  
  \- Includes original bonus amount \+ wins generated from bonus play  
  \- Could also track separately if needed

Filter logic:  
  \- category \= 'bonus\_completion' (not 'bonus' which is bonus play activity)  
  \- type \= 'credit' (money going INTO withdrawable balance)  
  \- status \= 'completed' (only finalized bonuses)  
  \- balance\_type \= 'withdrawable' (bonus converted to cash)

Why separate CTE:  
  \- Bonus costs might be calculated differently in future  
  \- Easy to modify bonus rules in one place  
  \- Other reports might need bonus metrics  
  \- Clear intent in code  
\*/

bonus\_cost\_metrics AS (  
  SELECT  
    pc.registration\_month,  
    COALESCE(SUM(CASE  
      WHEN t.transaction\_type \= 'credit'  
        AND t.transaction\_category \= 'bonus\_completion'  
        AND t.status \= 'completed'  
        AND t.balance\_type \= 'withdrawable'  
      THEN t.amount  
    END), 0\) AS total\_bonus\_cost  
  FROM player\_cohorts pc  
  LEFT JOIN transactions t ON pc.player\_id \= t.player\_id  
  JOIN players ON players.id \= pc.player\_id  
  JOIN companies ON companies.id \= players.company\_id  
  WHERE 1=1  
    \[\[ AND UPPER(COALESCE(  
      t.metadata-\>\>'currency',  
      t.cash\_currency,  
      players.wallet\_currency,  
      companies.currency  
    )) IN ({{currency\_filter}}) \]\]  
  GROUP BY pc.registration\_month  
),

/\*\*  
\---------------------------------------------------------------------------  
STEP 8: COHORT LIFETIME METRICS \- Combine all aggregations  
\---------------------------------------------------------------------------  
This is the MAIN AGGREGATION that brings all metrics together.

Join pattern:  
  \- Start with player\_cohorts (LEFT JOIN) to ensure all cohorts appear  
  \- FTD data (LEFT JOIN) \- not all players have deposits  
  \- All metric CTEs (LEFT JOIN) \- some cohorts may have zero activity

Why LEFT JOINs:  
  \- Non-FTD players should appear as 0, not excluded  
  \- Cohorts with zero activity should still show 0, not be missing  
  \- This preserves complete cohort visibility

GROUP BY logic:  
  \- Group by registration\_month to aggregate all players in that cohort  
  \- COUNT(DISTINCT player\_id) for total registrations  
  \- COUNT(DISTINCT ftd.player\_id) for FTDs (LEFT JOIN handles nulls)  
  \- Other columns come from metric CTEs (already grouped by registration\_month)

Why COUNT(DISTINCT ...):  
  \- Ensures each player counted once even if multiple transactions  
  \- LEFT JOINs could cause duplicate counts without DISTINCT  
  \- DISTINCT ftd.player\_id counts non-null FTD records only  
\*/

cohort\_lifetime\_metrics AS (  
  SELECT  
    pc.registration\_month,  
    COUNT(DISTINCT pc.player\_id) AS total\_registrations,  
    COUNT(DISTINCT ftd.player\_id) AS ftd\_count,  
    COALESCE(dwm.total\_deposits, 0\) AS total\_deposits,  
    COALESCE(dwm.total\_withdrawals, 0\) AS total\_withdrawals,  
    COALESCE(ggr.cash\_bet, 0\) AS cash\_bet,  
    COALESCE(ggr.cash\_win, 0\) AS cash\_win,  
    COALESCE(ggr.promo\_bet, 0\) AS promo\_bet,  
    COALESCE(ggr.promo\_win, 0\) AS promo\_win,  
    COALESCE(bcm.total\_bonus\_cost, 0\) AS total\_bonus\_cost  
  FROM player\_cohorts pc  
  LEFT JOIN ftd\_data ftd ON pc.player\_id \= ftd.player\_id  
  LEFT JOIN deposit\_withdrawal\_metrics dwm ON pc.registration\_month \= dwm.registration\_month  
  LEFT JOIN ggr\_ngr\_metrics ggr ON pc.registration\_month \= ggr.registration\_month  
  LEFT JOIN bonus\_cost\_metrics bcm ON pc.registration\_month \= bcm.registration\_month  
  GROUP BY pc.registration\_month, dwm.total\_deposits, dwm.total\_withdrawals,  
           ggr.cash\_bet, ggr.cash\_win, ggr.promo\_bet, ggr.promo\_win, bcm.total\_bonus\_cost  
),

/\*\*  
\---------------------------------------------------------------------------  
STEP 9: FINAL REPORT DATA \- Calculate KPIs and format output  
\---------------------------------------------------------------------------  
This CTE calculates all derived metrics and formats them for display.

Column calculations:

1\. month\_year \= TO\_CHAR(registration\_month, 'YYYY-MM')  
   Purpose: Human-readable month for display  
   Example: '2024-08' for August 2024  
     
2\. REG \= total\_registrations  
   Purpose: Total players registered in this month  
   Range: \[0, infinity)  
     
3\. FTD \= ftd\_count  
   Purpose: Players who made first deposit  
   Range: \[0, REG\]  
   Note: FTD ≤ REG always  
     
4\. conversion\_rate \= (FTD / REG) \* 100  
   Purpose: % of registrations that became depositors  
   Formula: ROUND(FTD::numeric / NULLIF(REG, 0\) \* 100, 2\)  
   Range: \[0, 100\]  
   Note: NULLIF prevents division by zero, returns 0 if REG=0  
     
5\. ltv \= total\_deposits / FTD  
   Purpose: Average deposit per first-time depositor  
   Formula: ROUND(total\_deposits::numeric / NULLIF(FTD, 0), 2\)  
   Range: \[0, infinity)  
   Note: This is "deposits per FTD" which proxies LTV at deposit stage  
   Interpretation: Higher \= better initial deposits  
     
6\. deposit \= total\_deposits  
   Purpose: Total deposits from cohort  
   Formula: ROUND(total\_deposits, 2\)  
   Range: \[0, infinity)  
   Currency: € (euros in your reports)  
     
7\. wd \= total\_withdrawals  
   Purpose: Total withdrawals from cohort  
   Formula: ROUND(total\_withdrawals, 2\)  
   Range: \[0, infinity)  
   Currency: €  
     
8\. ggr \= cash\_bet \+ promo\_bet \- cash\_win \- promo\_win  
   Purpose: Gross Gaming Revenue (platform profit before costs)  
   Formula: ROUND(cash\_bet \+ promo\_bet \- cash\_win \- promo\_win, 2\)  
   Range: Can be negative if payouts exceed bets  
   Currency: €  
     
9\. ngr \= ggr (in your platform setup)  
   Purpose: Net Gaming Revenue (same as GGR in transaction layer)  
   Formula: ROUND(cash\_bet \+ promo\_bet \- cash\_win \- promo\_win, 2\)  
   Range: Same as GGR  
   Note: Taxes/fees deducted later in revenue calculation  
     
10\. bonus\_cost \= total\_bonus\_cost  
    Purpose: Total cost of bonus conversions  
    Formula: ROUND(total\_bonus\_cost, 2\)  
    Range: \[0, infinity)  
    Currency: €  
      
11\. revenue \= NGR \- bonus\_cost  
    Purpose: Final net revenue after bonus costs  
    Formula: ROUND((ggr \- total\_bonus\_cost), 2\)  
    Range: Can be negative  
    Currency: €  
    Interpretation: Revenue platform keeps after bonuses

sort\_order \= 0:  
    \- Used for ordering (0 \= regular rows, \-1 \= total row)  
    \- Allows TOTAL to appear first via ORDER BY sort\_order, month\_year DESC  
\*/

final\_report\_data AS (  
  SELECT  
    0 AS sort\_order,  
    TO\_CHAR(registration\_month, 'YYYY-MM') AS month\_year,  
    total\_registrations AS REG,  
    ftd\_count AS FTD,  
    ROUND(CASE   
      WHEN total\_registrations \> 0   
      THEN ftd\_count::numeric / total\_registrations \* 100   
      ELSE 0   
    END, 2\) AS conversion\_rate,  
    ROUND(CASE  
      WHEN ftd\_count \> 0  
      THEN total\_deposits::numeric / ftd\_count  
      ELSE 0  
    END, 2\) AS ltv,  
    ROUND(total\_deposits, 2\) AS deposit,  
    ROUND(total\_withdrawals, 2\) AS wd,  
    ROUND(cash\_bet \+ promo\_bet \- cash\_win \- promo\_win, 2\) AS ggr,  
    ROUND(cash\_bet \+ promo\_bet \- cash\_win \- promo\_win, 2\) AS ngr,  
    ROUND(total\_bonus\_cost, 2\) AS bonus\_cost,  
    ROUND((cash\_bet \+ promo\_bet \- cash\_win \- promo\_win) \- total\_bonus\_cost, 2\) AS revenue  
  FROM cohort\_lifetime\_metrics  
)

/\*\*  
\---------------------------------------------------------------------------  
FINAL OUTPUT \- Combine TOTAL row with individual month rows  
\---------------------------------------------------------------------------

The TOTAL row aggregates all months together, showing platform-wide metrics.

TOTAL row calculation:  
  \- sort\_order \= \-1 (ensures it appears first via ORDER BY)  
  \- month\_year \= 'TOTAL' (label)  
  \- REG \= SUM(all registrations) across all months  
  \- FTD \= SUM(all FTDs) across all months  
  \- conversion\_rate \= SUM(FTDs) / SUM(REGs) \* 100 (overall conversion)  
  \- ltv \= SUM(deposits) / SUM(FTDs) (average deposit per FTD overall)  
  \- deposit/wd/ggr/ngr/bonus\_cost/revenue \= SUM of each

Why separate TOTAL from monthly rows:  
  \- Some DBs don't handle WITH ROLLUP well  
  \- Explicit UNION ALL is more portable  
  \- Easier to understand calculation logic  
  \- Can disable TOTAL if needed (just remove this UNION)

ORDER BY sort\_order, month\_year DESC:  
  \- sort\_order ASC puts TOTAL (-1) first  
  \- month\_year DESC puts newest months first (after TOTAL)  
  \- Result: \[TOTAL\] \[2024-09\] \[2024-08\] \[2024-07\] ...  
\*/

\-- TOTAL ROW (aggregated across all months)  
SELECT   
  \-1 AS sort\_order,  
  'TOTAL' AS month\_year,  
  SUM(REG) AS REG,  
  SUM(FTD) AS FTD,  
  ROUND(SUM(FTD)::numeric / NULLIF(SUM(REG), 0\) \* 100, 2\) AS conversion\_rate,  
  ROUND(SUM(deposit)::numeric / NULLIF(SUM(FTD), 0), 2\) AS ltv,  
  ROUND(SUM(deposit), 2\) AS deposit,  
  ROUND(SUM(wd), 2\) AS wd,  
  ROUND(SUM(ggr), 2\) AS ggr,  
  ROUND(SUM(ngr), 2\) AS ngr,  
  ROUND(SUM(bonus\_cost), 2\) AS bonus\_cost,  
  ROUND(SUM(revenue), 2\) AS revenue  
FROM final\_report\_data

UNION ALL

\-- INDIVIDUAL MONTH ROWS  
SELECT \* FROM final\_report\_data

ORDER BY sort\_order, month\_year DESC;  
