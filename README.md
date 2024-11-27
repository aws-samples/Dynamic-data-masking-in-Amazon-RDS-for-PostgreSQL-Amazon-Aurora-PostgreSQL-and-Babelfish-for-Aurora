## Dynamic data masking in Amazon RDS for PostgreSQL, Amazon Aurora PostgreSQL, and Babelfish for Aurora PostgreSQL

Data obfuscation, or data anonymization refers to a collection of techniques used to disguise or alter sensitive data in order to minimizes the risk of data breaches, while still allowing legitimate access for necessary operations. This process is commonly used in industries such as financial, healthcare and government industries where confidentiality of sensitive information is important and is demanded by industry compliance standards and regulations. 

Data obfuscation techniques can vary in the level of privacy protection they offer. These techniques include:

- ***Encryption*** – [This technique](https://en.wikipedia.org/wiki/Encryption) converts data into a coded language using a mathematical algorithm, that can only be deciphered with a specific key. 
- ***Hashing*** – [This technique](https://en.wikipedia.org/wiki/Salt_\(cryptography\)) uses a unique SALTs are fed to one-way hash functions to convert data into a fixed-length code that is irreversible, making it impossible to reverse engineer the original data. 
- ***Tokenization*** -  [This technique](https://en.wikipedia.org/wiki/Tokenization_\(data_security\)) substitutes sensitive data elements with non-sensitive equivalents, referred to as a token, that have no intrinsic or exploitable meaning or value. The token is a reference that maps back to the sensitive data through a tokenization system.
- ***Data masking*** – [This technique](https://en.wikipedia.org/wiki/Data_masking) uses masking patterns to partially or completely hide the data by replacing it with fictitious or obscured data.

Although, data masking, arguably provides the most basic level of anonymization, it is a popular technique across organizations. The more popular version of the technique is dynamic data masking where the data is masked in real time and the decision on whether and whom to mask the data for is determined at query time without changing the actual data stored in the database. Many commercial database systems, such as Oracle and Microsoft SQL Server provide dynamic data masking and customers migrating from these database systems to PostgreSQL may require a similar functionality in PostgreSQL. In this post, we discuss a dynamic data masking technique based on dynamic masking views. These views mask personally identifiable information (PII) columns for unauthorized users. This post discusses how to implement this technique in RDS for PostgreSQL and Aurora PostgreSQL-compatible Edition including Babelfish for Aurora PostgreSQL. 
# **Dynamic Data Masking with Masking Views** 
This post discusses a dynamic data masking package that accepts a source table as input and generates a view which, based on the persona of the user accessing the view, masks the PII columns in the source table using the masking pattern declared for those columns. The masking view masks the PII columns for the unauthorized users. The authorized users see the data in those columns unmasked. The code for the package can be found in [AWS GitHub](https://github.com/aws-samples/Dynamic-data-masking-in-Amazon-RDS-for-PostgreSQL-Amazon-Aurora-PostgreSQL-and-Babelfish-for-Aurora).

To make the dynamic data masking package globally available, in the case of Babelfish, the package is placed in the sys schema in Babelfish\_db on the PostgreSQL endpoint of Babelfish.  To load the dynamic data masking artifacts, sign in to Babelfish using the PostgreSQL endpoint and load the script “[DDM.SQL](https://github.com/aws-samples/Dynamic-data-masking-in-Amazon-RDS-for-PostgreSQL-Amazon-Aurora-PostgreSQL-and-Babelfish-for-Aurora/blob/main/Babelfish/DDM/DDM.sql).” This script loads all the artifacts into the sys schema in this database. The sys schema is global to Babelfish and makes all these artifacts visible to all the databases on a Babelfish instance.



In the case of Aurora and Amazon RDS for PostgreSQL, the dynamic data masking package is placed in the sys schema in a given database and can be loaded using the script “[DDM.SQL](https://github.com/aws-samples/Dynamic-data-masking-in-Amazon-RDS-for-PostgreSQL-Amazon-Aurora-PostgreSQL-and-Babelfish-for-Aurora/blob/main/Postgresql/DDM/DDM.sql)”. In PostrgeSQL, databases are independent and there is no global database accessible from all other databases. One way to make the dynamic data masking package common to all the databases is to use the [template utility](https://www.postgresql.org/docs/current/manage-ag-templatedbs.html) of PostgreSQL. Note, that the template content doesn’t propagate to the existing databases.
## **Dynamic Data Masking Architecture**

The dynamic data masking technique discussed in this post has five main components

- Source tables – the tables containing PII columns
- pii\_masked\_columns table – this table lists all the PII columns in a source table, and the masking pattern to use to mask a specific PII column.
- unmasked\_roles table – this table specifies the authorized roles who can see the PII columns in a source table unmasked.
- Masking artifacts – a set of functions and procedures used to generate masking views and apply masking patterns.
- Masking views – the views that mask PII columns for unauthorized users, using the declared masking pattern


` `The following diagram shows the end-to-end process for enforcing dynamic data masking using masking views. 

![image](https://github.com/user-attachments/assets/cb825e28-595d-47f0-8bcc-e8795c881225)


To implement this workflow

1. Declare the masking patterns for the PII columns in each table
1. Declare the unmasked roles; users with these roles are authorized to see the unmasked data in a source table.
1. Execute the procedure GenMaskingView and accompanying functions to generate masking views.
1. Grant permission to users to use the masking views. You can revoke permissions from the source tables, as needed.
1. Use the masking views; these views check the user roles, and if unauthorized, apply the declared the masking pattern to the PII columns using the masking functions defined in the dynamic data masking package.



Note that the dynamic data masking package presented here assumes that the source table and the masking views are located in separate database schemas. This is because the masking views and the source table have the same name.
## **Dynamic Data Masking Patterns**

The dynamic data masking package allows for the following masking patterns. A masking pattern is a function that masks the data in a PII column based on some regular expression pattern. The following table lists the available masking patterns.
**


|<br>**Masking Pattern**|<br>**Column data type**|<br>**Making pattern example**|<br>**Example input column**|<br>**Output**|
| :- | :- | :- | :- | :- |
|<br>default()|<br>Text|<br>MASKED WITH (FUNCTION = default())|<br>admin|<br>X|
|<br>default()|<br>Number|<br>MASKED WITH (FUNCTION = default())|100|0|
|<br>partial(n, xxxxx, m)|<br>Text|<br>MASKED WITH (FUNCTION = partial(0, xxxxx, 8)|<br>chase|<br>xxxxxxxx|
|<br>email()|<br>Text|<br>MASKED WITH (FUNCTION=email())|<br><john@efgh.biz>|<br>[joXXXXXXXX.net](http://joXXXXXXXX.net)|
|<br>random(n, 1m)|<br>Number|<br>MASKED WITH (FUNCTION = random(1, 100))|7102933|15|


The table pii\_masked\_columns keeps track of the masking pattern for each PII column in a specific source table. This table has the following layout

- Database\_name – Name of the database where the source table is located
- Schema\_name – Name of the schema where the source table is located
- Table\_name – Name of the source table
- Column\_name – Name of the pii column
- Masking pattern – The pattern to obfuscate the data



Examples of the entries in the pii\_masked\_columns table are:

|<br>**Database\_name**|<br>**Schema\_name**|<br>**Table\_name**|<br>**Column\_name**|<br>**Masking**|
| :- | :- | :- | :- | :- |
|<br>Users|<br>source\_schema|<br>user\_job|<br>title|<br>MASKED WITH (FUNCTION = default())|
|<br>Users|<br>source\_schema|<br>user\_job|<br>job|<br>MASKED WITH (FUNCTION = default())|
|<br>Users|<br>source\_schema|<br>user\_job|<br>email|<br>MASKED WITH (FUNCTION = email())|
|<br>Users|<br>source\_schema|<br>user\_bank|<br>bank\_name|<br>MASKED WITH (FUNCTION = partial(0,XXXXXXXX, 5))|
|<br>Users|<br>source\_schema|<br>user\_bank|<br>account\_id|<br>MASKED WITH (FUNCTION = random(1, 100))|
|<br>Users|<br>source\_schema|<br>user\_bank|<br>balance|<br>MASKED WITH (FUNCTION = random(100,500))|

` `**Authorized users**


Authorized users, those who can see the PII data unmasked, are defined using the unmasked\_roles table. The table has the following layout:

- Role  --  Role of the user who is authorized to see the data unmasked
- Database\_name – Name of the database where the source table is located
- Schema\_name – Name of the schema where the source table is located
- Table\_name – Name of the source table



Examples of the entries in the table are:



|<br>**Role**|<br>**Database\_name**|<br>**Schema\_name**|<br>**Table\_name**|
| :- | :- | :- | :- |
|admin|Users|source\_schema|user\_location|
|admin|Users|source\_schema|job|
|staff|Users |source\_schema|users|
|Hr|Users|source\_schema|users|
|postgres|Users|source\_schema|user\_location|
|Hr|Users|source\_schema|user\_job|
|Hr|Users|source\_schema|user\_bank|
|Hr|Users|source\_schema|user\_location|

## **Dynamic Data masking views**

The masking procedure GenMaskingView  is used to generate the masking view for a specific table. In this post, we provide the syntax for using the procedure in RDS for PostgreSQL and Aurora PostgreSQL-compatible Edition including Babelfish for Aurora PostgreSQL. 



**PostgreSQL:**

call sys.GenMaskingView (<database>, <source\_schema>, <source\_table>, <view\_schema>);



**Example :**



call sys.GenMaskingView ( 'users', 'source\_schema',  'users',  'view\_schema')



This call generates the following SQL statement that creates a masking view.



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
**


*Note that in this technique the masking views check the authorization based on the CURRENT\_ROLE (i.e. the role in which the view is executing). This implies that a user may have a different authorization pattern based on the role the user has in the current execution context.*

**Babelfish (TSQL endpoint):**

exec sys.GenMaskingView @p\_database = <database>, @p\_source\_schema = <source\_schema>, @p\_source\_table= <source\_table>, @p\_view\_schema = <view\_schema>

**Example:**



exec sys.GenMaskingView @p\_database = 'users', @p\_source\_schema = 'source\_schema', @p\_source\_table= 'users', @p\_view\_schema = 'view\_schema'



This statement generates the following SQL statement that creates a masking view.



CREATE VIEW view\_schema.user\_bank AS  

WITH t AS 

(SELECT COUNT(\*) as cnt from sys.unmasked\_roles  

WHERE table\_name = 'user\_bank' 

AND schema\_name = 'source\_schema' 

AND database\_name ='users' 

AND role = **ORIGINAL\_LOGIN())**) 
**
` `SELECT bank\_id, user\_id, 

CASE WHEN cnt = 1 THEN bank\_name ELSE sys.partial(bank\_name,0,'xxxxxxxx',5) END AS bank\_name,  CASE WHEN cnt = 1 THEN account\_id ELSE sys.random\_num(1,100) END AS account\_id, 

CASE WHEN cnt = 1 THEN balance ELSE sys.random\_num(100,500) END AS balance 

FROM source\_schema.user\_bank, t
**


If the definition for the underlying source table changes, the masking view nust be regenerated. Additionally, the unmasked\_roles and pii\_masked\_columns tables must reflect the changes in the source tables before the masking views are generated. 

When dealing with many tables, it can become cumbersome to keep track of the tables whose definition has changed. You can use the procedure **MaskingReconciliation** to generate dynamic data masking views for all the tables in a schema. 
**


**PostgreSQL:**

call sys.MaskingReconciliation  (<database>, <source\_schema>, <view\_schema>);

**Babelfish (TSQL endpoint):**

exec sys.MaskingReconciliation @p\_database = <database>, @p\_source\_schema = <source\_schema>, @p\_view\_schema = <view\_schema> 
## **Using masking views**

After users are given permissions to access dynamic data masking views, they can view the data in source table by selecting from these views. An unauthorized user sees the PII columns masked while an authorized sees them unmasked. For example, an unauthorized user sees the following entries in the user\_bank source bank when selecting from user\_bank  view. 



**select** \* **from**  ***view\_schema.user\_bank***

|bank\_id|user\_id|bank\_name|account\_id|balance|
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

|bank\_id|user\_id|bank\_name|account\_id|balance|
| :- | :- | :- | :- | :- |
|1|1|bank1|7,102,933|500,000|
|2|1|bank\_in\_congress|8,100,033|100,000|
|3|2|southern bank|1,111,133|200,000|
|4|2|bank4|8,188,833|90,000|
|5|3|southern bank|333,333|700,000|
|6|4|bank1|19,019,292|15,000|
|7|5|bank5|11,111,111|60,000|
|8|6|Bank\_in\_congress|222,222|3,000|
|9|7|bank1|887,603|650,000|
##
## **Cleanup**
If you decide that you no longer need the setup presented in this post, make sure to delete the setup and all the associated resources to avoid being charged in the future. The steps to delete the resources are

- **Sign in to the AWS Management Console and open the Amazon RDS console.**
- In the navigation pane, choose Databases, and then choose the DB instance that you want to delete.
- For Actions, choose Delete.
- Enter delete me in the box.
- Choose Delete.
  
## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

