USE master
GO
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
CREATE TABLE source_schema.user_job(job_id int, salary numeric(10,2), job varchar(100), title varchar(100), employee_id int, user_id int, email text, hire_date date, optout bit);
CREATE TABLE source_schema.user_bank(bank_id int, user_id int, bank_name text, account_id int, balance numeric(10,2));
CREATE TABLE source_schema.usps_zipcodes(
	[id] [int] IDENTITY(1,1) NOT NULL,
	[zipcode] [varchar](5) NOT NULL,
	[citystatekey] [varchar](6) NULL,
	[zipclassification] [varchar](1) NULL,
	[citystatename] [varchar](28) NULL,
	[citystatenameabbrev] [varchar](13) NULL,
	[citystatenamefacility] [varchar](1) NULL,
	[citystatemailingnameind] [varchar](1) NULL,
	[preflastlinekey] [varchar](6) NULL,
	[preflastlinename] [varchar](28) NULL,
	[citydelivind] [varchar](1) NULL,
	[carrratesortind] [varchar](1) NULL,
	[uniquezipnameinc] [varchar](1) NULL,
	[financeno] [varchar](6) NULL,
	[stateabbrev] [varchar](2) NULL,
	[countyno] [varchar](3) NULL,
	[countyname] [varchar](25) NULL);
CREATE TABLE source_schema.ctrpersons_data_customers(
	[ctrpersonsdcid] [bigint] IDENTITY(1,1) NOT NULL,
	[sourcetable] [varchar](9) NOT NULL,
	[accountid] [int] NULL,
	[accountnumber] [varchar](50) NULL,
	[applicationcode] [varchar](50) NULL,
	[institutionnumber] [int] NULL,
	[branchnumber] [int] NULL,
	[dba] [varchar](255) NULL,
	[businesstypeid] [int] NULL,
	[businesstypecode] [varchar](50) NULL,
	[personid] [varchar](62) NULL,
	[customerid] [int] NOT NULL,
	[cisnumber] [varchar](50) NULL,
	[idstring] [varchar](295) NULL,
	[tinidstring] [varchar](377) NULL,
	[name] [varchar](255) NOT NULL,
	[lastname] [varchar](255) NULL,
	[firstname] [varchar](255) NULL,
	[middlename] [varchar](255) NULL,
	[tin] [varchar](50) NULL,
	[identifyingnumber] [varchar](255) NULL,
	[birthdate] [datetime] NULL,
	[occupation] [varchar](255) NULL,
	[idtypevalue] [int] NULL,
	[idtype] [varchar](1) NOT NULL,
	[idnumber] [varchar](255) NULL,
	[idissuingauthority] [varchar](255) NULL,
	[idissuingcountry] [varchar](255) NULL,
	[idissuingstate] [varchar](255) NULL,
	[otheridtypename] [varchar](255) NULL,
	[phonenumber] [varchar](50) NULL,
	[street] [varchar](255) NOT NULL,
	[city] [varchar](255) NOT NULL,
	[zipcode] [varchar](10) NOT NULL,
	[stateid] [int] NOT NULL,
	[statecode] [varchar](50) NULL,
	[countryid] [int] NOT NULL,
	[countrycode] [varchar](50) NULL,
	[isentity] [bit] NULL,
	[accountentity] [bit] NULL,
	[noncustomerid] [int] NOT NULL,
	[isactive] [int] NULL,
	[suffix] [varchar](50) NULL,
	[genderid] [int] NOT NULL,
	[gender] [varchar](50) NULL,
	[gendercode] [varchar](50) NULL,
	[naicscode] [varchar](50) NULL,
	[tincodeid] [int] NOT NULL,
	[tintype] [varchar](50) NULL,
	[tincodecode] [varchar](50) NULL,
	[phonenumberextension] [varchar](50) NULL,
	[emailaddress] [varchar](50) NULL,
	[lastnameunknown] [bit] NULL,
	[firstnameunknown] [bit] NULL,
	[tinunknown] [bit] NULL,
	[birthdateunknown] [bit] NULL,
	[formofidentificationunknown] [bit] NULL,
	[streetunknown] [bit] NULL,
	[cityunknown] [bit] NULL,
	[stateunknown] [bit] NULL,
	[zipcodeunknown] [bit] NULL,
	[countryunknown] [bit] NULL,
	[createddate] [datetime] NOT NULL,
	[createdby] [int] NOT NULL,
	[lastmodifieddate] [datetime] NULL,
	[lastmodifiedby] [int] NULL,
	[orderrank] [int] NOT NULL,
	[dateorder] [datetime] NULL,
	[isholder] [int] NULL,
	[nickname] [varchar](100) NULL,
	[tin_formatted] [varchar](50) NULL);

