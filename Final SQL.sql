drop table Customers;
drop table Orders;
drop table Employees;
drop table warehouses;

---------- <<<<<<<<<<<<< CUSTOM TABLES FOR DATA CLEANING >>>>>>>>>> -----------------

---------NEW CUSTOM TABLE CUSTOMERS--------

Create table Customers as 
select h.*, ROW_NUMBER() OVER (Partition By customer_id order by customer_id) as RowNumber
from HOSALES.CUSTOMERS h 
order by customer_id;

Delete from Customers
Where RowNumber <> 1;

Alter Table Customers
Drop Column RowNumber;

--------NEW CUSTOM TABLE ORDERS--------
Create table Orders as 
select o.*, ROW_NUMBER() OVER (Partition By order_id order by customer_id) as RowNumber
from HOSALES.ORDERS o
order by order_id;

Update Orders
Set Order_ID = (Select max(Order_ID)+1 from Orders)
Where RowNumber <> 1;

Alter Table Customer
Drop Column RowNumber;

Delete from Orders
Where ORDER_MODE = 'direct'
and SALES_REP_ID is NULL;

--------NEW CUSTOM TABLE WAREHOUSES--------
Create table warehouses as 
Select *
From hosales.warehouses;

Alter table warehouses
Drop column warehouse_spec;

--------NEW CUSTOM TABLE EMPLOYEES--------
Create table employees as 
Select * from hosales.employees
order by employee_id;

Update employees
Set manager_id = employee_id
where manager_id = 210;

Update employees
Set manager_id = employee_id
where employee_id = 100;

Update employees
Set salary = abs(salary)
Where employee_id = 106;

Update employees
Set department_id = 80
where employee_id = 178;

------------ <<<<<<< STAR SCHEMA 1 >>>>>>> ------------
--Promotion DIM_v1--
Create Table PromotionDIM_v1 as
Select *
from hosales.promotions;

--Order Type DIM_v1
Create Table OrderTypeDim_V1 as
select distinct order_mode
from Orders;


--Order Time DIM_v1
Create Table OrderTimeDim_V1 as
select distinct 
to_char(order_date, 'yyyymm') as orderTime_ID ,
to_char(order_date, 'yyyy') as year,
to_char(order_date, 'mm') as month
From Orders;

--ProductDIM_v1
create table ProductDim_v1 as
select distinct 
p.product_ID, p.product_Description, p.Product_name,
1/count (i.warehouse_ID) as weight_factor,
LISTAGG (i.warehouse_ID,'_') within group (order by i.warehouse_ID) as warehouse_list_agg
from hosales.Products p, hosales.inventories i
where p.product_ID = i.product_ID 
Group by p.product_ID, p.product_Description, p.Product_name; 


--Credit Type DIM_v1
Create Table CreditTypeDIM_v1
(creditType varchar2(20), 
credit_desc varchar2(30));

Insert into creditTypeDIM_v1 values
('Low', 'credit <= 1500');
Insert into creditTypeDIM_v1 values
('Med', '1500 < credit <= 3500');
Insert into creditTypeDIM_v1 values
('High', 'credit > 3500');


/*Using constraints:
Create Table CreditTypeDIM_v1
As Select * From
(
Select
(Case 
    when Credit_Limit <= 1500 Then 'Low' 
    When Credit_Limit BETWEEN 1500 and 3500 Then 'Medium'
    Else 'High'
 END) As CreditType,
 (Case
    when Credit_Limit <= 1500 Then 'Credit <= 1500'
    When Credit_Limit BETWEEN 1500 and 3500 Then '1500 < Credit <= 3500'
    Else 'Credit > 3500'
 END) As CreditDesc
From Customers
)
Group by CreditType, CreditDesc
Order by CreditType;
*/

--CountryDIM_v1 
Create table CountryDIM_v1
As select * from hosales.countries; 

--RegionDIM_v1
Create table regionDIM_v1 
As select * from hosales.regions; 

--LocationDIM_v1
Create table locationDIM_v1
As select distinct 
location_ID, city, country_ID
From hosales.locations; 


--JobTypeDIM_v1
Create table jobTypeDIM_v1 
As select distinct 
Job_id, job_title 
From hosales.jobs;


--DepartmentDIM_v1
Create table departmentDIM_v1 
As select * from hosales.departments; 


