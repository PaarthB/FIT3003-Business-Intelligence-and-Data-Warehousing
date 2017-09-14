Describe DW.CHARTER_FACT;

Describe DW.TIME;

Describe DW.PILOT;

Describe DW.MODEL;

Select * from DW.CHARTER_FACT;
Select * from DW.PILOT;
---------------------------------C1 -----------------------------
Select t.TIME_MONTH, p.PIL_LICENSE, c.MOD_CODE, SUM(c.Tot_Fuel) as Total_Fuel
from DW.CHARTER_FACT c, DW.TIME t, DW.MODEL m, DW.PILOT p  
Where 
    c.TIME_ID = t.TIME_ID
and c.MOD_CODE = m.MOD_CODE
and c.EMP_NUM = p.EMP_NUM
and p.PIL_LICENSE = 'COM'
and c.MOD_CODE = 'C-90A'
and c.TIME_ID BETWEEN '199510' AND '199512'
Group by t.TIME_MONTH, p.PIL_LICENSE, c.MOD_CODE
Order by t.TIME_MONTH;

--- We get 3 rows for Question 1----

---------------------------------C2 -----------------------------
Select t.TIME_MONTH, p.PIL_LICENSE, c.MOD_CODE, SUM(c.Tot_Fuel) as Total_Fuel
from DW.CHARTER_FACT c, DW.TIME t, DW.MODEL m, DW.PILOT p  
Where 
    c.TIME_ID = t.TIME_ID
and c.MOD_CODE = m.MOD_CODE
and c.EMP_NUM = p.EMP_NUM
and p.PIL_LICENSE = 'COM'
and c.MOD_CODE = 'C-90A'
and c.TIME_ID BETWEEN '199510' AND '199512'
Group by CUBE(t.TIME_MONTH, p.PIL_LICENSE, c.MOD_CODE)
Order by t.TIME_MONTH;

--- Got 8 Rows with CUBE----
---------------------------------C3 -----------------------------
Select 
    t.TIME_MONTH, p.PIL_LICENSE, c.MOD_CODE, SUM(c.Tot_Fuel) as Total_Fuel,
    GROUPING(t.TIME_MONTH) as Month_Agg,
    GROUPING(p.PIL_LICENSE) as License_Agg,
    GROUPING(c.MOD_CODE) as Model_Agg
from DW.CHARTER_FACT c, DW.TIME t, DW.MODEL m, DW.PILOT p  
Where 
    c.TIME_ID = t.TIME_ID
and c.MOD_CODE = m.MOD_CODE
and c.EMP_NUM = p.EMP_NUM
and p.PIL_LICENSE = 'COM'
and c.MOD_CODE = 'C-90A'
and c.TIME_ID BETWEEN '199510' AND '199512'
Group by CUBE(t.TIME_MONTH, p.PIL_LICENSE, c.MOD_CODE)
Order by t.TIME_MONTH;

---------------------------------C4 -----------------------------
Select 
    t.TIME_MONTH, p.PIL_LICENSE, c.MOD_CODE, SUM(c.Tot_Fuel) as Total_Fuel,
    DECODE(GROUPING(t.TIME_MONTH), 1, 'All Months', t.TIME_MONTH) as Month_Agg,
    DECODE(GROUPING(p.PIL_LICENSE), 1, 'All Pilot Licenses', p.PIL_LICENSE) as License_Agg,
    DECODE(GROUPING(c.MOD_CODE), 1, 'All Models', c.MOD_CODE) as Model_Agg
from DW.CHARTER_FACT c, DW.TIME t, DW.MODEL m, DW.PILOT p  
Where 
    c.TIME_ID = t.TIME_ID
and c.MOD_CODE = m.MOD_CODE
and c.EMP_NUM = p.EMP_NUM
and p.PIL_LICENSE = 'COM'
and c.MOD_CODE = 'C-90A'
and c.TIME_ID BETWEEN '199510' AND '199512'
Group by CUBE(t.TIME_MONTH, p.PIL_LICENSE, c.MOD_CODE)
Order by t.TIME_MONTH;

