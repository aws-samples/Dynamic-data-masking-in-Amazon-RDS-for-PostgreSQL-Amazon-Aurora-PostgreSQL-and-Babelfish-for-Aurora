# **Dynamic data masking in Amazon RDS for PostgreSQL, Amazon Aurora PostgreSQL, and Babelfish for Aurora PostgreSQL**
Data obfuscation, or data anonymization, refers to a collection of techniques used to disguise or alter sensitive data to minimize the risk of data breaches, while still allowing legitimate access for necessary operations. This process is commonly used in industries such as financial, healthcare, and government industries, where confidentiality of sensitive information is important and demanded by industry compliance standards and regulations. 

Data obfuscation techniques can vary in the level of privacy protection they offer. These techniques include:

- **Encryption** – [This technique](https://en.wikipedia.org/wiki/Encryption) converts data into a coded language using a mathematical algorithm, which can only be deciphered with a specific key. 
- **Hashing** – [This technique](https://en.wikipedia.org/wiki/Salt_\(cryptography\)) uses unique SALTs fed to one-way hash functions to convert data into a fixed-length code that is irreversible, making it impossible to reverse engineer the original data. 
- **Tokenization** - [This technique](https://en.wikipedia.org/wiki/Tokenization_\(data_security\)) substitutes sensitive data elements with non-sensitive equivalents, referred to as a token, that have no intrinsic or exploitable meaning or value. The token is a reference that maps back to the sensitive data through a tokenization system.
- **Data masking** – [This technique](https://en.wikipedia.org/wiki/Data_masking) uses masking patterns to partially or completely hide the data by replacing it with fictitious or obscured data.

There are a variety of different techniques available to support data masking in databases, each with their trade-offs. In this post, we explore dynamic data masking, a technique that returns anonymized data from a query without modifying the underlying data.

Many commercial database systems, such as Oracle and Microsoft SQL Server, provide dynamic data masking, and customers migrating from these database systems to PostgreSQL might require a similar functionality in PostgreSQL. This repo provides a dynamic data masking technique based on dynamic masking views. These views mask personally identifiable information (PII) columns for unauthorized users. In this page, we discuss how to implement this technique in [Amazon Relational Database Service (Amazon RDS) for PostgreSQ](https://aws.amazon.com/rds/postgresql/)L and [Amazon Aurora PostgreSQL-Compatible Edition](https://aws.amazon.com/rds/aurora/postgresql-features/) including [Babelfish for Aurora PostgreSQL](https://aws.amazon.com/rds/aurora/babelfish/). In the last section, we discuss the limitations of dynamic data masking techniques.

## **Dynamic data masking with masking views** 
The dynamic data masking (PGDDM) package provided in this repo accepts a source table as input and generates a view which, based on the persona of the user accessing the view, masks the PII columns in the source table using the masking pattern declared for those columns. The masking view masks the PII columns for the unauthorized users. The authorized users see the data in those columns unmasked. 

To make the PGDDM package globally available, in the case of Babelfish, place the package in the `sys` schema in `Babelfish_db` on the PostgreSQL endpoint of Babelfish. To load the PGDDM artifacts, sign in to Babelfish using the PostgreSQL endpoint and load the script [PGDDM.SQL](https://github.com/aws-samples/Dynamic-data-masking-in-Amazon-RDS-for-PostgreSQL-Amazon-Aurora-PostgreSQL-and-Babelfish-for-Aurora/blob/d480b3e62e539c4bac58c8d39e557e70c3a2aa28/Babelfish/PGDDM/PGDDM.sql). This script loads all the artifacts into the `sys` schema in this database. The `sys` schema is global to Babelfish and makes all these artifacts visible to all the databases on a Babelfish instance.

In the case of Aurora PostgreSQL-Compatible and Amazon RDS for PostgreSQL, place the PGDDM package in the `sys` schema in a given database. To load the content, use the script [PGDDM.SQL](https://github.com/aws-samples/Dynamic-data-masking-in-Amazon-RDS-for-PostgreSQL-Amazon-Aurora-PostgreSQL-and-Babelfish-for-Aurora/blob/fd1666e50d6ca1ea8eff76ca6f92f0671c97bcca/Postgresql/PGDDM/PGDDM.sql). A database in PostgreSQL is independent, so to make the

PGDDM package common to all the databases, you can use [template databases](https://www.postgresql.org/docs/current/manage-ag-templatedbs.html) to automatically install the package in new databases. The template content doesn’t propagate to the existing databases.

## **Solution overview**
PGDDM has five main components:

- **Source tables** – The tables containing PII columns
- **Pii\_masked\_columns table** – A table that lists all the PII columns in a source table, and the masking pattern to use to mask a specific PII column
- **Unmasked\_roles table** – A table that specifies the authorized roles who can see the PII columns in a source table unmasked
- **Masking artifacts** – A set of functions and procedures used to generate masking views and apply masking patterns
- **Masking views** – The views that mask PII columns for unauthorized users, using the declared masking pattern

The following diagram shows the end-to-end process for enforcing dynamic data masking using masking views. 

<img width="468" alt="image" src="https://github.com/user-attachments/assets/e0d230b1-cb28-4568-b964-90521f259ec9" />
 

To implement this workflow, complete the following steps:

1. Declare the masking patterns for the PII columns in each table.
1. Declare the unmasked roles; users with these roles are authorized to see the unmasked data in a source table.
1. Run the procedure `GenMaskingView` and accompanying functions to generate masking views.
1. Grant permission to users to use the masking views. You can revoke permissions from the source tables as needed.
1. Use the masking views. These views check the user roles, and if unauthorized, apply the declared the masking pattern to the PII columns using the masking functions defined in the dynamic data masking package.

PGDDM assumes that the source table and the masking views are located in separate database schemas. This is because the masking views and the source table have the same name.

## **Masking functions in PGDDM**
The PGDDM package allows for the following masking patterns. A masking pattern is a function that masks the data in a PII column based on a regular expression pattern. The following table lists the available masking patterns.



|**Masking Pattern**|**Column data type**|**Making pattern example**|**Example input column**|**Output**|
| :- | :- | :- | :- | :- |
|`default()`|Text|`MASKED WITH (FUNCTION = default())`|`admin`|X|
|`default()`|Number|`MASKED WITH (FUNCTION = default())`|`100`|`0`|
|`partial(n, xxxxx, m)`|Text|`MASKED WITH (FUNCTION = partial(0, xxxxx, 8)`|`admin`|`xxxxxxxx`|
|`email()`|Text|`MASKED WITH (FUNCTION=email())`|`john@efgh.biz`|`joXXXXXXXX.biz`|
|`random(n, 1m)`|Number|`MASKED WITH (FUNCTION = random(1, 100))`|`7102933`|`15`|

The table `pii_masked_columns` keeps track of the masking pattern for each PII column in a specific source table. This table has the following layout:

- **Database\_name** – Name of the database where the source table is located
- **Schema\_name** – Name of the schema where the source table is located
- **Table\_name** – Name of the source table
- **Column\_name** – Name of the PII column
- **Masking** – Pattern to obfuscate the data

The following table lists examples of the entries in the `pii_masked_columns` table.

|**database\_name**|**schema\_name**|**table\_name**|**column\_name**|**masking**|
| :- | :- | :- | :- | :- |
|`users`|`source_schema`|`user_job`|`title`|`MASKED WITH (FUNCTION = default())`|
|`users`|`source_schema`|`user_job`|`job`|`MASKED WITH (FUNCTION = default())`|
|`users`|`source_schema`|`user_job`|`email`|`MASKED WITH (FUNCTION = email())`|
|`users`|`source_schema`|`user_bank`|`bank_name`|`MASKED WITH (FUNCTION = partial(0,XXXXXXXX, 5))`|
|`users`|`source_schema`|`user_bank`|`account_id`|`MASKED WITH (FUNCTION = random(1, 100))`|
|`users`|`source_schema`|`user_bank`|`balance`|`MASKED WITH (FUNCTION = random(100,500))`|

## **Setting up authorized users for viewing unmasked data**
Authorized users (those who can see the PII data unmasked) are defined using the `unmasked_roles` table. The table has the following layout:

- **Role** – Role of the user who is authorized to see the data unmasked
- **Database\_name** – Name of the database where the source table is located
- **Schema\_name** – Name of the schema where the source table is located
- **Table\_name** – Name of the source table

The following table lists examples of the entries in the `unmasked_roles` table.

|**role**|**database\_name**|**schema\_name**|**table\_name**|
| :- | :- | :- | :- |
|`admin`|`users`|`source_schema`|`user_location`|
|`admin`|`users`|`source_schema`|`job`|
|`staff`|`users`|`source_schema`|`users`|
|`hr`|`users`|`source_schema`|`users`|
|`postgres`|`users`|`source_schema`|`user_location`|
|`hr`|`users`|`source_schema`|`user_job`|
|`hr`|`users`|`source_schema`|`user_bank`|
|`hr`|`users`|`source_schema`|`user_location`|

## **Build dynamic data masking views**
The masking procedure `GenMaskingView` is used to generate the masking view for a specific table. 

The following is the syntax for using the procedure in Amazon RDS for PostgreSQL and Aurora PostgreSQL-Compatible:

CALL sys.GenMaskingView (*<database>*, *<source\_schema>*, *<source\_table>*, *<view\_schema>*);

For example:

CALL sys.GenMaskingView ( 'users', 'source\_schema',  'users',  'view\_schema')

This call generates the following SQL statement that creates a masking view:

CREATE VIEW view\_schema.user\_bank AS  

WITH t AS 

(SELECT COUNT(\*) as cnt from sys.unmasked\_roles  

WHERE table\_name = 'user\_bank' 

AND schema\_name = 'source\_schema' 

AND database\_name ='users' 

AND role = CURRENT\_ROLE) 

SELECT bank\_id, user\_id, 

CASE WHEN cnt = 1 THEN bank\_name ELSE sys.partial(bank\_name,0,'xxxxxxxx',5) END AS bank\_name,  CASE WHEN cnt = 1 THEN account\_id ELSE sys.random\_num(1,100) END AS account\_id, 

CASE WHEN cnt = 1 THEN balance ELSE sys.random\_num(100,500) END AS balance 

FROM source\_schema.user\_bank, t

In this technique, the masking view checks the authorization based on the `CURRENT_ROLE` (the role in which the view is executing). This implies that a user may have a different authorization pattern based on the role the user has in the current execution context.

The following is the syntax for using the procedure in Babelfish for Aurora PostgreSQL (TSQL endpoint):

EXEC sys.GenMaskingView @p\_database = *<database>*, @p\_source\_schema = *<source\_schema>*, @p\_source\_table= *<source\_table>*, @p\_view\_schema = *<view\_schema>*

For example:



EXEC sys.GenMaskingView @p\_database = 'users', @p\_source\_schema = 'source\_schema', @p\_source\_table= 'users', @p\_view\_schema = 'view\_schema'



This statement generates the following SQL statement that creates a masking view:



CREATE VIEW view\_schema.user\_bank AS  

WITH t AS 

(SELECT COUNT(\*) as cnt from sys.unmasked\_roles  

WHERE table\_name = 'user\_bank' 

AND schema\_name = 'source\_schema' 

AND database\_name ='users' 

AND role = ORIGINAL\_LOGIN())) 
**
` `SELECT bank\_id, user\_id, 

CASE WHEN cnt = 1 THEN bank\_name ELSE sys.partial(bank\_name,0,'xxxxxxxx',5) END AS bank\_name,  CASE WHEN cnt = 1 THEN account\_id ELSE sys.random\_num(1,100) END AS account\_id, 

CASE WHEN cnt = 1 THEN balance ELSE sys.random\_num(100,500) END AS balance 

FROM source\_schema.user\_bank, t



If the definition for the underlying source table changes, the masking view must be regenerated. Additionally, the `unmasked_roles` and `pii_masked_columns` tables must reflect the changes in the source tables before the masking views are generated. 

When dealing with many tables, it can become cumbersome to keep track of the tables whose definition has changed. You can use the procedure** `MaskingReconciliation`** to generate dynamic data masking views for all the tables in a schema. 



The following is the syntax for Amazon RDS for PostgreSQL and Aurora PostgreSQL-Compatible:

CALL sys.MaskingReconciliation  (*<database>*, *<source\_schema>*, *<view\_schema>*);

The following is the syntax for Babelfish for Aurora PostgreSQL (TSQL endpoint):

EXEC sys.MaskingReconciliation @p\_database = *<database>*, @p\_source\_schema = *<source\_schema>*, @p\_view\_schema = *<view\_schema>* 

## **Query dynamic masking views**
After users are given permissions to access dynamic data masking views, they can view the data in the source table by selecting from these views. An unauthorized user sees the PII columns masked, whereas an authorized sees them unmasked. For example, an unauthorized user sees the following entries in the `user_bank` source bank when selecting from the `user_bank` view. 



SELECT \* FROM  view\_schema.user\_bank

|**bank\_id**|**user\_id**|**bank\_name**|**account\_id**|**balance**|
| :- | :- | :- | :- | :- |
|1|1|xxxxxxxx|75|300|
|2|1|bankxxxxxxxxress|19|379|
|3|2|xxxxxxxx bank|56|401|
|4|2|xxxxxxxx|20|222|
|5|3|xxxxxxxx bank|45|283|
|6|4|xxxxxxxx|20|295|
|7|5|xxxxxxxx|80|195|
|8|6|bankxxxxxxxxress|23|361|
|9|7|xxxxxxxx|20|284|

An authorized user using the same view will see the PII data unmasked.

|**bank\_id**|**user\_id**|**bank\_name**|**account\_id**|**balance**|
| :- | :- | :- | :- | :- |
|1|1|bank1|7,102,933|500,000|
|2|1|bank\_in\_congress|8,100,033|100,000|
|3|2|southern bank|1,111,133|200,000|
|4|2|bank4|8,188,833|90,000|
|5|3|southern bank|3,333,333|700,000|
|6|4|bank1|9,019,292|15,000|
|7|5|bank5|1,111,111|60,000|
|8|6|Bank\_in\_congress|2,222,222|3,000|
|9|7|bank1|8,887,603|650,000|

## **Limitations of dynamic data masking** 
Although dynamic data masking can often be simpler to get started with, it has several limitations that you must be aware of:

- **Read-only nature** – Dynamically masked data can’t be written back to the database, and it’s not suitable for development and testing environments where data needs to be modified
- **Performance impact** – The dynamic, real-time masking process can introduce additional processing overhead, and potentially impact query performance
- **Complex configuration** – Setting up masking rules with granular access controls or queries that require federation to remote systems can be complex and require careful management
- **Potential for bypass** – The dynamic masking process can potentially be bypassed through various methods, including advanced SQL queries, privilege escalation, and brute-force techniques
- **Inference vulnerabilities** – Although masking hides sensitive data, a user with access to masked data might still be able to infer sensitive information through pattern analysis

## **Clean up**
If you no longer need the setup presented in this post, make sure to all the associated resources to avoid being charged in the future:

1. On the Amazon RDS console, choose **Databases** in the navigation pane.
1. Select the DB instance you want to delete, and on the **Actions** menu, choose **Delete**.
1. Enter `delete me` to confirm and choose **Delete**.

