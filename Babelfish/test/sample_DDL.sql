IF  EXISTS (SELECT * FROM sys.databases WHERE name = 'users')
DROP DATABASE users
GO
CREATE DATABASE users;
GO
USE users
GO
CREATE SCHEMA source_schema;
GO
CREATE SCHEMA view_schema;
GO

CREATE TABLE source_schema.jobs(job_id int, description varchar(100));
CREATE TABLE source_schema.admin(name varchar(30),admin_id int, description varchar(100));
CREATE TABLE source_schema.users(user_id int, user_name varchar(100));
CREATE TABLE source_schema.user_location(location_id int, address varchar(100), user_id int);
CREATE TABLE source_schema.user_ssn(ssn_id int, ssn varchar(100), user_id int);
CREATE TABLE source_schema.user_job(job_id int, salary varchar(100), job varchar(100), title varchar(100), employee_id int, user_id int, email text);
CREATE TABLE source_schema.user_bank(bank_id int, user_id int, bank_name text, account_id int, balance numeric(10,2));

INSERT INTO source_schema.admin VALUES ('admin1', 1, 'labs');
INSERT INTO source_schema.admin VALUES ('admin2', 2, 'orders');
INSERT INTO source_schema.admin VALUES ('admin3', 3, 'purchase');
INSERT INTO source_schema.admin VALUES ('admin4', 4, 'accounting');
SELECT * FROM source_schema.admin;

INSERT INTO source_schema.jobs VALUES (1, 'job1');
INSERT INTO source_schema.jobs VALUES (2, 'job2');
INSERT INTO source_schema.jobs VALUES (3, 'job3');
INSERT INTO source_schema.jobs VALUES (4, 'job4');
SELECT * FROM source_schema.jobs;

INSERT INTO source_schema.users VALUES (1, 'john');
INSERT INTO source_schema.users VALUES (2, 'mary');
INSERT INTO source_schema.users VALUES (3, 'brad');
INSERT INTO source_schema.users VALUES (4, 'jane');
INSERT INTO source_schema.users VALUES (5, 'julie');
INSERT INTO source_schema.users VALUES (6, 'jim');
INSERT INTO source_schema.users VALUES (7, 'bill');
SELECT * FROM source_schema.users;

INSERT INTO source_schema.user_location VALUES(1, '1111 south 1st',1);
INSERT INTO source_schema.user_location VALUES(2, '1111 north 21st',2);
INSERT INTO source_schema.user_location VALUES(3, '22 west 1st',3);
INSERT INTO source_schema.user_location VALUES(4, '1021 51st street',4);
INSERT INTO source_schema.user_location VALUES(5, '10 first street',5);
INSERT INTO source_schema.user_location VALUES(6, '1120 north lamar',7);
INSERT INTO source_schema.user_location VALUES(7, '8122 south 22',6);
SELECT * FROM source_schema.user_location;

INSERT INTO source_schema.user_bank VALUES (1, 1,'chase', 7102933, 500000);
INSERT INTO source_schema.user_bank VALUES (2, 1,'frost', 8100033, 100000);
INSERT INTO source_schema.user_bank VALUES (3, 2,'bank of america', 1111133, 200000);
INSERT INTO source_schema.user_bank VALUES (4, 2,'consumer', 8188833, 90000);
INSERT INTO source_schema.user_bank VALUES (5, 3,'wells fargo', 333333, 700000);
INSERT INTO source_schema.user_bank VALUES (6, 4,'frost', 19019292, 15000);
INSERT INTO source_schema.user_bank VALUES (7, 5,'dependence', 11111111, 60000);
INSERT INTO source_schema.user_bank VALUES (8, 6,'frost', 222222, 3000);
INSERT INTO source_schema.user_bank VALUES (9, 7,'chase', 887603, 650000);
SELECT *  FROM source_schema.user_bank;

INSERT INTO source_schema.user_ssn VALUES(1, '111-345-0881',1);
INSERT INTO source_schema.user_ssn VALUES(2,  '911-745-9981',2);
INSERT INTO source_schema.user_ssn VALUES(3,  '888-345-0081',3);
INSERT INTO source_schema.user_ssn VALUES(4,  '777-445-0881',4);
INSERT INTO source_schema.user_ssn VALUES(5,  '450-345-3535',7);
INSERT INTO source_schema.user_ssn VALUES(6,  '345-745-9999',5);
INSERT INTO source_schema.user_ssn VALUES(7,  '123-345-7777',6);
SELECT * FROM source_schema.user_ssn;

