DROP SCHEMA IF EXISTS sys CASCADE;
CREATE SCHEMA sys;

CREATE OR REPLACE FUNCTION sys.fun_now() 
RETURNS TEXT
AS $$ 
	BEGIN 
		RETURN CAST(NOW() AS TEXT); 
	END; 
$$ 
LANGUAGE plpgsql
immutable;

CREATE OR REPLACE FUNCTION update_modified_timestamp() 
        RETURNS TRIGGER AS $$
			BEGIN
			NEW.modified_timestamp := sys.fun_now();
			RETURN NEW;
			END;
			$$
LANGUAGE plpgsql;

DO $$                  
    BEGIN 
		IF EXISTS (SELECT * FROM pg_catalog.pg_tables 
			 WHERE schemaname = 'sys' AND tablename = 'pii_masked_columns')
			 THEN
				 BEGIN
					DROP TABLE sys.pii_masked_columns CASCADE;
				 END;
		END IF;
	
		CREATE TABLE IF NOT EXISTS sys.pii_masked_columns(
			database_name TEXT, 
			schema_name TEXT, 
			table_name TEXT, 
			column_name TEXT, 
			masking TEXT,
			create_timestamp TEXT DEFAULT sys.fun_now(), 
			modified_timestamp TEXT DEFAULT sys.fun_now(), 
			PRIMARY KEY (database_name, schema_name, table_name, column_name));

		CREATE TRIGGER update_pii_masked_columns
		BEFORE UPDATE ON sys.pii_masked_columns
		FOR EACH ROW
            EXECUTE FUNCTION update_modified_timestamp();
	END;
$$
LANGUAGE plpgsql;

DO $$                  
    BEGIN 
		IF EXISTS (SELECT * FROM pg_catalog.pg_tables 
			 WHERE schemaname = 'sys' AND tablename = 'unmasked_roles')
			 THEN
				 BEGIN
					DROP TABLE sys.unmasked_roles CASCADE;
				 END;
		END IF;
	
		CREATE TABLE IF NOT EXISTS sys.unmasked_roles(
			role TEXT,
			database_name TEXT, 
			schema_name TEXT, 
			table_name TEXT,
			create_timestamp TEXT DEFAULT sys.fun_now(), 
			modified_timestamp TEXT DEFAULT sys.fun_now(), 
			PRIMARY KEY (role, database_name, schema_name, table_name));

		CREATE TRIGGER update_unmasked_roles
		BEFORE UPDATE ON sys.unmasked_roles
		FOR EACH ROW
            EXECUTE FUNCTION update_modified_timestamp();
	END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.num(p_datatype TEXT)
				RETURNS SMALLINT 
AS $$
BEGIN
		IF LOWER(p_datatype) in ('int','integer','bigint','decimal','numeric','money', 'real',
						'double precision','smallint', 'serial')
				 THEN RETURN 1;
		END IF;
      
		RETURN 0;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.string(p_datatype TEXT)
	RETURNS SMALLINT
AS $$
BEGIN
	 IF LOWER(p_datatype) in ('char','varchar','character','character varying', 'text') 
		THEN RETURN 1;
	 END IF;
	
	 RETURN 0;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.dat(p_datatype TEXT)
	RETURNS SMALLINT
AS $$
BEGIN
	 IF LOWER(p_datatype) in ('date', 'timestamp', 'time')
	 	THEN RETURN 1;
	 END IF;
	
	 RETURN 0;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.MaskingString (p_mask TEXT, p_column TEXT, p_datatype TEXT)
	RETURNS  TEXT
AS $$
DECLARE v_str TEXT = LOWER(REPLACE(p_mask,' ',''));
DECLARE v_l1  INT = LENGTH(v_str);
DECLARE v_pos INT;
DECLARE v_l2  INT;
DECLARE v_start  INT;
DECLARE v_end  INT;
DECLARE v_func_string TEXT;
DECLARE v_args TEXT;
DECLARE v_len  INT;
DECLARE v_cnt  INT;
DECLARE v_func TEXT;	
DECLARE v_tab TEXT[];
DECLARE v_masked_string TEXT = '';
DECLARE v_padding TEXT;

