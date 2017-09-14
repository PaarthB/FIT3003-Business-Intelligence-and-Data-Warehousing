create table TimeDIM
As Select 
to_char(t.salesdate, 'MM') as Month, 
to_char(t.salesdate, 'YYYY') as Year, 
to_char(t.salesdate, 'MM') || to_char(t.salesdate, 'YYYY') as TimeID
From DTANIAR.SALES5 t;

Describe TimeDim;

create table StarRatingDim
As Select distinct Stars from DTANIAR.REVIEW5;

Select * from StarRatingDIM;
Describe STARRATINGDIM;

Alter Table StarRatingDim
add(StarDesc    VARCHAR(10));

Create table CategoryDIM
As Select Distinct * from DTANIAR.CATEGORY5;

Select * from CATEGORYDIM;

Create Table StoreDim
As Select Distinct * from DTANIAR.STORE5;

Select * from StoreDim;

Update StarRatingDIM
Set StarDesc = 'Unknown'
Where Stars = 0;

Update StarRatingDIM
Set StarDesc = 'Poor'
Where Stars = 1;

Update StarRatingDIM
Set StarDesc = 'Not Good'
Where Stars = 2;

Update StarRatingDIM
Set StarDesc = 'Average'
Where Stars = 3;

Update StarRatingDIM
Set StarDesc = 'Good'
Where Stars = 4;

Update StarRatingDIM
Set StarDesc = 'Excellent'
Where Stars = 5;


Select * from DTANIAR.BOOK5 b, DTANIAR.REVIEW5 r
Where b.ISBN = r.ISBN (+);

drop table ReviewFact;

---------------------------CREATING FACT TABLES---------------------------------

Create Table ReviewFact
As Select b.categoryid as CategoryID, r.stars as Stars, count(*) as Number_of_Reviews
from DTANIAR.BOOK5 b, DTANIAR.REVIEW5 r
Where b.ISBN = r.ISBN
Group by categoryid, stars;
/*The count(*) above, counts the rows after you do the join of the two tables.
That is, the number of rows you get after combining the two tables.
*/

Select * from ReviewFact
Order by CategoryID, Stars;

Select b.categoryid as CategoryID, r.stars as Stars, b.isbn, r.isbn
from DTANIAR.BOOK5 b, DTANIAR.REVIEW5 r
where b.isbn = r.isbn
Order by CategoryID, Stars;
/*
Understanding joins is very important.
*/


------------------------BOOK SALES FACT----------------------------------------
Create table TempBookWithStar
As Select b.CategoryID as CategoryID, to_char(s.salesdate, 'MM') || to_char(s.salesdate, 'YYYY') As TimeID, 
s.StoreID as StoreID, NVL(r.stars, 0) as STARS, t.SALESID as SalesID, t.TOTALPRICE as Price
from DTANIAR.REVIEW5 r, DTANIAR.BOOK5 b, DTANIAR.SALES5 s, DTANIAR.SALESDETAILS5 t
Where
    b.isbn = r.isbn (+)
and b.isbn = t.ISBN
and t.SALESID = s.SALESID;

Select * from DTANIAR.BOOK5 b, DTANIAR.REVIEW5 r
Where b.ISBN = r.ISBN(+);

Select * from TEMPBOOKWITHSTAR
Order by TimeID;

drop table TempBookWithStar;
drop table TempBookWithAvgStar;

Update TempBookWithStar
Set STARS = 0
Where STARS is NULL;

Create Table TempBookWithAvgStar
As Select CategoryID, TimeID, StoreID, SalesID, Price, ROUND(AVG(stars)) As Stars
from TempBookWithStar
Group by CategoryID, TimeID, StoreID, SalesID, Price;

Select * from TEMPBOOKWITHAVGSTAR
Order by CATEGORYID;

Create Table BookSalesFact
As Select CategoryID, TimeID, StoreID, Stars, count(*) as Number_of_Reviews, SUM(Price) as Total_Sales
from TEMPBOOKWITHAVGSTAR
Group by CategoryID, TimeID, StoreID, Stars;

Select * from BOOKSALESFACT;

------Question 1-------
/*What are the total sales for each bookstore in a month */
Select StoreID, t.Month, Total_Sales
from BookSalesFact b, TIMEDIM t
Where b.TIMEID = t.TIMEID;

------Question 2--------
/*What is the number of books sold for each category */
Select Distinct b.CategoryID, Sum(b.Number_of_Books)
from BOOKSALESFACT b, CATEGORYDIM c
Where b.CATEGORYID = c.CATEGORYID
Group By b.CategoryID;

------Question 3--------
/*What is the book category that has the highest total sales */

Select b.CategoryID, b.TOTAL_SALES from BOOKSALESFACT b
Where b.Total_Sales = (Select max(Total_Sales) from BookSalesFact);

------Question 4--------
/*How many 5 star reviews for each category */
--- Way 1: ($$$$ INCORRECT WAY $$$$$)
----BECAUSE THESE ARE AVERAGE STARS/REVIEWS!! Not individuals reviews!!!-----
Select b.CategoryID, Count(case when b.Stars = 5 then 1 end) as five_stars
from BOOKSALESFACT b
group by b.CategoryID
order by five_stars;
-----Way 2:------ $$$$ CORRECT WAY $$$$

Select CategoryID, Max(Five_Stars) as Five_Stars
from
(
    Select r.CategoryID, r.NUMBER_OF_REVIEWS as five_stars
    from REVIEWFACT r
    Where r.Stars = 5
    
    UNION
    
    Select r.CategoryID, Count(case when r.Stars = 5 then 1 end) as five_stars
    from REVIEWFACT r
    Where r.Stars <> 5
    Group by r.CategoryID
)
Group by CategoryID
Order by Five_Stars desc;
/* $$$$$$$$$$$$$ VERY IMPORTANT $$$$$$$$$$$$$$$$$*/
SELECT r.CategoryID, SUM(CASE WHEN r.stars = 5 THEN r.NUMBER_OF_REVIEWS ELSE 0 END) as Five_Stars
FROM REVIEWFACT r 
group by r.CategoryID 
ORDER BY Five_Stars desc;

------Question 5---------
/* Number of Reviews for each category */
Select distinct r.CategoryID, sum(r.Number_of_Reviews) as Number_of_Reviews
from REVIEWFACT r 
group by r.CategoryID
Order by Number_of_Reviews;

