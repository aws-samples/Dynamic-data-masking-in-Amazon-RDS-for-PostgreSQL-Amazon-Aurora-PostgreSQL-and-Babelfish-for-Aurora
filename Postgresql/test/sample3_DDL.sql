/* 
1- First create database "DB1"
2- Create a sys schema in "DB1" database
3- Load the DDL for the DDM functions/procedure using DDM.sql
4- Execute this create in the "DB1" database to populate the sample tables and sys.pii_unmasked_columns and sys.unmasked_roles.
5- Run the DDM procedure to greate the masking views and test the generated views.
6- Note that the database name, source and view schemas have mixed cases in their names.
7- Table "user_JOB" also has a mixed-case name, and has a column "Salary" in mix cases.
*/
DROP SCHEMA IF EXISTS "SOURCE_Schema" cascade;
DROP  SCHEMA IF EXISTS "VIEW_Schema" cascade;

CREATE SCHEMA "VIEW_Schema";
CREATE SCHEMA "SOURCE_Schema";

CREATE TABLE "SOURCE_Schema".jobs(job_id int, description varchar(100));
CREATE TABLE "SOURCE_Schema".admin(name varchar(30),admin_id int, description varchar(100));
CREATE TABLE "SOURCE_Schema".users(user_id int, user_name varchar(100));
CREATE TABLE "SOURCE_Schema".user_location(location_id int, address varchar(100), user_id int);
CREATE TABLE "SOURCE_Schema".user_ssn(ssn_id int, ssn varchar(100), user_id int);
CREATE TABLE "SOURCE_Schema"."user_JOB"(job_id int, "Salary" numeric(10,2), job varchar(100), 
title varchar(100), employee_id int, user_id int, email text, hire_date date);
CREATE TABLE "SOURCE_Schema".user_bank(bank_id int, user_id int, bank_name text, account_id int, balance numeric(10,2));

INSERT INTO "SOURCE_Schema".admin VALUES ('admin1', 1, 'labs');
INSERT INTO "SOURCE_Schema".admin VALUES ('admin2', 2, 'orders');
INSERT INTO "SOURCE_Schema".admin VALUES ('admin3', 3, 'purchase');
INSERT INTO "SOURCE_Schema".admin VALUES ('admin4', 4, 'accounting');
SELECT * FROM "SOURCE_Schema".admin;

INSERT INTO "SOURCE_Schema".jobs VALUES (1, 'job1');
INSERT INTO "SOURCE_Schema".jobs VALUES (2, 'job2');
INSERT INTO "SOURCE_Schema".jobs VALUES (3, 'job3');
INSERT INTO "SOURCE_Schema".jobs VALUES (4, 'job4');
SELECT * FROM "SOURCE_Schema".jobs;

INSERT INTO "SOURCE_Schema".users VALUES (1, 'john');
INSERT INTO "SOURCE_Schema".users VALUES (2, 'mary');
INSERT INTO "SOURCE_Schema".users VALUES (3, 'brad');
INSERT INTO "SOURCE_Schema".users VALUES (4, 'jane');
INSERT INTO "SOURCE_Schema".users VALUES (5, 'julie');
INSERT INTO "SOURCE_Schema".users VALUES (6, 'jim');
INSERT INTO "SOURCE_Schema".users VALUES (7, 'bill');
SELECT * FROM "SOURCE_Schema".users;

INSERT INTO "SOURCE_Schema".user_location VALUES(1, '1111 south 1st',1);
INSERT INTO "SOURCE_Schema".user_location VALUES(2, '1111 north 21st',2);
INSERT INTO "SOURCE_Schema".user_location VALUES(3, '22 west 1st',3);
INSERT INTO "SOURCE_Schema".user_location VALUES(4, '1021 51st street',4);
INSERT INTO "SOURCE_Schema".user_location VALUES(5, '10 first street',5);
INSERT INTO "SOURCE_Schema".user_location VALUES(6, '1120 north lamar',7);
INSERT INTO "SOURCE_Schema".user_location VALUES(7, '8122 south 22',6);
SELECT * FROM "SOURCE_Schema".user_location;

INSERT INTO "SOURCE_Schema".user_bank VALUES (1, 1,'chase', 7102933, 500000);
INSERT INTO "SOURCE_Schema".user_bank VALUES (2, 1,'frost', 8100033, 100000);
INSERT INTO "SOURCE_Schema".user_bank VALUES (3, 2,'bank of america', 1111133, 200000);
INSERT INTO "SOURCE_Schema".user_bank VALUES (4, 2,'consumer', 8188833, 90000);
INSERT INTO "SOURCE_Schema".user_bank VALUES (5, 3,'wells fargo', 333333, 700000);
INSERT INTO "SOURCE_Schema".user_bank VALUES (6, 4,'frost', 19019292, 15000);
INSERT INTO "SOURCE_Schema".user_bank VALUES (7, 5,'dependence', 11111111, 60000);
INSERT INTO "SOURCE_Schema".user_bank VALUES (8, 6,'frost', 222222, 3000);
INSERT INTO "SOURCE_Schema".user_bank VALUES (9, 7,'chase', 887603, 650000);
SELECT *  FROM "SOURCE_Schema".user_bank;

