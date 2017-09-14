Create Table Warehouse
(WarehouseID Varchar2(10) Not Null,
 Location Varchar2(10) Not Null,
 Primary Key (WarehouseID)
);
Create Table Truck
(TruckID Varchar2(10) Not Null,
 VolCapacity Number(5,2),
 WeightCategory Varchar2(10),

 CostPerKm Number(5,2),
 Primary Key (TruckID)
);
Create Table Trip
(TripID Varchar2(10) Not Null,
 TripDate Date,
 TotalKm Number(5),
 TruckID Varchar2(10),
 Primary Key (TripID),
 Foreign Key (TruckID) References Truck(TruckID)
);
Create Table TripFrom
(TripID Varchar2(10) Not Null,
 WarehouseID Varchar2(10) Not Null,
 Primary Key (TripID, WarehouseID),
 Foreign Key (TripID) References Trip(TripID),
 Foreign Key (WarehouseID) References Warehouse(WarehouseID)
);
Create Table Store
(StoreID Varchar2(10) Not Null,
 StoreName Varchar2(20),
 StoreAddress Varchar2(20),
 Primary Key (StoreID)
);
Create Table Destination
(TripID Varchar2(10) Not Null,
 StoreID Varchar2(10) Not Null,
 Primary Key (TripID, StoreID),
 Foreign Key (TripID) References Trip(TripID),
 Foreign Key (StoreID) References Store(StoreID)
);
--Insert Records to Operational Database
Insert Into Warehouse Values ('W1','Warehouse1');
Insert Into Warehouse Values ('W2','Warehouse2');
Insert Into Warehouse Values ('W3','Warehouse3');
Insert Into Warehouse Values ('W4','Warehouse4');
Insert Into Warehouse Values ('W5','Warehouse5');
Insert Into Truck Values ('Truck1', 250, 'Medium', 1.2);
Insert Into Truck Values ('Truck2', 300, 'Medium', 1.5);
Insert Into Truck Values ('Truck3', 100, 'Small', 0.8);
Insert Into Truck Values ('Truck4', 550, 'Large', 2.3);
Insert Into Truck Values ('Truck5', 650, 'Large', 2.5);
Insert Into Trip Values ('Trip1', to_date('14-Apr-2013', 'DD-MON-YYYY'), 370, 'Truck1');
Insert Into Trip Values ('Trip2', to_date('14-Apr-2013', 'DD-MON-YYYY'), 570, 'Truck2');
Insert Into Trip Values ('Trip3', to_date('14-Apr-2013', 'DD-MON-YYYY'), 250, 'Truck3');
Insert Into Trip Values ('Trip4', to_date('15-Jul-2013', 'DD-MON-YYYY'), 450, 'Truck1');
Insert Into Trip Values ('Trip5', to_date('15-Jul-2013', 'DD-MON-YYYY'), 175, 'Truck2');
Insert Into TripFrom Values ('Trip1', 'W1');
Insert Into TripFrom Values ('Trip1', 'W4');
Insert Into TripFrom Values ('Trip1', 'W5');
Insert Into TripFrom Values ('Trip2', 'W1');
Insert Into TripFrom Values ('Trip2', 'W2');
Insert Into TripFrom Values ('Trip3', 'W1');
Insert Into TripFrom Values ('Trip3', 'W5');
Insert Into TripFrom Values ('Trip4', 'W1');
Insert Into TripFrom Values ('Trip5', 'W4');
Insert Into TripFrom Values ('Trip5', 'W5');
Insert Into Store Values ('M1', 'Myer City', 'Melbourne');
Insert Into Store Values ('M2', 'Myer Chaddy', 'Chadstone');
Insert Into Store Values ('M3', 'Myer HiPoint', 'High Point');
Insert Into Store Values ('M4', 'Myer West', 'Doncaster');

Insert Into Store Values ('M5', 'Myer North', 'Northland');
Insert Into Store Values ('M6', 'Myer South', 'Southland');
Insert Into Store Values ('M7', 'Myer East', 'Eastland');
Insert Into Store Values ('M8', 'Myer Knox', 'Knox');
Insert Into Destination Values ('Trip1', 'M1');
Insert Into Destination Values ('Trip1', 'M2');
Insert Into Destination Values ('Trip1', 'M4');
Insert Into Destination Values ('Trip1', 'M3');
Insert Into Destination Values ('Trip1', 'M8');
Insert Into Destination Values ('Trip2', 'M4');
Insert Into Destination Values ('Trip2', 'M1');
Insert Into Destination Values ('Trip2', 'M2');


Create Table TruckDim1
As Select * From Truck;


Create Table SeasonDim1
(SeasonID   VARCHAR2(3) NOT NULL,
SeasonPeriod    VARCHAR2(10) NOT NULL,
Primary Key(SeasonID)
);

Insert into SeasonDim1 Values('1', 'Summer');
Insert into SeasonDim1 Values('2', 'Autumn');
Insert into SeasonDim1 Values('3', 'Winter');
Insert into SeasonDim1 Values('4', 'Spring');

Create Table TripDim1
As Select TripID, TripDate, TotalKm
from Trip;

Create Table BridgeTableDim1
As Select TripID, StoreID
from Trip, Store;

Create Table StoreDim1
As Select * from Store;
drop table TempFact1;

Create Table TempFact1
as select t.TruckID, s.TripDate, s.TripID, s.TotalKm, t.CostPerKm
from Truck t, Trip s
where t.TruckID = s.TruckID;

Alter Table TempFact1
add( SeasonID varchar(2));
Select * from TruckFact1;
Select * from Trip;

Create Table TruckFact1
as Select * from TempFact1;

Update TempFact1
Set SeasonID = 1
Where to_char(TripDate, 'MM') < '03' and to_char(TripDate, 'MM') >= '01';

Update TempFact1
Set SeasonID = 2
Where to_char(TripDate, 'MM') < '06' and to_char(TripDate, 'MM') >= '03';

Update TempFact1
Set SeasonID = 3
Where to_char(TripDate, 'MM') < '09' and to_char(TripDate, 'MM') >= '06';

Update TempFact1
Set SeasonID = 4
Where SeasonID is NULL;

Select * from TruckFact1
Order by TruckID;

Create Table TruckFact1
As Select TruckID, SeasonID, TripID, SUM(TotalKm * CostPerKm) Total_Delivery_Cost
from TempFact1
Group by TruckID, SeasonID, TripID;

Create Table TruckFact2
As Select TruckID, SeasonID, TripID, SUM(TotalKm * CostPerKm) Total_Delivery_Cost
from TempFact1
Group by TruckID, SeasonID, TripID;


Create Table TripDim2
As select t.tripid, t.tripdate, t.totalkm, 1.0/count(d.STOREID) as WeightFactor
from trip t, destination d
where t.tripid = d.tripid
group by t.tripid, t.tripdate, t.totalkm;

Select * from destination;
select * from TripDim2;

Create Table TripDim3 As
Select T.TripID, T.TripDate, T.TotalKm, 1.0/count(D.StoreID) As
WeightFactor , LISTAGG (D.StoreID, '_') Within Group (Order By
D.StoreID) As StoreGroupList
From Trip T, Destination D
Where T.TripID = D.TripID
Group By T.TripID, T.TripDate, T.TotalKm;

Select * from TripDim3;