describe dw.charter_fact;
describe dw.time;
describe dw.pilot;
describe dw.model;
--------------------------------- PART A ---------------------------------
/*Q1 */
SELECT time_year, time_month,
RANK() OVER (ORDER BY time_year, time_month) AS time_rank
FROM dw.time;

/*Q2 */
SELECT time_year, time_month,
RANK() OVER (ORDER BY time_year, time_month+0) AS time_rank
FROM dw.time;

/*Q3 */
SELECT mod_code, time_id, sum(tot_char_hours), 
ROW_NUMBER() OVER (ORDER BY SUM(tot_char_hours)) AS ROW_NUMBER
from DW.CHARTER_FACT
Where time_id >= '199601' and time_id <= '199612'
Group by mod_code, time_id;

/*Q4 */
SELECT mod_code, time_id, sum(tot_char_hours), 
DENSE_RANK() OVER (ORDER BY SUM(TOT_CHAR_HOURS))  as DENSE_RANK
from DW.CHARTER_FACT
Where time_id BETWEEN '199601' and '199612'
Group by mod_code, time_id;

/*Q5 */
/*
- ROW_NUMBER returns a serial number for each row, without any gaps. 
- The numbers returned by the DENSE_RANK function do not have gaps and always 
  have consecutive ranks. 
*/

/*Q6 */
SELECT mod_code, time_id, sum(tot_char_hours), 
RANK() OVER (ORDER BY SUM(TOT_CHAR_HOURS)) as RANK
from DW.CHARTER_FACT
Where time_id BETWEEN '199601' and '199612'
Group by mod_code, time_id;

/*Q7 */
/*
- ROW_NUMBER returns a serial number for each row, without any gaps. 
- The numbers returned by the DENSE_RANK function do not have gaps and always 
  have consecutive ranks. 
- The RANK function does not always return consecutive integer.
*/

/*Q8 */
SELECT mod_code, time_id, sum(tot_char_hours), 
RANK() OVER (PARTITION BY mod_code ORDER BY mod_code, SUM(TOT_CHAR_HOURS)) 
as "RANK_BY_MODEL"
from DW.CHARTER_FACT
Where time_id BETWEEN '199601' and '199612'
Group by mod_code, time_id;

/*Q9 VERY IMPORTANT!!*/
Select t.time_year, c.mod_code, sum(c.tot_fuel) as TOTAL,
RANK() OVER (PARTITION BY t.time_year ORDER BY t.time_year, SUM(c.tot_fuel) DESC) AS RANK_BY_YEAR,
RANK() OVER (PARTITION BY c.mod_code ORDER BY c.mod_code, SUM(c.tot_fuel) DESC) AS RANK_BY_MODEL
from DW.CHARTER_FACT c, DW.TIME t
Where c.time_id = t.time_id
Group by t.time_year, c.mod_code
Order by t.time_year, sum(c.tot_fuel) DESC, c.mod_code;

/*Q10 VERY IMPORTANT!! */
SELECT mod_code, mod_name, sum(total), 
RANK() OVER (ORDER BY SUM(total) DESC) as MYRANK
FROM 
(
SELECT c.mod_code, m.mod_name, sum(c.tot_fuel) AS total,
RANK() OVER (ORDER BY sum(c.tot_fuel) DESC) as MY_RANK
FROM DW.CHARTER_FACT c, DW.MODEL m
WHERE
    c.mod_code = m.mod_code
Group by 
    c.mod_code, m.mod_name
)
Where MY_RANK <= 2
Group By mod_code, mod_name;


/*Q11 VERY IMPORTANT!!*/
Select * From
(
Select 
    time_id, sum(revenue) as Total, 
    percent_rank() over (order by sum(revenue)) as PERCENT_RANK
From DW.CHARTER_FACT 
group by time_id
order by Total DESC
)
Where PERCENT_RANK >= 0.9;


--------------------------------- PART B ---------------------------------

/*Q1 VERY IMPORTANT!!*/
SELECT c.time_id, sum(c.revenue),
TO_CHAR (SUM(SUM(c.revenue)) OVER (ORDER BY c.time_id ROWS UNBOUNDED PRECEDING),
'9,999,999,999') AS CUMULATIVE_REV
FROM DW.CHARTER_FACT c
WHERE c.time_id BETWEEN '199501' and '199512'
GROUP BY c.time_id
ORDER BY c.time_id;

/*Q2 VERY IMPORTANT!!*/
/* Error in question. Needs to mention that we need to do average */
SELECT c.time_id, sum(c.revenue),
TO_CHAR (AVG(SUM(c.revenue)) OVER (ORDER BY c.time_id ROWS 2 PRECEDING),
'9,999,999,999') AS MOVING_3_MONTH
FROM DW.CHARTER_FACT c
WHERE c.time_id BETWEEN '199501' and '199512'
GROUP BY c.time_id
ORDER BY c.time_id;

/*Q3 */
/*
- Cumulative sums up from the current row to the very first row
- Moving sums up from the current row to N rows before it, where
  N is specified in "ROWS N PRECEDING"
*/

/*Q4 MOST IMPORTANT!!!*/
SELECT t.time_year, c.mod_code, sum(c.tot_fuel),
TO_CHAR (SUM(SUM(c.TOT_FUEL)) OVER (PARTITION BY t.time_year ORDER BY t.time_year ROWS UNBOUNDED PRECEDING),
'9,999,999,999') AS CUM_FUEL_YEAR,
TO_CHAR (SUM(SUM(c.TOT_FUEL)) OVER (PARTITION BY c.mod_code ORDER BY c.mod_code ROWS UNBOUNDED PRECEDING),
'9,999,999,999') AS CUM_FUEL_MODE
FROM DW.CHARTER_FACT c, DW.TIME t
WHERE 
    c.time_id = t.time_id
GROUP BY t.time_year, c.MOD_CODE
ORDER BY t.time_year, c.MOD_CODE;

 ---- All questions done!! ----