BEGIN
		IF  p_mask = '' THEN RETURN  ''; END IF;
	   
		IF POSITION('maskedwith(function=' IN v_str) = 0 THEN RAISE EXCEPTION 'Invalid Masking String: %', p_mask; END IF;
	    
		v_pos = POSITION('=' IN v_str) + 1;
		v_l2 =  v_l1 - v_pos ;
	    v_func_string = SUBSTRING(v_str, v_pos, v_l2);
	    v_len  =  POSITION('(' IN v_func_string) - 1;
	    v_func = SUBSTRING(v_func_string, 1, v_len);
	   
		IF v_func NOT IN('partial', 'default', 'random', 'email') THEN RAISE EXCEPTION 'Invalid Masking String: %', p_mask; END IF;
	
		v_args = SUBSTRING(v_func_string, v_len + 2, LENGTH(v_func_string) - v_len - 2);
	
	    IF v_args = '' THEN v_str = v_func; 
	     ELSE v_str =  v_func || ',' || v_args;
	    END IF;
	
		v_tab = string_to_array(v_str, ',');
  		
  		v_cnt = array_length(v_tab, 1);
  	
  		v_func = v_tab[1];
  	
  		IF ((v_func = 'default' OR v_func = 'email') AND v_cnt != 1 ) OR
		    (v_func = 'partial' AND v_cnt != 4 ) OR
		    (v_func = 'random' AND v_cnt != 3 )
		    THEN RAISE EXCEPTION 'Invalid function format: %', mask;
	    END IF;
		  	
		IF(v_func = 'default') THEN
		  		 IF sys.num(p_datatype) = 1 THEN v_func = 'default_num';	   					
			  		ELSE IF sys.string(p_datatype) = 1 THEN v_func = 'default_string';
			  			  ELSE IF sys.dat(p_datatype) = 1 THEN v_func = 'default_date';
			  			   		 ELSE
				  			   		RAISE EXCEPTION 'Wrong Data Type for DDM function default: Column % with data type %.', p_column, p_datatype; 
			  			   	   END IF;
			  			 END IF;	
			    END IF;
			    RETURN 'sys.' || v_func || '() ';
		END IF;
		
		IF(v_func = 'email') THEN
		  	IF sys.string(p_datatype) != 1 	THEN				
			  			RAISE EXCEPTION 'Wrong Data Type for DDM function email: Column % with data type %.', p_column, p_datatype;
		  	END IF; 
		  	RETURN 'sys.' || v_func || '(' || p_column || ')';				
		END IF;
		
		IF(v_func = 'random') THEN
		  		IF sys.num(p_datatype) = 1 THEN 
		  			v_func = 'random_num';
			  		v_start = v_tab[2];
			  		v_end = v_tab[3];
			  		RETURN 'sys.' || v_func || '(' || v_start || ',' || v_end || ')';
			  		ELSE 
			  			RAISE EXCEPTION 'Wrong Data Type for DDM function random: Column % with data type %.', p_column, p_datatype;
		  		END IF;	 
		END IF;
	
		IF(v_func = 'partial') THEN
		  		IF sys.string(p_datatype) = 1 THEN 
		  			v_start = v_tab[2];
		  			v_padding = v_tab[3];
		  			v_end = v_tab[4];				
		  			RETURN  'sys.' || v_func || '(' || p_column || ',' || v_start || ',' || '''' || v_padding || '''' || ',' || v_end || ')';	
			  	ELSE 
		  			RAISE EXCEPTION 'Wrong Data Type for DDM function partial: Column % with data type %.', p_column, p_datatype;
		  		END IF;
		END IF;

	END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.email(p_email TEXT)