INSERT INTO "SOURCE_Schema".user_ssn VALUES(1, '111-345-0881',1);
INSERT INTO "SOURCE_Schema".user_ssn VALUES(2,  '911-745-9981',2);
INSERT INTO "SOURCE_Schema".user_ssn VALUES(3,  '888-345-0081',3);
INSERT INTO "SOURCE_Schema".user_ssn VALUES(4,  '777-445-0881',4);
INSERT INTO "SOURCE_Schema".user_ssn VALUES(5,  '450-345-3535',7);
INSERT INTO "SOURCE_Schema".user_ssn VALUES(6,  '345-745-9999',5);
INSERT INTO "SOURCE_Schema".user_ssn VALUES(7,  '123-345-7777',6);
SELECT * FROM "SOURCE_Schema".user_ssn;

INSERT INTO "SOURCE_Schema"."user_JOB" VALUES(1, 300000, 'engineer','admin', 111111,1, 'john@efgh.biz', CURRENT_DATE);
INSERT INTO "SOURCE_Schema"."user_JOB" VALUES(2, 400000, 'dba','manager', 44444,2, 'mary@amazon.com', CURRENT_DATE);
INSERT INTO "SOURCE_Schema"."user_JOB" VALUES(3, 400000, 'writer','head writer', 76254,3, 'brad@aaaa.edu', CURRENT_DATE);
INSERT INTO "SOURCE_Schema"."user_JOB" VALUES(4, 400000, 'architect','vp', 109294,4, 'joe@abcd.net', CURRENT_DATE);
INSERT INTO "SOURCE_Schema"."user_JOB" VALUES(5, 400000, 'security','officer', 236514,5, 'joe@where-ur.net', CURRENT_DATE);
INSERT INTO "SOURCE_Schema"."user_JOB" VALUES(6, 400000, 'account manager','sr manager', 1029394,6, 'joe@ggggg_uwu.org', CURRENT_DATE);
INSERT INTO "SOURCE_Schema"."user_JOB" VALUES(7, 400000, 'customer rep ','customer liason', 524214,7, 'bill@abcd.gov', CURRENT_DATE);
SELECT * FROM "SOURCE_Schema"."user_JOB";

INSERT INTO sys.pii_masked_columns (database_name, schema_name, table_name, column_name, masking) 
VALUES('DB1','SOURCE_Schema','admin', 'name','MASKED WITH (FUNCTION = default(XXXXXXXX))');

INSERT INTO sys.pii_masked_columns (database_name, schema_name, table_name, column_name, masking) 
VALUES('DB1','SOURCE_Schema','users', 'user_name','MASKED WITH (FUNCTION = default(ZZZZZZZ))');

INSERT INTO sys.pii_masked_columns (database_name, schema_name, table_name, column_name, masking) 
VALUES('DB1','SOURCE_Schema','user_JOB', 'Salary','MASKED WITH (FUNCTION = default(0))');

INSERT INTO sys.pii_masked_columns (database_name, schema_name, table_name, column_name, masking) 
values('DB1','SOURCE_Schema','user_JOB', 'hire_date','MASKED WITH (FUNCTION = default())');

INSERT INTO sys.pii_masked_columns (database_name, schema_name, table_name, column_name, masking) 
VALUES('DB1','SOURCE_Schema','user_JOB', 'job','MASKED WITH (FUNCTION = random(10))');

INSERT INTO sys.pii_masked_columns (database_name, schema_name, table_name, column_name, masking) 
VALUES('DB1','SOURCE_Schema','user_JOB', 'email','MASKED WITH (FUNCTION = email())');

INSERT INTO sys.pii_masked_columns (database_name, schema_name, table_name, column_name, masking) 
VALUES('DB1','SOURCE_Schema','user_bank','bank_name','MASKED WITH (FUNCTION = partial(0,XXXXXXXX, 5))');

INSERT INTO sys.pii_masked_columns (database_name, schema_name, table_name, column_name, masking) 
VALUES('DB1','SOURCE_Schema','user_bank','account_id','MASKED WITH (FUNCTION = random(1, 100))');

INSERT INTO sys.pii_masked_columns (database_name, schema_name, table_name, column_name, masking) 
VALUES('DB1','SOURCE_Schema','user_bank','balance','MASKED WITH (FUNCTION = random(100,500))');

INSERT INTO sys.pii_masked_columns (database_name, schema_name, table_name, column_name, masking) 
VALUES('DB1','SOURCE_Schema','user_ssn','ssn','MASKED WITH (FUNCTION = partial(0,XXXXXXXX, 5))');

INSERT INTO sys.pii_masked_columns (database_name, schema_name, table_name, column_name, masking) 
VALUES('DB1','SOURCE_Schema','user_location','address','MASKED WITH (FUNCTION = partial(0,XXXXXXXX, 0))');