-------------------------------C5 ------------------------------------
Select 
    t.TIME_MONTH, p.PIL_LICENSE, c.MOD_CODE, SUM(c.Tot_Fuel) as Total_Fuel,
    DECODE(GROUPING(t.TIME_MONTH), 1, 'All Months', t.TIME_MONTH) as Month_Agg,
    DECODE(GROUPING(p.PIL_LICENSE), 1, 'All Pilot Licenses', p.PIL_LICENSE) as License_Agg,
    DECODE(GROUPING(c.MOD_CODE), 1, 'All Models', c.MOD_CODE) as Model_Agg
from DW.CHARTER_FACT c, DW.TIME t, DW.MODEL m, DW.PILOT p  
Where 
    c.TIME_ID = t.TIME_ID
and c.MOD_CODE = m.MOD_CODE
and c.EMP_NUM = p.EMP_NUM
and p.PIL_LICENSE = 'COM'
and c.MOD_CODE = 'C-90A'
and c.TIME_ID BETWEEN '199510' AND '199512'
Group by c.MOD_CODE, CUBE(t.TIME_MONTH, p.PIL_LICENSE)
Order by t.TIME_MONTH;

---------------------------------C6 -----------------------------
Select 
    t.TIME_MONTH, p.PIL_LICENSE, c.MOD_CODE, SUM(c.Tot_Fuel) as Total_Fuel,
    DECODE(GROUPING(t.TIME_MONTH), 1, 'All Months', t.TIME_MONTH) as Month_Agg,
    DECODE(GROUPING(p.PIL_LICENSE), 1, 'All Pilot Licenses', p.PIL_LICENSE) as License_Agg,
    DECODE(GROUPING(c.MOD_CODE), 1, 'All Models', c.MOD_CODE) as Model_Agg
from DW.CHARTER_FACT c, DW.TIME t, DW.MODEL m, DW.PILOT p  
Where 
    c.TIME_ID = t.TIME_ID
and c.MOD_CODE = m.MOD_CODE
and c.EMP_NUM = p.EMP_NUM
and p.PIL_LICENSE = 'COM'
and c.MOD_CODE = 'C-90A'
and c.TIME_ID BETWEEN '199510' AND '199512'
Group by ROLLUP(t.TIME_MONTH, p.PIL_LICENSE, c.MOD_CODE)
Order by t.TIME_MONTH;

/* We get 10 Rows by using ROLLUP with DECODE */
---------------------------------C7 -----------------------------
/* The difference is that in C2 we get 16 rows, whereas in C6 we get 10 rows
   This is because rollup excludes the cases where a null (aggregate value)
   can be followed a non-aggregate column value and then another null 
   (aggregate value). Whereas, CUBE does not do this, and hence has to display
   all possible combinations of aggregations in the Group By clause.
*/

---------------------------------C8 -----------------------------
Select 
    t.TIME_MONTH, p.PIL_LICENSE, c.MOD_CODE, SUM(c.Tot_Fuel) as Total_Fuel,
    DECODE(GROUPING(t.TIME_MONTH), 1, 'All Months', t.TIME_MONTH) as Month_Agg,
    DECODE(GROUPING(p.PIL_LICENSE), 1, 'All Pilot Licenses', p.PIL_LICENSE) as License_Agg,
    DECODE(GROUPING(c.MOD_CODE), 1, 'All Models', c.MOD_CODE) as Model_Agg
from DW.CHARTER_FACT c, DW.TIME t, DW.MODEL m, DW.PILOT p  
Where 
    c.TIME_ID = t.TIME_ID
and c.MOD_CODE = m.MOD_CODE
and c.EMP_NUM = p.EMP_NUM
and p.PIL_LICENSE = 'COM'
and c.MOD_CODE = 'C-90A'
and c.TIME_ID BETWEEN '199510' AND '199512'
Group by c.MOD_CODE, ROLLUP(t.TIME_MONTH, p.PIL_LICENSE)
Order by t.TIME_MONTH;

/* ALL EXERCISES DONE!!!!!!!!!!!!! */