--JobTimeDIM_v1 
Create table jobTimeDIM_v1
As select distinct 
to_char(hire_date, 'yyyymm') as jobTimeID ,
to_char(hire_date, 'yyyy') as year,
to_char(hire_date, 'mm') as month
From employees;


--InventoryBridge_v1
Create table InventoryBridge_v1
As select * from hosales.inventories; 


--WarehouseDIM_v1
Create table WarehouseDIM_v1
As select warehouse_id, warehouse_name, location_id
From warehouses;



--SeasonDIM_v1
Create table seasonDIM_v1
(season_ID number,
seasondesc varchar2(20));

Insert into seasonDIM_v1 values
(1, 'Summer');
Insert into seasonDIM_v1 values
(2, 'Winter');
Insert into seasonDIM_v1 values
(3, 'Spring');
Insert into seasonDIM_v1 values
(4, 'Autumn');


--CustomerfactTemp_v1 + FACT
Create table customerfactTemp_v1 as select
C.country_id, cu.credit_limit, cu.customer_id
From hosales.countries c, customers cu
Where c.country_id = cu.country_id;

Alter table customerfactTemp_v1 
Add (creditType varchar(20));

Update customerfactTemp_v1
Set creditType = 'Low'
Where Credit_Limit <= 1500;

Update customerfactTemp_v1
Set creditType = 'Med'
Where Credit_Limit > 1500 AND Credit_limit <= 3500;

Update customerfactTemp_v1
Set creditType = 'High'
Where Credit_Limit > 3500;


Create table customerfact_v1 as select 
Country_id, creditType, count(customer_id) as no_of_customers
From customerfactTemp_v1
Group by Country_id, creditType; 



--EmployeefactTemp_v1 + FACT
Create table EmployeeFact_v1 as select 
to_char(e.hire_date, 'yyyymm') as jobTimeID, j.job_id, d.department_id,
l.location_ID, sum(e.salary) as total_salary, count(e.employee_ID) as number_of_employees
FROM hosales.jobs j, employees e, hosales.departments d, hosales.locations l
WHERE j.job_id = e.job_id and e.department_ID = d.department_ID and d.location_ID = l.location_ID
GROUP BY to_char(hire_date, 'yyyymm'), j.job_id, d.department_id, l.location_ID;


--SalesOrderfactTemp_v1 + FACT
Create table salesOrderfactTemp_v1 as select 
o.total_price, o.order_mode, oi.product_id, to_char(o.order_date, 'yyyymm') as orderTime_ID, c.region_ID, o.order_date as transaction_date, p.start_date, p.end_date
From orders o, hosales.order_items oi, hosales.countries c, customers ct, hosales.promotions p
Where oi.order_id = o.order_id AND  o.customer_ID = ct.customer_ID AND ct.country_ID = c.country_ID AND o.promotion_id = p.promotion_ID; 

alter table salesOrderfactTemp_v1
add (season_Id number);

update salesOrderfactTemp_v1
set season_Id = 1
where to_char (transaction_date, 'mm')
in ('12','01','02');

update salesOrderfactTemp_v1
set season_Id = 2
where to_char (transaction_date, 'mm')
in ('03','04','05');

update salesOrderfactTemp_v1
set season_Id = 3
where to_char (transaction_date, 'mm')
in ('06','07','08');

update salesOrderfactTemp_v1
set season_Id = 4
where to_char (transaction_date, 'mm')
in ('09','10','11');

Create Table salesOrderfact_v1 as select
Order_mode, product_id, orderTime_ID, region_ID, season_ID, 
Sum (total_price) as total_sales
From salesOrderfactTemp_v1
Where transaction_date >= start_date AND transaction_date <= end_date
Group by Order_mode, product_id, orderTime_ID, region_ID, season_ID; 


------------ <<<<<<< STAR SCHEMA 2 >>>>>>> ------------

--Promotion DIM_v2
Create Table PromotionDIM_v2 as
Select *
from hosales.promotions;


--Order Type DIM_v2
Create Table OrderTypeDim_v2 as
select distinct order_mode
from Orders;


--Order Time DIM_v2
Create Table OrderTimeDim_v2 as
select distinct 
to_char(order_date, 'yyyymm') as orderTime_ID ,
to_char(order_date, 'yyyy') as year,
to_char(order_date, 'mm') as month
From orders;


