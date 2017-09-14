create table class_dim
as select *
from DW.CLASS;

create table major_dim
as select *
from DW.MAJOR;

create table SemesterDIM
(SemID      varchar2(3),
Sem_Desc    varchar2(15),
begin_time  date,
end_time    date);

Insert Into SemesterDIM
values ('s1', 'Semester 1', to_date('01-JAN', 'DD-MON'), to_date('15-JUL', 'DD-MON'));

Insert Into SemesterDIM
values ('s2', 'Semester 2', to_date('16-JUN', 'DD-MON'), to_date('31-DEC', 'DD-MON'));

create table labtimeDIM
(TimeID     number,
Time_Desc   varchar2(15),
begin_time  date,
end_time    date);

insert into labtimeDIM 
values(1,'morning', to_date('06:01', 'HH24:MI'), to_date('12:00', 'HH24:MI'));

insert into labtimeDIM
values(2, 'afternoon', to_date('12:01', 'HH24:MI'), to_date('18:00', 'HH24:MI'));

insert into labtimeDIM 
values(3, 'night', to_date('18:01', 'HH24:MI'), to_date('06:00', 'HH24:MI'));


-- Need intermediate process to create fact table because SemID and TimeID not in Operational Database.
--Select * from DW.STUDENT;
Create table TEMP_FACT
as select 
    u.LOG_DATE, 
    u.LOG_TIME, 
    student.MAJOR_CODE,
    student.CLASS_ID,
    student.STUDENT_ID
from 
    DW.USELOG u,
    DW.STUDENT student
where u.STUDENT_ID = student.STUDENT_ID;   -- Join statement

Alter table TEMP_FACT
Add (SemID  varchar2(2), TimeID number(1));

Update TEMP_FACT
Set SemID = 's1'
Where to_char(LOG_DATE, 'MMDD') >= '0101'
and   to_char(LOG_DATE, 'MMDD') <= '0715';

Update TEMP_FACT
Set SemID = 's2'
Where SemID is NULL;

Update TEMP_FACT
Set TimeID = '1'
Where
    to_char(LOG_TIME, 'HH24:MI') >= '06:00'
    and
    to_char(LOG_TIME, 'HH24:MI') <= '12:00';

Update TEMP_FACT
Set TimeID = '2'
Where
    to_char(LOG_TIME, 'HH24:MI') >= '12:01'
    and
    to_char(LOG_TIME, 'HH24:MI') <= '18:00';
    
Update TEMP_FACT
Set TimeID = '3'
Where
    to_char(LOG_TIME, 'HH24:MI') >= '18:01'
    or
    to_char(LOG_TIME, 'HH24:MI') <= '05:59';

Create table FACT
as select
    SemID, 
    TimeID, 
    MAJOR_CODE, 
    CLASS_ID, 
    Count(STUDENT_ID) as TotalUsage
from TEMP_FACT
group by SemID, TimeID, MAJOR_CODE, CLASS_ID;