CREATE TABLE source_schema.noncustomers(
	[noncustomerid] [int] IDENTITY(1,1) NOT NULL,
	[name] [varchar](255) NOT NULL,
	[firstname] [varchar](255) NULL,
	[lastname] [varchar](255) NULL,
	[middlename] [varchar](255) NULL,
	[dba] [varchar](255) NULL,
	[birthdate] [datetime] NULL,
	[identifyingnumber] [varchar](255) NULL,
	[occupation] [varchar](255) NULL,
	[tin] [varchar](50) NULL,
	[idtype] [tinyint] NULL,
	[otheridtypename] [varchar](255) NULL,
	[idnumber] [varchar](255) NULL,
	[idissuingauthority] [varchar](255) NULL,
	[street] [varchar](255) NULL,
	[city] [varchar](255) NULL,
	[stateid] [int] NULL,
	[countryid] [int] NULL,
	[zipcode] [varchar](10) NULL,
	[createddate] [datetime] NOT NULL,
	[createdby] [int] NOT NULL,
	[lastmodifieddate] [datetime] NULL,
	[lastmodifiedby] [int] NULL,
	[customerid] [int] NULL,
	[isactive] [bit] NULL,
	[isentity] [bit] NULL,
	[lastnameunknown] [bit] NULL,
	[firstnameunknown] [bit] NULL,
	[suffix] [varchar](255) NULL,
	[gender] [varchar](1) NULL,
	[naicscode] [varchar](50) NULL,
	[tinunknown] [bit] NULL,
	[tintype] [varchar](1) NULL,
	[birthdateunknown] [bit] NULL,
	[phonenumber] [varchar](16) NULL,
	[phonenumberextension] [varchar](6) NULL,
	[emailaddress] [varchar](50) NULL,
	[formofidentificationunknown] [bit] NULL,
	[streetunknown] [bit] NULL,
	[cityunknown] [bit] NULL,
	[stateunknown] [bit] NULL,
	[zipcodeunknown] [bit] NULL,
	[countryunknown] [bit] NULL,
	[idissuingauthoritycountry] [varchar](255) NULL,
	[idissuingauthoritystate] [varchar](255) NULL,
	[tincodecode] [varchar](50) NULL,
	[gendercode] [varchar](50) NULL,
	[countrycode] [varchar](50) NULL,
	[statecode] [varchar](50) NULL,
	[tin_formatted] [varchar](50) NULL,
	[nickname] [varchar](100) NULL,
	[nametitle] [varchar](50) NULL,
	[allowcalls] [bit] NULL,
	[allowtexts] [bit] NULL,
	[allowemails] [bit] NULL,
	[ipaddress] [varchar](100) NULL,
	[cellphone] [varchar](50) NULL,
	[cellphoneinternationalprefix] [varchar](10) NULL,
	[modifiedby] [varchar](100) NULL,
	[englishdescription] [varchar](8000) NULL,
	[usercomments] [varchar](8000) NULL);

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

