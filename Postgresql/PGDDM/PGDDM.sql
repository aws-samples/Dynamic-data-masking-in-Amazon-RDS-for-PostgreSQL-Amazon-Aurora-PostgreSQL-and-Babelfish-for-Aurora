-- Author: Ezat Karimi
--
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
	 IF LOWER(p_datatype) in ('date', 'timestamp', 'time') THEN
	 	RETURN 1;
	 END IF;
	 RETURN 0;
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

-- Specify what to expose
CREATE OR REPLACE FUNCTION sys.partial(
    input_text text,
    prefix_length integer,
    padding_string text,
    suffix_length integer
)
RETURNS text
AS $$
DECLARE
    input_length integer := length(input_text);
    total_exposed_length integer := prefix_length + suffix_length;
    final_prefix text;
    final_suffix text;
BEGIN
    -- Handle case where the total exposed length is longer than the input string
    IF total_exposed_length >= input_length THEN
        -- If the entire string is shorter than or equal to the exposed parts,.
        RETURN padding_string || input_text;
    ELSE
        -- Extract the prefix
        final_prefix := SUBSTRING(input_text, 1, prefix_length);
        
        -- Extract the suffix
        final_suffix := SUBSTRING(input_text, input_length - suffix_length + 1, suffix_length);
        
        -- Return the combined masked string
        RETURN final_prefix || padding_string || final_suffix;
    END IF;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.default_string(p_value TEXT)
RETURNS TEXT
AS $$
BEGIN  	
	 
	    RETURN p_value;
	   
END;
$$
LANGUAGE plpgsql;

CREATE  OR REPLACE FUNCTION sys.default_num(p_value INT)
RETURNS NUMERIC
AS $$
BEGIN  
	
	RETURN  p_value;
	   
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sys.default_date()
RETURNS date
AS $$
BEGIN  
	
	RETURN  '1900-01-01 00:00:00.00000000';
	   
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sys.random_string(p_length INT)
RETURNS TEXT AS $$
    SELECT ARRAY_TO_STRING(
        ARRAY(
            SELECT SUBSTRING('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz' FROM (floor(random()*62)+1)::int FOR 1)
            FROM GENERATE_SERIES(1, p_length)
        ), ''
    );
$$ LANGUAGE sql;

CREATE  OR REPLACE FUNCTION sys.random_num(p_low INT , p_high INT) 
   RETURNS INT 
AS $$
BEGIN
   RETURN FLOOR(RANDOM()* (p_high - p_low + 1) + p_low);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.maskingstring(p_mask TEXT, p_column TEXT, p_datatype TEXT)
 RETURNS TEXT