RETURNS TEXT
AS $$
BEGIN

	    RETURN  REGEXP_REPLACE(p_email, '([a-zA-Z0-9]{0,1})[a-zA-Z0-9_\-\.]@+([a-zA-Z0-9_\-]+\.)+(com|org|edu|nz|au|net|gov|biz)', '\1XXXXXXXX.\3');
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.partial(p_column TEXT, p_start  INT,p_padding TEXT, p_end INT)
RETURNS TEXT
AS $$
DECLARE v_l1 INT = LENGTH(p_column);
DECLARE	v_l2  INT = LENGTH(p_column) - LENGTH(p_padding);
	BEGIN 	
		IF (v_l2 <= 0) OR (p_start = 0 and p_end = 0) THEN RETURN p_padding; END IF;
		IF (p_end + p_start) < v_l2 THEN
	 		p_start = v_l2/2;
	 	    p_end= v_l2/2;
	    END IF;
	    RETURN  SUBSTRING(p_column, 1, p_start) || p_padding || SUBSTRING(p_column, v_l1 - p_end + 1, p_end) ;   
	END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.default_string()
RETURNS TEXT
AS $$
BEGIN  	
	 
	    RETURN 'X';
	   
END;
$$
LANGUAGE plpgsql;

CREATE  OR REPLACE FUNCTION sys.default_num()
RETURNS NUMERIC
AS $$
BEGIN  
	
	RETURN  0;
	   
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sys.default_date()
RETURNS TEXT
AS $$
BEGIN  
	
	RETURN  '1900-01-01 00:00:00.00000000';
	   
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sys.random_string(p_column TEXT)
RETURNS TEXT
AS $$
BEGIN
  RETURN REPEAT(string_agg (SUBSTR('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', ceil (random() * 62), 1), ''),LENGTH(p_column));
END;
$$
LANGUAGE plpgsql;

CREATE  OR REPLACE FUNCTION sys.random_num(p_low INT , p_high INT) 
   RETURNS INT 
AS $$
BEGIN
   RETURN FLOOR(RANDOM()* (p_high - p_low + 1) + p_low);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE sys.GenMaskingView
(p_database TEXT, 
 p_source_schema TEXT, 
 p_source_table TEXT,
 p_view_schema TEXT
)
AS $$ 
DECLARE v_source_table TEXT = LOWER(p_source_table);
DECLARE v_database TEXT = LOWER(p_database);
DECLARE v_source_schema TEXT = LOWER(p_source_schema);
DECLARE v_view_schema TEXT = LOWER(p_view_schema);
DECLARE v_masking TEXT;
DECLARE v_unmasked_roles TEXT = '';
DECLARE v_unmasked_masked_columns TEXT = '';
DECLARE v_unmasked_columns TEXT = '';
DECLARE v_masked_columns TEXT = '';
DECLARE v_mstring TEXT = '';
DECLARE v_with_clause TEXT = '';
DECLARE v_column TEXT;
DECLARE v_columns TEXT;
DECLARE v_datatype TEXT;
DECLARE v_masked_string TEXT;
DECLARE v_out TEXT;
DECLARE v_func TEXT;
DECLARE v_tab TEXT;
DECLARE v_cnt smallint = 0;
DECLARE v_padding TEXT;
DECLARE v_start TEXT;
DECLARE v_end TEXT;
DECLARE v_sql TEXT;
DECLARE v_usql TEXT;
DECLARE v_dsql TEXT;

DECLARE v_recCursor CURSOR FOR
			WITH t AS (SELECT c.column_name, c.data_type  AS datatype 
				      FROM  INFORMATION_SCHEMA.columns c
				      WHERE LOWER(c.table_name) = v_source_table
				      AND   LOWER(c.table_schema) = v_source_schema 
				      AND   LOWER(c.table_catalog) =  v_database
				     )
			 SELECT t.column_name, t.datatype, m.masking FROM t INNER JOIN sys.pii_masked_columns m ON m.column_name = t.column_name 
             WHERE LOWER(m.table_name) = v_source_table AND LOWER(m.schema_name) = v_source_schema and LOWER(m.database_name) = v_database
                    UNION all
             SELECT t.column_name, t.datatype,'' FROM t WHERE t.column_name NOT IN 
            (SELECT column_name FROM sys.pii_masked_columns m WHERE LOWER(m.table_name) = v_source_table AND LOWER(m.schema_name) = v_source_schema and LOWER(m.database_name) = v_database)
      		FOR READ ONLY;