INSERT INTO source_schema.user_job VALUES(1, 300000, 'engineer','admin', 111111,1, 'john@efgh.biz', GETDATE(), 0);
INSERT INTO source_schema.user_job VALUES(2, 400000, 'dba','manager', 44444,2, 'mary@amazon.com', GETDATE(), 1);
INSERT INTO source_schema.user_job VALUES(3, 400000, 'writer','head writer', 76254,3, 'brad@aaaa.edu', GETDATE(), 1);
INSERT INTO source_schema.user_job VALUES(4, 400000, 'architect','vp', 109294,4, 'joe@abcd.net', GETDATE(),0);
INSERT INTO source_schema.user_job VALUES(5, 400000, 'security','officer', 236514,5, 'joe@where-ur.net', GETDATE(), 1);
INSERT INTO source_schema.user_job VALUES(6, 400000, 'account manager','sr manager', 1029394,6, 'joe@ggggg_uwu.org', GETDATE(),0 );
INSERT INTO source_schema.user_job VALUES(7, 400000, 'customer rep ','customer liason', 524214,7, 'bill@abcd.gov', GETDATE(), 0);
select * from source_schema.user_job

-- ctrpersons_data_customers (IDENTITY column ctrpersonsdcid is auto-generated)
SET IDENTITY_INSERT source_schema.ctrpersons_data_customers OFF;

INSERT INTO source_schema.ctrpersons_data_customers
(sourcetable, accountid, accountnumber, applicationcode, institutionnumber, branchnumber, dba, businesstypeid, businesstypecode, personid, customerid, cisnumber, idstring, tinidstring, name, lastname, firstname, middlename, tin, identifyingnumber, birthdate, occupation, idtypevalue, idtype, idnumber, idissuingauthority, idissuingcountry, idissuingstate, otheridtypename, phonenumber, street, city, zipcode, stateid, statecode, countryid, countrycode, isentity, accountentity, noncustomerid, isactive, suffix, genderid, gender, gendercode, naicscode, tincodeid, tintype, tincodecode, phonenumberextension, emailaddress, lastnameunknown, firstnameunknown, tinunknown, birthdateunknown, formofidentificationunknown, streetunknown, cityunknown, stateunknown, zipcodeunknown, countryunknown, createddate, createdby, lastmodifieddate, lastmodifiedby, orderrank, dateorder, isholder, nickname, tin_formatted)
VALUES
('CTR2013', 1001, 'ACC-10001', 'APP01', 100, 10, 'Acme Corp', 1, 'BT01', 'PER-001', 1, 'CIS001', 'ID-STR-001', 'TIN-STR-001', 'John Smith', 'Smith', 'John', 'A', '123-45-6789', 'DL12345', '1985-03-15', 'Engineer', 1, 'D', 'DL-99001', 'DMV', 'US', 'TX', NULL, '512-555-0101', '100 Main St', 'Austin', '78701', 1, 'TX', 1, 'US', 0, 0, 0, 1, NULL, 1, 'Male', 'M', '541511', 1, 'SSN', 'SSN', '101', 'john.smith@example.com', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '2024-01-10', 1, '2024-06-01', 1, 1, '2024-01-10', 1, 'Johnny', '123-45-6789'),

('CTR2013', 1002, 'ACC-10002', 'APP01', 100, 11, 'Beta LLC', 2, 'BT02', 'PER-002', 2, 'CIS002', 'ID-STR-002', 'TIN-STR-002', 'Jane Doe', 'Doe', 'Jane', 'B', '987-65-4321', 'PP78900', '1990-07-22', 'Analyst', 2, 'P', 'PP-88002', 'State Dept', 'US', 'CA', NULL, '415-555-0202', '200 Oak Ave', 'San Francisco', '94102', 2, 'CA', 1, 'US', 0, 1, 0, 1, 'Jr', 2, 'Female', 'F', '523110', 1, 'SSN', 'SSN', '202', 'jane.doe@example.com', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '2024-02-15', 1, '2024-06-10', 2, 2, '2024-02-15', 0, 'JD', '987-65-4321'),

('CTR2013', 1003, 'ACC-10003', 'APP02', 101, 12, NULL, 3, 'BT03', 'PER-003', 3, 'CIS003', 'ID-STR-003', 'TIN-STR-003', 'Carlos Rivera', 'Rivera', 'Carlos', 'M', '555-12-3456', 'ML33210', '1978-11-05', 'Manager', 3, 'M', 'ML-77003', 'Military', 'US', 'FL', NULL, '305-555-0303', '300 Palm Blvd', 'Miami', '33101', 3, 'FL', 1, 'US', 0, 0, 0, 1, NULL, 1, 'Male', 'M', '722511', 2, 'EIN', 'EIN', NULL, 'carlos.r@example.com', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '2024-03-20', 2, NULL, NULL, 3, '2024-03-20', 1, NULL, '555-12-3456');