--ProductDIM_v2
create table ProductDim_v2 as
select distinct 
p.product_ID, p.product_Description, p.Product_name,
1/count (i.warehouse_ID) as weight_factor,
LISTAGG (i.warehouse_ID,'_') within group (order by i.warehouse_ID) as warehouse_list_agg
from hosales.Products p, hosales.inventories i
where p.product_ID = i.product_ID 
Group by p.product_ID, p.product_Description, p.Product_name; 


--Credit Type DIM_v2
Create Table CreditTypeDIM_v2
(creditType varchar2(20), 
credit_desc varchar2(30));

Insert into creditTypeDIM_v2 values
('Low', 'credit <= 1500');
Insert into creditTypeDIM_v2 values
('Med', '1500 < credit <= 3500');
Insert into creditTypeDIM_v2 values
('High', 'credit > 3500');

--LocationDIm_v2
create table LocationDIM_v2 as
Select l.location_ID, l.city, c.country_id,
    c.country_name, r.region_id, r.region_name
from hosales.Locations l, hosales.Countries c, hosales.regions r
where r.region_id = c.region_id and c.country_id = l.country_id;



--JobTypeDIM_v2
Create table jobTypeDIM_v2 
As select distinct 
Job_id, job_title 
From hosales.jobs;


--DepartmentDIM_v2
Create table departmentDIM_v2 
As select * from hosales.departments; 


--JobTimeDIM_v2 
Create table jobTimeDIM_v2
As select distinct 
to_char(hire_date, 'yyyymm') as jobTimeID ,
to_char(hire_date, 'yyyy') as year,
to_char(hire_date, 'mm') as month
From employees;


--ProductSalesHistoryDIM_v2
create table ProductSalesHistoryDIM_v2 
as select distinct 
o.product_id, p.start_date, p.end_date, p.pro_desc as remarks,o.unit_price, p.DISCOUNT
from hosales.order_items o, orders k, hosales.promotions p
where o.order_id = k.order_id and k.promotion_id = p.promotion_id;

alter table ProductSalesHistoryDIM_v2 
Add (Price number);

update ProductSalesHistoryDIM_v2 
Set price = (0.8 * Unit_price) 
Where discount = '20% off'; 

update ProductSalesHistoryDIM_v2 
Set price = (0.7 * Unit_price) 
Where discount = '30% off'; 

update ProductSalesHistoryDIM_v2 
Set price = (0.8 * Unit_price) 
Where discount = '20% off'; 

update ProductSalesHistoryDIM_v2 
Set price = Unit_price
Where discount = 'Full Price'; 

update ProductSalesHistoryDIM_v2 
Set price = (0.9 * Unit_price) 
Where discount = '10% off'; 


--InventoryBridge_v2
Create table InventoryBridge_v2
As select * from hosales.inventories; 


--WarehouseDIM_v2
Create table WarehouseDIM_v2
As select * from warehouses;


--SeasonDIM_v2
Create table seasonDIM_v2
(season_ID number,
seasondesc varchar2(20));

Insert into seasonDIM_v2 values
(1, 'Summer');
Insert into seasonDIM_v2 values
(2, 'Winter');
Insert into seasonDIM_v2 values
(1, 'Spring');
Insert into seasonDIM_v2 values
(1, 'Autumn');


--CustomerfactTemp_v2 + FACT
Create table customerfactTemp_v2 as select
C.country_id, cu.credit_limit, cu.customer_id
From hosales.countries c, customers cu
Where c.country_id = cu.country_id;

Alter table customerfactTemp_v2 
Add (creditType varchar(20));

Update customerfactTemp_v2
Set creditType = 'Low'
Where Credit_Limit <= 1500;

Update customerfactTemp_v2
Set creditType = 'Med'
Where Credit_Limit > 1500 AND Credit_limit <= 3500;

Update customerfactTemp_v2
Set creditType = 'High'
Where Credit_Limit > 3500;


Create table customerfact_v2 as select 
Country_id, creditType, count(customer_id) as no_of_customers
From customerfactTemp_v2
Group by Country_id, creditType; 



--EmployeefactTemp_v2 + FACT
Create table EmployeeFact_v2 as select 
to_char(e.hire_date, 'yyyymm') as jobTimeID, j.job_id, d.department_id,
l.location_ID, sum(e.salary) as total_salary, count(e.employee_ID) as number_of_employees
FROM hosales.jobs j, employees e, hosales.departments d, hosales.locations l
WHERE j.job_id = e.job_id and e.department_ID = d.department_ID and d.location_ID = l.location_ID
GROUP BY to_char(hire_date, 'yyyymm'), j.job_id, d.department_id, l.location_ID;