AS $$
DECLARE v_str TEXT = LOWER(REPLACE(p_mask,' ',''));
DECLARE v_l1  INT = LENGTH(v_str);
DECLARE v_pos INT;
DECLARE v_l2  INT;
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
	    RAISE DEBUG 'p_mask is %, p_column is %, p_datatype is %', p_mask, p_column, p_datatype;
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
  	/*
  		IF ((v_func = 'default' OR v_func = 'email') AND v_cnt != 1 ) OR
		    (v_func = 'partial' AND v_cnt != 4 ) OR
		    (v_func = 'random' AND v_cnt != 3 )
		    THEN RAISE EXCEPTION 'Invalid function format: %', p_mask;
	    END IF;
	*/
		IF(v_func = 'default') THEN
				 IF sys.string(p_datatype) = 1 THEN
						RETURN 'sys.default_string' || '(''' || v_tab[2] || ''') ';
				 END IF;
				 IF sys.num(p_datatype) = 1 THEN
		  				RETURN 'sys.default_num' || '(' || v_tab[2]::TEXT  || ') ';
				 END IF;
				 IF sys.dat(p_datatype) = 1 THEN
		  				RETURN 'sys.default_date()::date';
				 END IF;
				 RAISE EXCEPTION 'Wrong Data Type for DDM function default: Column % with data type %.', p_column, p_datatype;
		END IF;

		IF(v_func = 'email') THEN
		  	IF sys.string(p_datatype) = 1 THEN
				  	RETURN 'sys.' || v_func || '(' || p_column || ') ';
			END IF;		  		
		    RAISE EXCEPTION 'Wrong Data Type for DDM function email: Column % with data type %.', p_column, p_datatype;  		
		END IF;
		
		IF(v_func = 'random') THEN
				IF (sys.string(p_datatype)) = 1 THEN
				  		RETURN 'sys.random_string'  || '(' || v_tab[2]  || ') ';
				END IF;
				IF (sys.num(p_datatype) = 1) THEN
		  				RETURN 'sys.random_num' || '(' || v_tab[2]::TEXT || ',' || v_tab[3]::TEXT || ') ';
				END IF;
				RAISE EXCEPTION 'Wrong Data Type for DDM function random: Column % with data type %.', p_column, p_datatype;	
		END IF;
		
		IF(v_func = 'partial') THEN
		  		IF sys.string(p_datatype) = 1 THEN
				RETURN 'sys.' || v_func ||'(' || p_column || ',' || v_tab[2]::TEXT || ',' || '''' || v_tab[3]::TEXT  || '''' || ',' ||  v_tab[4]::TEXT  || ')';
			  	END IF;
		  		RAISE EXCEPTION 'Wrong Data Type for DDM function partial: Column % with data type %.', p_column, p_datatype;
		END IF;
END;
$$
LANGUAGE plpgsql
immutable;

CREATE OR REPLACE PROCEDURE sys.GenMaskingView
(p_database TEXT, 
 p_source_schema TEXT, 
 p_source_table TEXT,
 p_view_schema TEXT
)
AS $$ 
DECLARE i_source_table TEXT = quote_ident(p_source_table);
DECLARE i_database TEXT = quote_ident(p_database);
DECLARE i_source_schema TEXT = quote_ident(p_source_schema);
DECLARE i_view_schema TEXT = quote_ident(p_view_schema);
DECLARE i_column_name TEXT;

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
DECLARE v_padding TEXT;
DECLARE v_sql TEXT;

DECLARE v_recCursor CURSOR FOR
			WITH t AS (SELECT c.column_name, c.data_type  AS datatype 
				      FROM  INFORMATION_SCHEMA.columns c
				      WHERE c.table_name = p_source_table
				      AND   c.table_schema = p_source_schema 
				      AND   c.table_catalog =  p_database
				     )
			 SELECT t.column_name, t.datatype, m.masking FROM t INNER JOIN sys.pii_masked_columns m ON m.column_name = t.column_name 
             WHERE m.table_name = p_source_table AND m.schema_name = p_source_schema and m.database_name = p_database
                    UNION all
             SELECT t.column_name, t.datatype,'' FROM t WHERE t.column_name NOT IN 
            (SELECT column_name FROM sys.pii_masked_columns m WHERE m.table_name = p_source_table AND m.schema_name = p_source_schema and m.database_name = p_database)
      		FOR READ ONLY;
BEGIN

		IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_database  WHERE datname = p_database) 
			THEN RAISE EXCEPTION 'Sourc database % does not exist.', p_database;
	    END IF;

		IF  current_database() != p_database
			THEN RAISE EXCEPTION 'Current database is not %.', p_database;
	    END IF;

		IF NOt has_permission(CURRENT_ROLE, p_source_schema, p_source_table, p_view_schema)
			THEN RAISE EXCEPTION 'You do not have sufficient permission to run this procedure';
	    END IF;

 		IF NOT EXISTS (SELECT 1 from INFORMATION_SCHEMA.schemata
 						WHERE schema_name =  '' || p_source_schema || ''
 						AND   catalog_name = p_database)
	  		THEN RAISE EXCEPTION 'Schema % does not exist.', p_source_schema;
	  	END IF;

	    IF NOT EXISTS (SELECT 1 from INFORMATION_SCHEMA.schemata
 						WHERE schema_name = p_view_schema
 						AND   catalog_name = p_database)
	  		THEN RAISE EXCEPTION 'Schema % does not exist.', p_view_schema;
	  	END IF;
	  		
      	IF p_source_schema = p_view_schema 
				THEN RAISE EXCEPTION 'Source table cannot be in the same schema as the view schema %.', p_source_schema;
	    END IF;
			
		IF NOT EXISTS (SELECT 1 FROM PG_TABLES WHERE schemaname = p_source_schema and tablename = p_source_table) 
			THEN RAISE EXCEPTION 'Source table % does not exist in schema %.', p_source_table, p_source_schema;
	    END IF;
  
        OPEN v_recCursor;
		
        LOOP
			FETCH NEXT FROM v_recCursor INTO v_column, v_datatype, v_masking;
			EXIT WHEN NOT FOUND;
		  			v_tab = '{}';
		  			v_func = '';
		  			v_out = '';
		  		    v_masked_string = '';
				    i_column_name = quote_ident(v_column);
	  			    IF v_masking = ''
	  			    	THEN
		  			    	  IF v_unmasked_columns = '' 
			  			     	 THEN v_unmasked_columns = i_column_name;
			  			      	 ELSE v_unmasked_columns = v_unmasked_columns || ', ' || i_column_name;
		  			   		  END IF;
		  			ELSE
			  			v_masked_string = sys.MaskingString(v_masking, i_column_name, v_datatype);
			  		    v_mstring = ' CASE WHEN cnt = 1 THEN ' || i_column_name || ' ELSE ' || v_masked_string || ' END AS ' || i_column_name;
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
  	   					' WHERE table_name = ' || '''' || p_source_table || '''' ||
 	   					' AND schema_name = ' || '''' || p_source_schema || '''' ||
       					' AND database_name =' || '''' || p_database || '''' ||
       					' AND role = CURRENT_ROLE)';

			 v_sql =  'CREATE  VIEW ' || i_view_schema || '.' || i_source_table || ' AS ' || v_with_clause || ' SELECT ' || v_columns || ' FROM ' || i_source_schema || '.' || i_source_table || ', t';
  	  
	 		EXECUTE 'DROP VIEW IF EXISTS ' || i_view_schema || '.' || i_source_table || ' CASCADE';
	    	EXECUTE v_sql;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE sys.maskingreconciliation(IN p_database text, IN p_source_schema text, IN p_view_schema text)
 LANGUAGE plpgsql
AS $procedure$  
DECLARE  v_table TEXT;
DECLARE  v_cdb TEXT = current_database();
DECLARE  recCursor CURSOR FOR SELECT table_name FROM sys.pii_masked_columns 
                   WHERE schema_name = p_source_schema
                    AND  database_name = p_database;
BEGIN	
	IF v_cdb != p_database THEN RAISE EXCEPTION 'Current database is not %', p_database;
	END IF;
	
	IF NOT EXISTS (SELECT * FROM pg_catalog.pg_namespace WHERE nspname = p_view_schema)
           		THEN RAISE EXCEPTION 'View schema % does not exist.', p_view_schema;
	END IF;

	IF NOT EXISTS (SELECT * FROM pg_catalog.pg_namespace WHERE nspname = p_source_schema)
           		THEN RAISE EXCEPTION 'Source schema % does not exist.', p_source_schema;
	END IF;
	  		
	OPEN recCursor;
	
	LOOP
		FETCH NEXT FROM recCursor INTO v_table;
		EXIT WHEN NOT FOUND;
		
		RAISE NOTICE 'maskingReconciliation:Processing % % ', p_source_schema, v_table; 

		CALL sys.genmaskingview(p_database, p_source_schema, v_table, p_view_schema);

		RAISE NOTICE 'maskingReconciliation:Processed %.% ', p_source_schema, v_table;
				   
	END LOOP;
			
	CLOSE recCursor;
END;
$procedure$
;

CREATE OR REPLACE PROCEDURE sys.unmask_role(p_database text, p_source_schema text, p_table text, p_role text)
AS $procedure$  
DECLARE  v_str TEXT;
BEGIN	
	  	IF EXISTS (SELECT * FROM sys.unmasked_roles 
		             WHERE database_name = p_database 
		               AND schema_name = p_source_schema
					   AND table_name = p_table
					   AND role = p_role)
           		THEN RAISE EXCEPTION 'Row with role %, database %, schema %, table % already exists in sys.unmasked_roles', p_role, p_database, p_source_schema, p_table;
	  	END IF;

		IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = p_role) 
		THEN RAISE EXCEPTION 'Role % does not exist in database %', p_role, p_database;
    	END IF;
	  		
	  	v_str = 'INSERT INTO sys.unmasked_roles(role, database_name, schema_name, table_name) VALUES(''' || p_role || ''', ''' || p_database || 