BEGIN
		IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_database  WHERE LOWER(datname) = v_database )
			THEN RAISE EXCEPTION 'Source table database % does not exist.', p_database;
	    END IF;

	    IF NOT EXISTS (SELECT 1 from INFORMATION_SCHEMA.schemata
 						WHERE LOWER(schema_name) = v_view_schema
 						AND   LOWER(catalog_name) = v_database)
	  		THEN RAISE EXCEPTION 'Schema % does not exist.', p_view_schema;
	  	END IF;
	  		
      	IF v_source_schema = v_view_schema 
				THEN RAISE EXCEPTION 'Source table cannot be in the same schema as the view schema %.', p_source_schema;
	    END IF;
			
		IF NOT EXISTS (SELECT 1 FROM PG_TABLES WHERE LOWER(schemaname) = v_source_schema and tablename = v_source_table) 
			THEN RAISE EXCEPTION 'Source table % does not exist in schema %.', p_source_table, p_source_schema;
	    END IF;

		IF  current_database() != v_database
			THEN RAISE EXCEPTION 'Current database is not %.', p_database;
	    END IF;
	        
        OPEN v_recCursor;
		
        LOOP
			FETCH NEXT FROM v_recCursor INTO v_column, v_datatype, v_masking;
			EXIT WHEN NOT FOUND;
		  			v_tab = '{}';
		  			v_func = '';
		  			v_out = '';
		  		    v_masked_string = '';
					
	  			    IF v_masking = ''
	  			    	THEN
		  			    	  IF v_unmasked_columns = '' 
			  			     	 THEN v_unmasked_columns = v_column;
			  			      	 ELSE v_unmasked_columns = v_unmasked_columns || ', ' || v_column;
		  			   		  END IF;
		  			ELSE
			  			v_masked_string = sys.MaskingString(v_masking, v_column, v_datatype);
			  		    v_mstring = ' CASE WHEN cnt = 1 THEN ' || v_column || ' ELSE ' || v_masked_string || ' END AS ' || v_column;
					 	IF v_masked_columns = '' 
				  			      THEN v_masked_columns = v_mstring;
				  			      ELSE v_masked_columns = v_masked_columns || ', ' || v_mstring;
						END IF;

  	   				END IF;
  		END LOOP;
  		
		CLOSE v_recCursor;   
	

  	    IF v_unmasked_columns = '' THEN v_columns = v_masked_columns;
  	       ELSE IF v_masked_columns = '' THEN v_columns = v_unmasked_columns;
  	            ELSE v_columns = v_unmasked_columns || ',' || v_masked_columns;
  	            END IF;
  	    END IF;
       
	    v_with_clause = ' WITH t AS (SELECT COUNT(*) as cnt from sys.unmasked_roles ' ||
  	   					' WHERE table_name = ' || '''' || v_source_table || '''' ||
 	   					' AND schema_name = ' || '''' || v_source_schema || '''' ||
       					' AND database_name =' || '''' || v_database || '''' ||
       					' AND role = CURRENT_ROLE)';

		v_sql =  'CREATE VIEW ' || p_view_schema || '.' || p_source_table || ' AS ' || v_with_clause || ' SELECT ' || v_columns || ' FROM ' || v_source_schema || '.' || p_source_table || ', t';
  	  
		RAISE NOTICE 'masking view % ', v_sql; 
        IF (EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.views
 						WHERE LOWER(table_schema) = v_view_schema
 						AND   LOWER(table_name) = v_source_table
 						AND   LOWER(table_catalog) = v_database)) 
	  		THEN
	            v_dsql = 'DROP VIEW ' || p_view_schema || '.' || v_source_table;
				EXECUTE v_dsql;
		END IF;
        
	    EXECUTE v_sql;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE sys.MaskingReconciliation(p_database TEXT, p_source_schema TEXT, p_view_schema TEXT)