--SalesOrderfactTemp_v2 + FACT
Create table salesOrderfactTemp_v2 as select 
o.total_price, o.order_mode, oi.product_id, to_char(o.order_date, 'yyyymm') as orderTime_ID, c.region_ID, o.order_date as transaction_date, p.start_date, p.end_date
From orders o, hosales.order_items oi, hosales.countries c, customers ct, hosales.promotions p
Where oi.order_id = o.order_id AND  o.customer_ID = ct.customer_ID AND ct.country_ID = c.country_ID AND o.promotion_id = p.promotion_ID; 

alter table salesOrderfactTemp_v2
add (season_Id number);

update salesOrderfactTemp_v2
set season_Id = 1
where to_char (transaction_date, 'mm')
in ('12','01','02');

update salesOrderfactTemp_v2
set season_Id = 2
where to_char (transaction_date, 'mm')
in ('03','04','05');

update salesOrderfactTemp_v2
set season_Id = 3
where to_char (transaction_date, 'mm')
in ('06','07','08');

update salesOrderfactTemp_v2
set season_Id = 4
where to_char (transaction_date, 'mm')
in ('09','10','11');

Create Table salesOrderfact_v2 as select
Order_mode, product_id, orderTime_ID, region_ID, season_ID, 
Sum (total_price) as total_sales
From salesOrderfactTemp_v2
Where transaction_date >= start_date AND transaction_date <= end_date
Group by Order_mode, product_id, orderTime_ID, region_ID, season_ID; 

------------ <<<<<<< OLAP QUERIES >>>>>>> ------------

----REPORT-1----

Explain Plan for;
Select 
    decode(years, NULL, 'All Years', years) as Years, 
    decode(Season, NULL, 'All Seasons', Season) as Season, ONLINE_ORDERS from
(
Select
    to_char(to_date(orderTime_ID, 'yyyymm'), 'yyyy') as years, 
    se.SeasonDesc as Season,
    count(*) as ONLINE_ORDERS
from salesOrderFact_v1 s, SeasonDIM_v1 se
Where 
    Order_mode = 'online'
and s.Season_ID = se.Season_ID
group by cube(to_char(to_date(orderTime_ID, 'yyyymm'), 'yyyy'), se.SeasonDesc)
);
Select * From Table(dbms_xplan.display);

----REPORT-2----

Explain Plan for;
Select DECODE(Year, NULL, 'All Years', Year) as Year, Region, Average_Sales
from(
Select
    to_char(to_date(s.orderTime_ID, 'yyyymm'), 'yyyy') as Year, 
    DECODE(GROUPING(r.region_name), 1, 'All Regions', r.region_name) as Region,
    to_char(avg(s.total_sales), '$9,999,999,999') as Average_Sales
from salesOrderfact_V1 s, regionDim_V1 r
where s.region_ID = r.region_ID
group by ROLLUP(to_char(to_date(s.orderTime_ID, 'yyyymm'), 'yyyy'), r.region_name));
Select * From Table(dbms_xplan.display);

----REPORT-3----

Explain Plan for;
Select 
    s.Season_ID as Seasons, 
    r.region_name as Regions,
    to_char(sum(s.total_sales), '$9,999,999,999.999') as "TOTAL SALES",
    RANK() OVER (ORDER BY SUM(s.Total_Sales) DESC) AS "Rank"
from salesOrderfact_v1 s, RegionDIM_v1 r
Where s.region_id = r.region_id
Group By s.season_id, r.region_name;
Select * From Table(dbms_xplan.display);

----REPORT-4----

Explain Plan for;
Select 
    r.region_name as "Region Name", 
    sum(c.No_Of_Customers) as "Number of Customers",
    percent_rank() over (order by sum(c.No_Of_Customers) desc) as "Percent Rank"
from Customerfact_v1 c, RegionDIM_v1 r, CountryDIM_v1 co
Where 
    c.CreditType = 'High'
and c.Country_ID = co.Country_ID
and co.Region_ID = r.region_id
Group by r.region_name;
Select * From Table(dbms_xplan.display);

----REPORT-5----

