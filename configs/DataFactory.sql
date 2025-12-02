-- Create Tables
create table emp(
    ename varchar(50),
    esalary int,
    ejoineddate datetime
);

create table cust(
    cname varchar(50),
    accounttype varchar(50),
    acccreation datetime
);

create table orders(
    productname varchar(50),
    quantity int,
    orderdate datetime
);

---------------------------------------------------------
-- Insert Data
---------------------------------------------------------

-- EMP
INSERT INTO emp (ename, esalary, ejoineddate) VALUES
('rama', 5000, '2023-01-01 10:10:10'),
('krishna', 2000, '2023-01-02 10:10:10'),
('sai', 3000, '2023-01-03 10:10:10');

-- CUST
insert into cust (cname, accounttype, acccreation) values
('david', 'saving', '2023-01-01 10:10:10'),
('michel', 'current', '2023-01-01 10:10:10'),
('warner', 'saving', '2023-01-02 10:10:10');

-- ORDERS
insert into orders (productname, quantity, orderdate) values
('laptop', 1, '2023-01-01 10:10:10'),
('mobile', 1, '2023-01-10 10:10:10');
---------------------------------------------------------
-- Metadata Table
---------------------------------------------------------

create table metadata(
    schemaname varchar(50),
    tablename varchar(50),
    deltacol varchar(50),
    last_processed_value datetime,
    foldername varchar(50)
);

-- Insert Metadata  --last_processed_value dummy timestamp < emp, cust , order timestamp;
insert into metadata (schemaname, tablename, deltacol, last_processed_value, foldername) values
('dbo', 'emp', 'ejoineddate', '2023-01-01 09:10:10', 'empdata'),
('dbo', 'cust', 'acccreation', '2023-01-01 09:10:10', 'custdata'),
('dbo', 'orders', 'orderdate', '2023-01-01 09:10:10', 'orderdata');

---------------------------------------------------------
-- Stored Procedure
---------------------------------------------------------

create proc metadata_usp 
    @LPV datetime,    --Last Processed Value
    @tablename varchar(50)
as
begin
    update metadata 
    set last_processed_value = @LPV 
    where tablename = @tablename;
end;


select * from emp;

select * from cust;

select * from orders;

select * from metadata;

-------------------------------------
--max value of deltacolumn in each and every table and schema
select max(@{item().deltacol}) as maxvalue from @{item().schemaname}.@{item().tablename}

select * from @{item().schemaname}.@{item().tablename} where @{item().deltacol} > '@{item().last_processed_value}'