AS $$  
DECLARE  v_table TEXT;
DECLARE  v_vs TEXT = LOWER(p_view_schema);
DECLARE  v_msg TEXT;
DECLARE  v_ds  TEXT = LOWER(p_source_schema);
DECLARE  v_ret INT = 0;
DECLARE  recCursor CURSOR FOR SELECT TABLENAME FROM PG_TABLES WHERE SCHEMANAME = v_ds;
BEGIN	
	  	IF NOT EXISTS (SELECT * FROM pg_catalog.pg_namespace WHERE LOWER(nspname) = v_vs)
           		THEN RAISE EXCEPTION 'Schema % does not exist.', v_vs;
	  	END IF;
	  		
	  	IF NOT EXISTS (SELECT * FROM PG_TABLES WHERE LOWER(schemaname) = v_ds) 
           	THEN RAISE EXCEPTION 'Schema % does not exist.', v_ds;
	  	END IF;
	  		
	  	OPEN recCursor;
	
	  	LOOP
			FETCH NEXT FROM recCursor INTO v_table;
			EXIT WHEN NOT FOUND;
		
			RAISE NOTICE 'maskingReconciliation:Processing % % ', v_ds, v_table; 

			CALL sys.genmaskingview(p_database, p_source_schema, v_table, p_view_schema);

			RAISE NOTICE 'maskingReconciliation:Processed %.% ', v_ds, v_table;
				   
		END LOOP;
			
		CLOSE recCursor;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE sys.unmask_role(IN p_database text, IN p_source_schema text, IN p_table text, IN p_role text)
AS $procedure$  
DECLARE  v_str TEXT;
BEGIN	
	  	IF EXISTS (SELECT * FROM sys.unmasked_roles 
		             WHERE LOWER(database_name) = LOWER(p_database) 
		               AND LOWER(schema_name) = LOWER(p_schema) 
					   AND LOWER(table_name) = LOWER(p_table)
					   AND LOWER(role) = LOWER(p_role))
           		THEN RAISE EXCEPTION 'Row with role %, database %, schema %, table % already exists in sys.unmasked_roles', p_role, p_database, p_schema, p_table;
	  	END IF;
	  		
	  	v_str = 'INSERT INTO sys.unmasked_roles VALUES(LOWER(p_role), LOWER(p_database), LOWER(p_schema), LOWER(p_table))';
		EXECUTE v_str;
END;
$procedure$
LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE sys.mask_role(p_database TEXT, p_source_schema TEXT, p_table TEXT, p_role TEXT)
AS $$  
DECLARE  v_str TEXT;
BEGIN	
	  	IF NOT EXISTS (SELECT * FROM sys.unmasked_roles 
		             WHERE LOWER(database_name) = LOWER(p_database) 
		               AND LOWER(schema_name) = LOWER(p_schema) 
					   AND LOWER(table_name) = LOWER(p_table)
					   AND LOWER(role) = LOWER(p_role))
           		THEN RAISE EXCEPTION 'Row with role %, database %, schema %, table % does not exist in sys.unmasked_roles', p_role, p_database, p_schema, p_table;
	  	END IF;
	  		
	  	v_str = 'DELETE sys.unmasked_roles WHERE LOWER(database_name) = LOWER(p_database) 
		               AND LOWER(schema_name) = LOWER(p_schema) 
					   AND LOWER(table_name) = LOWER(p_table)
					   AND LOWER(role) = LOWER(p_role)';
		EXECUTE v_str;
END;
$$
LANGUAGE plpgsql;

GRANT SELECT, UPDATE, DELETE, INSERT ON sys.pii_masked_columns TO PUBLIC;
GRANT SELECT, UPDATE, DELETE, INSERT ON sys.unmasked_roles TO PUBLIC;