SELECT * FROM source_schema.ctrpersons_data_customers;

-- usps_zipcodes (IDENTITY column id is auto-generated)
SET IDENTITY_INSERT source_schema.usps_zipcodes OFF;

INSERT INTO source_schema.usps_zipcodes
(zipcode, citystatekey, zipclassification, citystatename, citystatenameabbrev, citystatenamefacility, citystatemailingnameind, preflastlinekey, preflastlinename, citydelivind, carrratesortind, uniquezipnameinc, financeno, stateabbrev, countyno, countyname)
VALUES
('78701', 'TX0001', 'N', 'AUSTIN', 'AUSTIN', 'Y', 'Y', 'TX0001', 'AUSTIN', 'Y', 'Y', 'Y', '000001', 'TX', '453', 'TRAVIS'),
('94102', 'CA0001', 'N', 'SAN FRANCISCO', 'S FRANCISCO', 'Y', 'Y', 'CA0001', 'SAN FRANCISCO', 'Y', 'Y', 'N', '000002', 'CA', '075', 'SAN FRANCISCO'),
('33101', 'FL0001', 'P', 'MIAMI', 'MIAMI', 'Y', 'N', 'FL0001', 'MIAMI', 'Y', 'Y', 'Y', '000003', 'FL', '086', 'MIAMI-DADE');

SELECT * FROM source_schema.usps_zipcodes;

INSERT INTO source_schema.noncustomers 
(name, firstname, lastname, middlename, dba, birthdate, identifyingnumber, occupation, tin, idtype, street, city, stateid, countryid, zipcode, createddate, createdby, isactive, isentity, gender, phonenumber, emailaddress)
VALUES 
('Johnathan Q. Public', 'Johnathan', 'Public', 'Quincy', NULL, '1985-05-12', 'ID-99821', 'Software Engineer', '123-45-6789', 1, '123 Maple St', 'Austin', 43, 1, '78701', GETDATE(), 1, 1, 0, 'M', '5125550101', 'john.public@email.com'),
('TechNova Solutions LLC', NULL, NULL, NULL, 'TechNova', NULL, 'BUS-4451', 'Information Technology', '99-8877665', 2, '500 Oracle Way', 'San Francisco', 5, 1, '94105', GETDATE(), 1, 1, 1, NULL, '4155550202', 'billing@technova.io'),
('Sarah Smith', 'Sarah', 'Smith', NULL, NULL, '1992-11-30', NULL, 'Architect', NULL, 1, '789 Pine Rd', 'Seattle', 47, 1, '98101', GETDATE(), 1, 1, 0, 'F', '2065550303', 'ssmith92@email.com'),
('Elena Rodriguez', 'Elena', 'Rodriguez', 'Maria', NULL, '1978-02-15', 'PASS-7721', 'Consultant', NULL, 3, 'Calle de Alcalá 14', 'Madrid', NULL, 72, '28014', GETDATE(), 2, 0, 0, 'F', '34915550404', 'elena.rod@provider.es');

--
INSERT INTO sys.pii_masked_columns (database_name, schema_name, table_name, column_name, masking) 
VALUES('users','source_schema','admin', 'name','MASKED WITH (FUNCTION = default(XXXXXXXX))');

INSERT INTO sys.pii_masked_columns (database_name, schema_name, table_name, column_name, masking) 
VALUES('users','source_schema','users', 'user_name','MASKED WITH (FUNCTION = default(ZZZZZZZ))');

INSERT INTO sys.pii_masked_columns (database_name, schema_name, table_name, column_name, masking) 
VALUES('users','source_schema','user_job', 'salary','MASKED WITH (FUNCTION = default(0))');

INSERT INTO sys.pii_masked_columns (database_name, schema_name, table_name, column_name, masking) 
VALUES('users','source_schema','user_job', 'hire_date','MASKED WITH (FUNCTION = default())');