''',  ''' || p_source_schema || ''' , '''|| p_table || ''')';
		EXECUTE v_str;
END;
$procedure$
LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE sys.mask_role(p_database TEXT, p_source_schema TEXT, p_table TEXT, p_role TEXT)
AS $$  
DECLARE  v_str TEXT;
BEGIN	
	  	IF NOT EXISTS (SELECT * FROM sys.unmasked_roles 
		             WHERE database_name = p_database 
		               AND schema_name = p_source_schema
					   AND table_name = p_table
					   AND role = p_role)
           		THEN RAISE EXCEPTION 'Row with role %, database %, schema %, table % does not exist in sys.unmasked_roles', p_role, p_database, p_source_schema, p_table;
	  	END IF;
	  		
	  	v_str = 'DELETE FROM sys.unmasked_roles WHERE database_name =  ''' || p_database || ''' 
		               AND schema_name =  ''' || p_source_schema || ''' 
					   AND table_name = ''' ||p_table  ||'''
					   AND role = ''' || p_role  || '''';
		EXECUTE v_str;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION has_permission(
    p_role TEXT,
    p_source_schema TEXT,
    p_source_table TEXT,
    p_view_schema TEXT
)
RETURNS BOOLEAN AS $$
DECLARE i_source_table TEXT = quote_ident(p_source_table);
DECLARE i_source_schema TEXT = quote_ident(p_source_schema);
BEGIN
 
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = p_role) THEN RETURN FALSE;
    END IF;

    IF NOT has_schema_privilege(p_role, p_source_schema, 'USAGE') THEN RETURN FALSE;
    END IF;

    IF NOT has_table_privilege(p_role, i_source_schema || '.' || i_source_table, 'SELECT') THEN RETURN FALSE;
    END IF;

    IF NOT has_schema_privilege(p_role, p_view_schema, 'USAGE') THEN RETURN FALSE;
    END IF;

    IF NOT has_schema_privilege(p_role, p_view_schema, 'CREATE') THEN RETURN FALSE;
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

GRANT SELECT, UPDATE, DELETE, INSERT ON sys.pii_masked_columns TO PUBLIC;
GRANT SELECT, UPDATE, DELETE, INSERT ON sys.unmasked_roles TO PUBLIC;