INSERT INTO sys.unmasked_roles (role, database_name, schema_name, table_name) 
VALUES('admin','DB1','SOURCE_Schema','admin');
INSERT INTO sys.unmasked_roles (role, database_name, schema_name, table_name) 
VALUES('admin','DB1','SOURCE_Schema','jobs');

INSERT INTO sys.unmasked_roles (role, database_name, schema_name, table_name) 
VALUES('staff','DB1','SOURCE_Schema','users');

INSERT INTO sys.unmasked_roles (role, database_name, schema_name, table_name) 
VALUES('hr','DB1','SOURCE_Schema','users');

INSERT INTO sys.unmasked_roles (role, database_name, schema_name, table_name) 
VALUES('postgres','DB1','SOURCE_Schema','user_location');

INSERT INTO sys.unmasked_roles (role, database_name, schema_name, table_name) 
VALUES('hr','DB1','SOURCE_Schema','user_JOB');

INSERT INTO sys.unmasked_roles (role, database_name, schema_name, table_name) 
VALUES('hr','DB1','SOURCE_Schema','user_bank');

INSERT INTO sys.unmasked_roles (role, database_name, schema_name, table_name) 
VALUES('hr','DB1','SOURCE_Schema','user_location');

/*
 
CALL sys.genmaskingview ('DB1','SOURCE_Schema','user_JOB','VIEW_Schema');

-- check table as role postgres
SELECT * FROM "VIEW_Schema"."user_JOB";

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'hr') THEN
        CREATE ROLE hr;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'staff') THEN
        CREATE ROLE staff;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'admin') THEN
        CREATE ROLE admin;
    END IF;
END
$$;

GRANT USAGE ON SCHEMA  "VIEW_Schema" TO hr;
GRANT USAGE ON SCHEMA  "VIEW_Schema" TO staff;
GRANT USAGE ON SCHEMA  "VIEW_Schema" TO admin;

GRANT SELECT ON "VIEW_Schema"."user_JOB" to hr;
GRANT SELECT ON "VIEW_Schema"."user_JOB" to staff;
GRANT SELECT ON "VIEW_Schema"."user_JOB" to admin;

-- Now try other roles -- defined in sys.unmaked_roles
SET ROLE hr;
SELECT * FROM "VIEW_Schema"."user_JOB";
SET ROLE staff;
SELECT * FROM "VIEW_Schema"."user_JOB";
SET ROLE admin;
SELECT * FROM "VIEW_Schema"."user_JOB";

SET ROLE postgres;
CALL sys.MaskingReconciliation('DB1', 'SOURCE_Schema','VIEW_Schema');

-- Note that there is no view on "VIEW_Schema".jobs, because there is no entry for this table in sys.pii_masked_columns
SELECT * FROM "VIEW_Schema".user_location;
SELECT * FROM "VIEW_Schema".user_bank;
SELECT * FROM "VIEW_Schema".user_ssn;
SELECT * FROM "VIEW_Schema".users;
SELECT * FROM "VIEW_Schema".admin;

GRANT SELECT ON "VIEW_Schema".user_location to hr;
GRANT SELECT ON "VIEW_Schema".user_location to staff;
GRANT SELECT ON "VIEW_Schema".user_location to admin;

GRANT SELECT ON "VIEW_Schema".user_ssn to hr;
GRANT SELECT ON "VIEW_Schema".user_ssn to staff;
GRANT SELECT ON "VIEW_Schema".user_ssn to admin;

GRANT SELECT ON "VIEW_Schema".user_bank to hr;
GRANT SELECT ON "VIEW_Schema".user_bank to staff;
GRANT SELECT ON "VIEW_Schema".user_bank to admin;

GRANT SELECT ON "VIEW_Schema".users to hr;
GRANT SELECT ON "VIEW_Schema".users to staff;
GRANT SELECT ON "VIEW_Schema".users to admin;

GRANT SELECT ON "VIEW_Schema".admin to hr;
GRANT SELECT ON "VIEW_Schema".admin to staff;
GRANT SELECT ON "VIEW_Schema".admin to admin;

SET ROLE staff;
SELECT * FROM "VIEW_Schema".user_location;
SELECT * FROM "VIEW_Schema".user_bank;
SELECT * FROM "VIEW_Schema".user_ssn;
SELECT * FROM "VIEW_Schema".users;
SELECT * FROM "VIEW_Schema".admin;

SET ROLE admin;
SELECT * FROM "VIEW_Schema".user_location;
SELECT * FROM "VIEW_Schema".user_bank;
SELECT * FROM "VIEW_Schema".user_ssn;
SELECT * FROM "VIEW_Schema".users;
SELECT * FROM "VIEW_Schema".admin;

SET ROLE hr;
SELECT * FROM "VIEW_Schema".user_location;
SELECT * FROM "VIEW_Schema".user_bank;
SELECT * FROM "VIEW_Schema".user_ssn;
SELECT * FROM "VIEW_Schema".users;
SELECT * FROM "VIEW_Schema".admin;

*/