INSERT INTO sys.pii_masked_columns (database_name, schema_name, table_name, column_name, masking) 
VALUES('users','source_schema','user_job', 'job','MASKED WITH (FUNCTION = random(10))');

INSERT INTO sys.pii_masked_columns (database_name, schema_name, table_name, column_name, masking) 
VALUES('users','source_schema','user_job', 'email','MASKED WITH (FUNCTION = email())');

INSERT INTO sys.pii_masked_columns (database_name, schema_name, table_name, column_name, masking) 
VALUES('users','source_schema','user_job', 'optout','MASKED WITH (FUNCTION = random(2,9))');

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

INSERT INTO sys.pii_masked_columns (database_name, schema_name, table_name, column_name, masking) VALUES
('users','source_schema','ctrpersons_data_customers','phonenumber','MASKED WITH (FUNCTION = partial(0,XXXXX,4))'),
('users','source_schema','ctrpersons_data_customers','zipcode','MASKED WITH (FUNCTION = partial(0,XXXXX,8))'),
('users','source_schema','ctrpersons_data_customers','phonenumberextension','MASKED WITH (FUNCTION = partial(0,XXXXX,4))'),
('users','source_schema','ctrpersons_data_customers','emailaddress','MASKED WITH (FUNCTION = email())'),
('users','source_schema','ctrpersons_data_customers','zipcodeunknown','MASKED WITH (FUNCTION = random(2,9))'),
('users','source_schema','usps_zipcodes','zipcode','MASKED WITH (FUNCTION = partial(0,XXXXX,8))'),
('users','source_schema','usps_zipcodes','zipclassification','MASKED WITH (FUNCTION = partial(0,XXXXX,8))'),
('users','source_schema','usps_zipcodes','citystatemailingnameind','MASKED WITH (FUNCTION = email())'),
('users','source_schema','usps_zipcodes','uniquezipnameinc','MASKED WITH (FUNCTION = partial(0,XXXXX,8))');

INSERT INTO sys.pii_masked_columns (database_name, schema_name, table_name, column_name, masking) VALUES
('users','source_schema','noncustomers','zipcode','MASKED WITH (FUNCTION = partial(0,XXXXX,8))'),
('users','source_schema','noncustomers','phonenumber','MASKED WITH (FUNCTION = partial(0,XXXXX,4))'),
('users','source_schema','noncustomers','phonenumberextension','MASKED WITH (FUNCTION = partial(0,XXXXX,4))'),
('users','source_schema','noncustomers','emailaddress','MASKED WITH (FUNCTION = email())'),
('users','source_schema','noncustomers','zipcodeunknown','MASKED WITH (FUNCTION = random(2,9))'),
('users','source_schema','noncustomers','allowemails','MASKED WITH (FUNCTION = random(2,9))'),
('users','source_schema','noncustomers','ipaddress','MASKED WITH (FUNCTION = partial(0,XXXXX,8))'),
('users','source_schema','noncustomers','cellphone','MASKED WITH (FUNCTION = partial(0,XXXXX,4))'),
('users','source_schema','noncustomers','cellphoneinternationalprefix','MASKED WITH (FUNCTION = partial(0,XXXXX,4))');

INSERT INTO sys.unmasked_roles (role, database_name, schema_name, table_name) 
VALUES('admin','users','source_schema','user_location');

INSERT INTO sys.unmasked_roles (role, database_name, schema_name, table_name) 
VALUES('admin','users','source_schema','jobs');

INSERT INTO sys.unmasked_roles (role, database_name, schema_name, table_name) 
VALUES('admin','users','source_schema','admin');

INSERT INTO sys.unmasked_roles (role, database_name, schema_name, table_name) 
VALUES('staff','users','source_schema','users');

INSERT INTO sys.unmasked_roles (role, database_name, schema_name, table_name) 
VALUES('hr','users','source_schema','users');

INSERT INTO sys.unmasked_roles (role, database_name, schema_name, table_name) 
VALUES('postgres','users','source_schema','user_location');

INSERT INTO sys.unmasked_roles (role, database_name, schema_name, table_name) 
VALUES('hr','users','source_schema','usps_zipcodes');

