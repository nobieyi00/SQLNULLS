
Drop table if exists PRODUCT_DIM ;
drop table if exists PRODUCT_STAGE ;

CREATE TABLE PRODUCT_DIM 
(
    ID INT,
    NAME VARCHAR(50),
    Description VARCHAR(200),
    LAST_MODIFIED_DATE DATETIME
)
go

CREATE TABLE PRODUCT_STAGE 
(
    ID INT,
    NAME VARCHAR(50),
    Description VARCHAR(200),
    LAST_MODIFIED_DATE DATETIME
)
GO

insert into PRODUCT_DIM 
select 1, 'Hammer', 'Object to hit a nail', '2023-02-02 10:04:01'
union ALL
select 2, 'Plier', 'Object to clamp', '2023-02-03 10:04:01'
union ALL
select 3, 'Nail', null, '2023-01-03 10:04:01'

insert into PRODUCT_STAGE 
select 4, 'Spanner', 'Object to span', '2023-02-03 10:04:01'
union ALL
select 3, 'Nail', 'Object to make hole', '2023-02-03 10:04:01'
union all
select 2, 'Plier', 'Object to clamp', '2023-02-04 10:04:01'

SELECT * FROM PRODUCT_DIM 

SELECT * FROM PRODUCT_STAGE 

select * from PRODUCT_DIM

--Default code--This will not work
MERGE PRODUCT_DIM  AS Target
    USING PRODUCT_STAGE 	AS Source
    ON Source.ID = Target.ID
    
    -- For Inserts
    WHEN NOT MATCHED BY Target THEN
        INSERT (ID,Name, Description,LAST_MODIFIED_DATE) 
        VALUES (Source.ID,Source.Name, Source.Description, Source.LAST_MODIFIED_DATE)
    
    -- For Updates
    WHEN MATCHED AND (Target.Name <> Source.Name 
                    or Target.Description <> Source.Description 
                    ) THEN UPDATE SET
        Target.Name	= Source.Name,
        Target.Description		= Source.Description,
        Target.LAST_MODIFIED_DATE	= Source.LAST_MODIFIED_DATE;


SELECT * FROM PRODUCT_DIM 

---Solution 1: Use isnull or coalsece to replace the null values before comparison
MERGE PRODUCT_DIM  AS Target
    USING PRODUCT_STAGE 	AS Source
    ON Source.ID = Target.ID
    
    -- For Inserts
    WHEN NOT MATCHED BY Target THEN
        INSERT (ID,Name, Description,LAST_MODIFIED_DATE) 
        VALUES (Source.ID,Source.Name, Source.Description, Source.LAST_MODIFIED_DATE)
    
    -- For Updates
    WHEN MATCHED AND (Target.Name <> Source.Name 
                    or isnull(Target.Description,'') <> Source.Description 
                    ) THEN UPDATE SET
        Target.Name	= Source.Name,
        Target.Description = Source.Description,
        Target.LAST_MODIFIED_DATE = Source.LAST_MODIFIED_DATE;

---Problem
--1. You need to know what to replace null with, might work for strings but what about numeric fields, replacing with zero might not be accurate
--2. Does not work in PySpark


---Solution 2: always update the nullable fields when matched
MERGE PRODUCT_DIM  AS Target
    USING PRODUCT_STAGE 	AS Source
    ON Source.ID = Target.ID
    
    -- For Inserts
    WHEN NOT MATCHED BY Target THEN
        INSERT (ID,Name, Description,LAST_MODIFIED_DATE) 
        VALUES (Source.ID,Source.Name, Source.Description, Source.LAST_MODIFIED_DATE)
    
    -- For Updates
    WHEN MATCHED AND (Target.Name <> Source.Name 
                    or Target.Description <> Source.Description 
                    or Target.Description is null or Target.Name is null
                    ) THEN UPDATE SET
        Target.Name	= Source.Name,
        Target.Description = Source.Description,
        Target.LAST_MODIFIED_DATE = Source.LAST_MODIFIED_DATE;

        
SELECT * FROM PRODUCT_DIM 

---Problem: We end up updating more records than necessary

---Solution 3: Find out the true incremental records using EXCEPT then use those to do the update


--let's understand Except
select * 
from (
    select 1 col1
    union select 2
    union select 3
)a

EXCEPT

select col1 
from 
    (select 1 col1
    union select 2
    ) b

---it treats null as a literal value

select * 
from (
    select 1 col1
    union select null
    union select 3
)a

EXCEPT

select col1 
from 
    (select 1 col1
    union select null
    ) b

---get the records that truly changed
select ID,Name, Description from PRODUCT_STAGE
except 
select ID,Name, Description from PRODUCT_DIM 

---get all fields from the source using the Ids of the truly changed records
select ID  
into #Stage_ID from (
select ID,Name, Description from PRODUCT_STAGE
except 
select ID,Name, Description from PRODUCT_DIM )a


---We need all columns from stage to merge to the target


select * 
from PRODUCT_STAGE where ID in (select ID from #Stage_ID)

MERGE PRODUCT_DIM  AS Target
    USING (select * 
            from PRODUCT_STAGE where ID in (select ID from #Stage_ID)
            )	AS Source
    ON Source.ID = Target.ID
    
    -- For Inserts
    WHEN NOT MATCHED BY Target THEN
        INSERT (ID,Name, Description,LAST_MODIFIED_DATE) 
        VALUES (Source.ID,Source.Name, Source.Description, Source.LAST_MODIFIED_DATE)
    
    -- For Updates
    WHEN MATCHED THEN UPDATE SET
        Target.Name	= Source.Name,
        Target.Description = Source.Description,
        Target.LAST_MODIFIED_DATE = Source.LAST_MODIFIED_DATE;


select * 
from PRODUCT_DIM