INSERT INTO source_schema.user_job VALUES(1, 300000, 'engineer','admin', 111111,1, 'john@efgh.biz');
INSERT INTO source_schema.user_job VALUES(2, 400000, 'dba','manager', 44444,2, 'mary@amazon.com');
INSERT INTO source_schema.user_job VALUES(3, 400000, 'writer','head writer', 76254,3, 'brad@aaaa.edu');
INSERT INTO source_schema.user_job VALUES(4, 400000, 'architect','vp', 109294,4, 'joe@abcd.net');
INSERT INTO source_schema.user_job VALUES(5, 400000, 'security','officer', 236514,5, 'joe@where-ur.net');
INSERT INTO source_schema.user_job VALUES(6, 400000, 'account manager','sr manager', 1029394,6, 'joe@ggggg_uwu.org');
INSERT INTO source_schema.user_job VALUES(7, 400000, 'customer rep ','customer liason', 524214,7, 'bill@abcd.gov');
SELECT * FROM source_schema.user_job;

--
INSERT INTO sys.pii_masked_columns (database_name, schema_name, table_name, column_name, masking) 
VALUES('users','source_schema','admin', 'name','MASKED WITH (FUNCTION = default())');

INSERT INTO sys.pii_masked_columns (database_name, schema_name, table_name, column_name, masking) 
VALUES('users','source_schema','users', 'user_name','MASKED WITH (FUNCTION = default())');

INSERT INTO sys.pii_masked_columns (database_name, schema_name, table_name, column_name, masking) 
VALUES('users','source_schema','user_job', 'salary','MASKED WITH (FUNCTION = default())');

INSERT INTO sys.pii_masked_columns (database_name, schema_name, table_name, column_name, masking) 
values('users','source_schema','user_job', 'title','MASKED WITH (FUNCTION = default())');

INSERT INTO sys.pii_masked_columns (database_name, schema_name, table_name, column_name, masking) 
VALUES('users','source_schema','user_job', 'job','MASKED WITH (FUNCTION = default())');

INSERT INTO sys.pii_masked_columns (database_name, schema_name, table_name, column_name, masking) 
VALUES('users','source_schema','user_job', 'email','MASKED WITH (FUNCTION = email())');

INSERT INTO sys.pii_masked_columns (database_name, schema_name, table_name, column_name, masking) 
VALUES('users','source_schema','user_bank','bank_name','MASKED WITH (FUNCTION = partial(0,XXXXXXXX, 5))');

INSERT INTO sys.pii_masked_columns (database_name, schema_name, table_name, column_name, masking) 
VALUES('users','source_schema','user_bank','account_id','MASKED WITH (FUNCTION = random(1, 100))');

INSERT INTO sys.pii_masked_columns (database_name, schema_name, table_name, column_name, masking) 
VALUES('users','source_schema','user_bank','balance','MASKED WITH (FUNCTION = random(100,500))');

INSERT INTO sys.pii_masked_columns (database_name, schema_name, table_name, column_name, masking) 
VALUES('users','source_schema','user_ssn','ssn','MASKED WITH (FUNCTION = partial(0,XXXXXXXX, 5))');

INSERT INTO sys.pii_masked_columns (database_name, schema_name, table_name, column_name, masking) 
VALUES('users','source_schema','user_location','address','MASKED WITH (FUNCTION = partial(0,XXXXXXXX, 0))');



INSERT INTO sys.unmasked_roles (role, database_name, schema_name, table_name) 
VALUES('admin','users','source_schema','user_location');

INSERT INTO sys.unmasked_roles (role, database_name, schema_name, table_name) 
VALUES('admin','users','source_schema','job');

INSERT INTO sys.unmasked_roles (role, database_name, schema_name, table_name) 
VALUES('staff','users','source_schema','users');

INSERT INTO sys.unmasked_roles (role, database_name, schema_name, table_name) 
VALUES('hr','users','source_schema','users');

INSERT INTO sys.unmasked_roles (role, database_name, schema_name, table_name) 
VALUES('postgres','users','source_schema','user_location');

INSERT INTO sys.unmasked_roles (role, database_name, schema_name, table_name) 
VALUES('hr','users','source_schema','user_job');

INSERT INTO sys.unmasked_roles (role, database_name, schema_name, table_name) 
VALUES('hr','users','source_schema','user_bank');

INSERT INTO sys.unmasked_roles (role, database_name, schema_name, table_name) 
VALUES('hr','users','source_schema','user_location');

/*
exec sys.GenMaskingView @p_database = 'users', @p_source_schema = 'source_schema', @p_source_table= 'users', @p_view_schema = 'view_schema'

exec sys.MaskingReconciliation @p_database = 'users', @p_source_schema = 'source_schema', @p_view_schema = 'view_schema' 

*/