Explain Plan for;
select d.department_ID, j.job_title, 
    Sum(e.number_of_employees) as total_employees, 
    Rank() OVER (PARTITION BY d.department_ID order by
        sum(e.number_of_employees) DESC) As Rank
from departmentDIM_v1 d, Employeefact_v1 e, JobTypeDIM_v1 j
where d.department_ID = e.Department_ID and j.job_id = e.job_id
group by d.department_ID, j.job_title
order by d.department_ID;
Select * From Table(dbms_xplan.display);

----REPORT-6----

Explain Plan for;
select d.department_ID, j.job_title, 
    to_Char(Sum(e.Total_Salary), '$999,999.00') as Total_Salary_Expense, 
    Rank() OVER (PARTITION BY d.department_ID order by
        sum(e.total_salary) DESC) As Rank
from departmentDIM_v1 d, Employeefact_v1 e, JobTypeDIM_v1 j
where d.department_ID = e.Department_ID and j.job_id = e.job_id
group by d.department_ID, j.job_title
order by d.department_ID;
Select * From Table(dbms_xplan.display);

----REPORT-7----
Explain Plan for;
Select 
    l.city, c.country_name as COUNTRY, 
    to_char(sum(e.total_salary), '$9,999,999,999') as "TOTAL SALARY", 
    to_char(sum(sum(e.total_salary)) OVER
    (PARTITION BY c.country_name 
    ORDER BY c.country_name, l.city
    ROWS UNBOUNDED PRECEDING),
    '$9,999,999,999') AS CUM_SALARY
from LocationDIM_v1 l, CountryDIM_v1 c, EmployeeFact_v1 e
Where 
    e.Location_ID = l.Location_ID
and l.Country_ID = c.Country_ID
Group By l.city, c.country_name;
Select * From Table(dbms_xplan.display);

----REPORT-8----
Explain plan for;
Select
    p.product_name, w.warehouse_name, s.OrderTime_ID, 
    to_char(sum(s.total_sales), '$9,999,999,999') as "TOTAL SALARY", 
    to_char(sum(sum(s.total_sales)) OVER
    (PARTITION BY p.product_name 
    ORDER BY p.product_name, w.warehouse_name
    ROWS 2 PRECEDING),
    '$9,999,999,999') AS MOVING_3_MONTH_SALES
from ProductDIM_v1 p, WarehouseDIM_v1 w, InventoryBridge_v1 i, SalesOrderfact_v1 s
Where
    s.Product_ID = p.Product_ID
and p.Product_ID = i.Product_ID
and i.Warehouse_ID = w.Warehouse_ID
Group By p.Product_Name, w.Warehouse_Name, s.OrderTime_ID;
Select * From Table(dbms_xplan.display);

------------ <<<<<<< OLAP QUERY OPTMISATIONS >>>>>>> ------------

Explain Plan for;
Select * From Table(dbms_xplan.display);

----REPORT-1----

Explain Plan for;
Select 
    decode(years, NULL, 'All Years', years) as Years, 
    decode(Season, NULL, 'All Seasons', Season) as Season, ONLINE_ORDERS from
(
Select /*+ USE_MERGE (s se) */
    to_char(to_date(orderTime_ID, 'yyyymm'), 'yyyy') as years, 
    se.SeasonDesc as Season,
    count(*) as ONLINE_ORDERS
from salesOrderFact_v1 s, SeasonDIM_v1 se
Where 
    Order_mode = 'online'
and s.Season_ID = se.Season_ID
group by cube(to_char(to_date(orderTime_ID, 'yyyymm'), 'yyyy'), se.SeasonDesc)
);
Select * From Table(dbms_xplan.display);

----REPORT-2----

Explain Plan for;
Select DECODE(Year, NULL, 'All Years', Year) as Year, Region, Average_Sales
from(
Select /*+ USE_NL (s r)*/
    to_char(to_date(s.orderTime_ID, 'yyyymm'), 'yyyy') as Year, 
    DECODE(GROUPING(r.region_name), 1, 'All Regions', r.region_name) as Region,
    to_char(avg(s.total_sales), '$9,999,999,999') as Average_Sales
from salesOrderfact_v1 s, regionDim_v1 r
where s.region_ID = r.region_ID
group by ROLLUP(to_char(to_date(s.orderTime_ID, 'yyyymm'), 'yyyy'), r.region_name));

Select * From Table(dbms_xplan.display);

----REPORT-3----