INSERT INTO sys.unmasked_roles (role, database_name, schema_name, table_name) 
VALUES('hr','users','source_schema','ctrpersons_data_customers');

INSERT INTO sys.unmasked_roles (role, database_name, schema_name, table_name) 
VALUES('admin','users','source_schema','noncustomers');

INSERT INTO sys.unmasked_roles (role, database_name, schema_name, table_name) 
VALUES('hr','users','source_schema','user_job');

INSERT INTO sys.unmasked_roles (role, database_name, schema_name, table_name) 
VALUES('hr','users','source_schema','user_bank');

INSERT INTO sys.unmasked_roles (role, database_name, schema_name, table_name) 
VALUES('hr','users','source_schema','user_location');

-- Refresh effective roles for all tables with unmasked role entries
-- Run this on the PostgreSQL endpoint of Babelfish
-- CALL sys.RefreshEffectiveRoles('users', 'source_schema');

/*
exec sys.GenMaskingView @p_database = 'users', @p_source_schema = 'source_schema', @p_source_table= 'users', @p_view_schema = 'view_schema'

exec sys.MaskingReconciliation @p_database = 'users', @p_source_schema = 'source_schema', @p_view_schema = 'view_schema' 

use users;

SELECT USER_NAME()

select * from view_schema.ctrpersons_data_customers;
select * from view_schema.noncustomers;
select * from view_schema.usps_zipcodes;
select * from view_schema.user_bank;
select * from view_schema.user_location;
select * from view_schema.user_job;
select * from view_schema.users;
select * from view_schema.user_ssn;
select * from view_schema.admin;

SELECT name, type_desc, create_date FROM sys.server_principals WHERE type IN ('S', 'U');

CREATE LOGIN hr WITH PASSWORD = 'hr';
GO
CREATE LOGIN staff WITH PASSWORD = 'staff';
GO
CREATE LOGIN admin WITH PASSWORD = 'admin';
GO

CREATE USER hr FOR LOGIN hr;
GO
CREATE USER staff FOR LOGIN staff;
GO
CREATE USER admin FOR LOGIN admin;
GO

GRANT SELECT ON view_schema.ctrpersons_data_customers TO hr;
GO
GRANT SELECT ON view_schema.ctrpersons_data_customers TO staff;
GO
GRANT SELECT ON view_schema.ctrpersons_data_customers TO admin;
GO

GRANT SELECT ON view_schema.noncustomers TO hr;
GO
GRANT SELECT ON view_schema.noncustomers TO staff;
GO
GRANT SELECT ON view_schema.noncustomers TO admin;
GO

GRANT SELECT ON view_schema.usps_zipcodes TO hr;
GO
GRANT SELECT ON view_schema.usps_zipcodes TO staff;
GO
GRANT SELECT ON view_schema.usps_zipcodes TO admin;
GO


GRANT SELECT ON view_schema.admin TO hr;
GO
GRANT SELECT ON view_schema.admin TO staff;
GO
GRANT SELECT ON view_schema.admin TO admin;
GO


GRANT SELECT ON view_schema.user_job TO hr;
GO
GRANT SELECT ON view_schema.user_job TO staff;
GO
GRANT SELECT ON view_schema.user_job TO admin;
GO


GRANT SELECT ON view_schema.user_ssn TO hr;
GO
GRANT SELECT ON view_schema.user_ssn TO staff;
GO
GRANT SELECT ON view_schema.user_ssn TO admin;
GO


GRANT SELECT ON view_schema.user_location TO hr;
GO
GRANT SELECT ON view_schema.user_location TO staff;
GO
GRANT SELECT ON view_schema.user_location TO admin;
GO

GRANT SELECT ON view_schema.user_bank TO hr;
GO
GRANT SELECT ON view_schema.user_bank TO staff;
GO
GRANT SELECT ON view_schema.user_bank TO admin;
GO

GRANT SELECT ON view_schema.users TO hr;
GO
GRANT SELECT ON view_schema.users TO staff;
GO
GRANT SELECT ON view_schema.users TO admin;
GO

-- Now test each user

*/