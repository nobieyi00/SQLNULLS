

--Section 1: Null Propagation
-- when NULL combined to a value or column it is results to NULL
Select 10 * NULL
Select NULL/0 --dividing by 0 is still unknown
Select 10  + Null
select 'Abc' || Null

--Section 2: Null Logical evaluation
--- Always note that Nulls when evaluated will result to Null (unknown)
select 1 = 1
select 1 = 2
select 1 != 1
select NULL = 1
select NULL < 10
select NULL <> 'Hello'  ---note this
select 1 != Null
select null = null

--Section 3: NULL with Boolean Operators
-- In this case think of NULL as Unknown can be either True or False
select True and True
Select False and True
select False and False
select False or True
select True or True
Select False or False


Select NULL and True
Select NULL and False
select NULL or True
Select NULL or False



--NULL in where Condition
---Prep Demo table
Create Table Sample (Col1 int);
insert into Sample (Col1)
select 1
union select 2
union select Null

--select from table
select * 
from Sample

---Null in where clause
---This will not work, Null evaluates to Unknown and where clause only returns true
select *
from Sample
where Col1 = Null  --Common rookie mistake by junior developers. Note this evalutes to NUll for entire table


Select * 
from Sample where Col1 is null


Select * 
from Sample where Col1 is not null

---Becareful when filters for a column that with a set of values that might have Null
Select *
from Sample
where Col1 =1 and Col1 = Null ---does not matter what the second predicate is, it will make entire where clause to be NULL


select *
from Sample
where Col1 = 1 or Col1 = Null 


---above is same as
select *
from Sample
where Col1 in (1, Null)  


create table sub (fid int)
insert into sub (fid)
select Null
union select 1

select * from sub

--- same as 
select * from Sample
where Col1 in (select fid from sub)

---Here is where it gets TRICKY. NOTE for Advanced Programmers
--if I want to get the records not in sub table, ie return 2
select * from Sample
where Col1 not in (select fid from sub)
---no results!!
--because
select * from Sample
where Col1 not in (1, Null)

select * from Sample
where Col1 <> 1 and Col1 <> Null  ---evaluate to null for all rows

---correct way for writing
select * from Sample
where Col1 not in (select fid from sub where fid is not null)

---Section 3: NULL in the Case condition and IF statements

Select Case when 1 = NULL THEN 'First'
else 'Second' end -- case goes evaluate the first true condition, then goes for the next or else block
--Therefore, the else block maybe executed in a NULL or False condition

Select Case when 1 = 2 THEN 'First'
when 1 <> Null then 'Second' else 'Third' end


---NULL in Aggregate function
--Aggregate functions only operate on the not null fields except for count(*) or count(1) or aggregate over a literal value Sum(1)
select * from Sample
select count(*), count(Col1), sum(Col1), Avg(col1), sum(col1)/count(*)
from Sample

--Note Avg(col) is SUM(COl)/Count(Col) it is not SUM(col)/ count(*)

--Handling NULLs
--Coalesce
select col1, Coalesce(Col1, 0) from Sample


---Real world bug 
---In Merge statement---Check for Nulls
MERGE TargetProducts AS Target
USING SourceProducts AS Source
ON Source.ProductID = Target.ProductID
    
-- For Inserts
WHEN NOT MATCHED BY Target THEN
    INSERT (ProductID,ProductName, Price) 
    VALUES (Source.ProductID,Source.ProductName, Source.Price)
    
-- For Updates
WHEN MATCHED and (Target.ProductName != Source.ProductName
                  or Target.Price != Source.Price
				---fix  
				  or Target.ProductName is NULL
				  or Target.Price is NULL
				 )THEN UPDATE SET
    Target.ProductName = Source.ProductName,
    Target.Price  = Source.Price