Explain Plan for;
Select /*+ USE_MERGE (s r) */
    s.Season_ID as Seasons, 
    r.region_name as Regions,
    to_char(sum(s.total_sales), '$9,999,999,999') as "Total Sales",
    RANK() OVER (ORDER BY SUM(s.Total_Sales) DESC) AS "Rank"
from salesOrderFact_v1 s, RegionDIM_v1 r
Where s.region_id = r.region_id
Group By s.season_id, r.region_name;
Select * From Table(dbms_xplan.display);

----REPORT-4----

Explain Plan for;
Select
    r.region_name as "Region Name", 
    sum(c.No_Of_Customers) as "Number of Customers",
    percent_rank() over (order by sum(c.No_Of_Customers) desc) as "Percent Rank"
from CustomerFact_v1 c, RegionDIM_v1 r, CountryDIM_v1 co
Where 
    c.CreditType = 'High'
and c.Country_ID = co.Country_ID
and co.Region_ID = r.region_id
Group by r.region_name
order by sum(c.No_Of_Customers) desc;
Select * From Table(dbms_xplan.display);

----REPORT-5----

Explain Plan for;
Select /*+ ORDERED */ d.department_ID, j.job_title, 
    Sum(e.number_of_employees) as total_employees, 
    Rank() OVER (PARTITION BY d.department_ID order by
        sum(e.number_of_employees) DESC) As Rank
from departmentDIM_v1 d, JobTypeDim_v1 j, EmployeeFact_v1 e 
where d.department_ID = e.Department_ID and j.job_id = e.job_id
group by d.department_ID, j.job_title
order by d.department_ID;
Select * From Table(dbms_xplan.display);

----REPORT-6----
Set AutoTrace on;
Explain Plan for;
select /*+ USE_NL (d j)*/ d.department_ID, j.job_title, 
    to_Char(Sum(e.Total_Salary), '$999,999.00') as Total_Salary_Expense, 
    Rank() OVER (PARTITION BY d.department_ID order by
        sum(e.total_salary) DESC) As Rank
from departmentDIM_v1 d, EmployeeFact_v1 e, JobTypeDim_v1 j
where d.department_ID = e.Department_ID and j.job_id = e.job_id
group by d.department_ID, j.job_title
order by d.department_ID;
Select * From Table(dbms_xplan.display);

----REPORT-7----
Explain plan for;
Select
    InnerQuery.city, InnerQuery.country_name, 
    InnerQuery.total_salary as "TOTAL SALARY", 
    to_char(sum(InnerQuery.total_salary) OVER
    (PARTITION BY InnerQuery.country_name 
    ORDER BY InnerQuery.country_name, InnerQuery.city
    ROWS UNBOUNDED PRECEDING),
    '$9,999,999,999.99') AS CUM_SALARY
from
((Select /*+ no_merge */
    l.city as city, c.country_name as country_name, sum(e.total_salary) as total_salary
from LocationDIM_v1 l, CountryDIM_v1 c, EmployeeFact_v1 e
Where 
    e.Location_ID = l.Location_ID
and l.Country_ID = c.Country_ID
Group By l.city, c.country_name) InnerQuery);
Select * From Table(dbms_xplan.display);

----REPORT-8----

Explain plan for;
Select
    InnerQuery.product_name, InnerQuery.warehouse_name, InnerQuery.OrderTime_ID, 
    to_char(InnerQuery.total_sales, '$9,999,999,999') as "TOTAL SALARY", 
    to_char(sum(InnerQuery.total_sales) OVER
    (PARTITION BY InnerQuery.product_name 
    ORDER BY InnerQuery.product_name, InnerQuery.warehouse_name
    ROWS 2 PRECEDING),
    '$9,999,999,999') AS MOVING_3_MONTH_SALES
from
((Select /*+ no_merge */
    p.product_name as product_name, w.warehouse_name as warehouse_name,
    s.orderTime_ID as OrderTime_ID, sum(s.total_sales) as total_sales
from ProductDIM_v1 p, WarehouseDIM_v1 w, InventoryBridge_v1 i, SalesOrderFact_v1 s
Where
    s.Product_ID = p.Product_ID
and p.Product_ID = i.Product_ID
and i.Warehouse_ID = w.Warehouse_ID
Group By p.Product_Name, w.Warehouse_Name, s.OrderTime_ID) InnerQuery);
Select * From Table(dbms_xplan.display);



Select * from CreditTypeDIM_v1;
