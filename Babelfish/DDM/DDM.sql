CREATE OR REPLACE FUNCTION sys.fun_now() 
RETURNS sys.NVARCHAR(30) 
AS $$ 
	BEGIN 
		RETURN CAST(NOW() AS sys.NVARCHAR(30)); 
	END; 
$$ 
LANGUAGE pltsql
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

CREATE OR REPLACE FUNCTION sys.num(IN "@p_datatype" TEXT)
				RETURNS SMALLINT 
AS $$
BEGIN
		IF LOWER(@p_datatype) in ('int','int4','int8','bigint','decimal','numeric','money','fixeddecimal','float','float4','float8','tinyint','smallint')
				 	RETURN 1;
      
		RETURN 0;
END;
$$
LANGUAGE pltsql;

CREATE OR REPLACE FUNCTION sys.string(IN "@p_datatype" TEXT)
	RETURNS SMALLINT
AS $$
BEGIN
	 IF LOWER(@p_datatype) in ('char','varchar','nvarchar','nchar','text') RETURN 1;
	
	 RETURN 0;
END;
$$
LANGUAGE pltsql;

CREATE OR REPLACE FUNCTION sys.dat(IN "@p_datatype" TEXT)
	RETURNS SMALLINT
AS $$
BEGIN
	 IF LOWER(@p_datatype) in ('date', 'datetime2', 'datetime', 'datetimeoffset', 'smalldatetime', 'time')
	 	RETURN 1;
	 RETURN 0;
END;
$$
LANGUAGE pltsql;

CREATE OR REPLACE PROCEDURE sys.SplitString(IN "@p_text" TEXT, IN "@p_delim" char(1))
AS $$
BEGIN
		DECLARE @v_table table(id int, col nvarchar(100));
	 	INSERT @v_table
			SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS RowNum,
		    value
		    FROM STRING_SPLIT(@p_text, @p_delim);
		
		SELECT * FROM @v_table;
END;
$$
LANGUAGE pltsql;

CREATE OR REPLACE FUNCTION sys.maskingstring("@p_mask" text, "@p_column" text, "@p_datatype" text)
 RETURNS character varying
 LANGUAGE pltsql
AS '{"version_num": "1", "typmod_array": ["-1", "-1", "-1", "776"], "original_probin": ""}', $function$
BEGIN
		DECLARE @v_str NVARCHAR(254) = LOWER(REPLACE(@p_mask,' ',''));
		DECLARE @v_l1  INT = LEN(@v_str);
		DECLARE @v_pos INT;
		DECLARE @v_l2  INT;
		DECLARE @v_func_string NVARCHAR(100);
		DECLARE @v_args NVARCHAR(100);
	    DECLARE @v_padding NVARCHAR(100);
	    DECLARE @v_len  INT;
	    DECLARE @v_start  INT;
	    DECLARE @v_end  INT;
	    DECLARE @v_cnt  INT;
	    DECLARE @v_func NVARCHAR(100);
	    DECLARE @v_err INT = 33557097;
	    DECLARE @v_msg NVARCHAR(254);	
	    DECLARE @v_table table(id int, val nvarchar(100));
	    DECLARE @v_masked_string NVARCHAR(100);

		IF  @p_mask = '' RETURN  '';

		SET @v_msg = FORMATMESSAGE('Invalid Masking String: %s', @p_mask);
	   
		IF CHARINDEX('maskedwith(function=', @v_str) = 0 THROW @v_err, @v_msg, 1;
	    
		SET @v_pos = CHARINDEX('=', @v_str) + 1;
		SET @v_l2 =  @v_l1 - @v_pos ;
	    SET @v_func_string = SUBSTRING(@v_str, @v_pos, @v_l2);
	    SET @v_len  =  CHARINDEX('(', @v_func_string) - 1;
	    SET @v_func = SUBSTRING(@v_func_string, 1, @v_len);
	   
		IF  @v_func NOT IN('partial', 'default', 'random', 'email') THROW @v_err, @v_msg, 1;
	
		SET @v_args = SUBSTRING(@v_func_string, @v_len + 2, LEN(@v_func_string) - @v_len - 2);
	
		IF @v_args = '' 
			SET @v_str =  @v_func;
		ELSE
		SET @v_str =  @v_func + ',' + @v_args;
	
		INSERT @v_table 
			SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS RowNum,
		    value
		    FROM STRING_SPLIT(@v_str, ',');
  		
  		SELECT @v_cnt = count(*) from @v_table;
  	
  		SELECT @v_func = val from @v_table WHERE id = 1;
  	
  		IF ((@v_func = 'default' OR @v_func = 'email') AND @v_cnt != 1 ) OR
		    (@v_func = 'partial' AND @v_cnt != 4 ) OR
		    (@v_func = 'random' AND @v_cnt != 3 )
  			BEGIN
	  			SET @v_msg = FORMATMESSAGE('Invalid function format: %s', @v_mask);
	  			THROW @v_err, @v_msg, 1;
	  		END
	
			IF(@v_func = 'default')
			   BEGIN
		  		 IF sys.num(@p_datatype) = 1 SET @v_func = 'default_num';	   					
			  		ELSE IF sys.string(@p_datatype) = 1 SET @v_func = 'default_string';
			  			  ELSE IF sys.dat(@p_datatype) = 1 SET @v_func = 'default_date';
			  			   		 ELSE
							  		BEGIN
							  			 SET @v_msg = FORMATMESSAGE('Wrong Data Type for DDM function default: Column % with data type %.', @p_column, @p_datatype);
						  			 	 THROW @v_err, @v_msg, 1;
						  			END;
						  		
			    RETURN'sys.' + @v_func + '() ';

			   END

		IF(@v_func = 'email')
		  BEGIN
		  	IF sys.string(@p_datatype) != 1  
				  		BEGIN
				  			 SET @v_msg = FORMATMESSAGE('Wrong Data Type for DDM function email: Column % with data type %.', @p_column, @p_datatype);
			  			 	 THROW @v_err, @v_msg, 1;
			  			END;		  		
		   
		  	RETURN 'sys.' + @v_func + '(' + @p_column + ') ';	
		  END;
		
		IF(@v_func = 'random')
		  	BEGIN
		  		IF sys.num(@p_datatype) = 1 SET @v_func = 'random_num';
			  		ELSE 
				  		BEGIN
				  			 SET @v_msg = FORMATMESSAGE('Wrong Data Type for DDM function random: Column % with data type %.', p_column, p_datatype);
			  			 	 THROW @v_err, @v_msg, 1;
			  			END;
		  		
		  		SELECT @v_start = val from @v_table WHERE id = 2;
		  		SELECT @v_end = val from @v_table WHERE id = 3;
		  		RETURN 'sys.' + @v_func + '(' + CAST(@v_start AS VARCHAR) + ',' + CAST(@v_end AS VARCHAR) + ') ';	
		  	END;
		
		IF(@v_func = 'partial')
		  	BEGIN
		  		IF sys.string(@p_datatype) != 1 
			  				BEGIN
				  			 SET @v_msg = FORMATMESSAGE('Wrong Data Type for DDM function partial: Column % with data type %.', @p_column, @p_datatype);
			  			 	 THROW @v_err, @v_msg, 1;
			  			 	END
		  		
		  		SELECT @v_start = val from @v_table WHERE id = 2;
		  		SELECT @v_padding = val from @v_table WHERE id = 3;
		  		SELECT @v_end = val from @v_table WHERE id = 4;	
		  		
		  		RETURN 'sys.' + @v_func + '(' + @p_column + ',' + CAST(@v_start AS VARCHAR) + ',' + '''' + @v_padding + '''' + ',' +  CAST(@v_end AS VARCHAR) + ')';	
		
			END
END;
$function$
;

CREATE OR REPLACE FUNCTION sys.email(IN "@p_email" TEXT)
RETURNS VARCHAR(776)
AS $$
BEGIN

	    RETURN  REGEXP_REPLACE(@p_email COLLATE c, '([a-zA-Z0-9]{0,1})[a-zA-Z0-9_\-\.]+@([a-zA-Z0-9_\-]+\.)+(com|org|edu|nz|au|net|gov|biz)', '\1XXX@XXXXX.\3');
END;
$$
LANGUAGE pltsql;

CREATE OR REPLACE FUNCTION sys.partial(IN "@p_column" TEXT, IN "@p_start" INT, IN "@p_padding" TEXT, IN "@p_end" INT)
RETURNS VARCHAR(776)
AS $$
BEGIN 
		DECLARE @v_l1 NUMERIC = LENGTH(@p_column);
		DECLARE	@v_l2  NUMERIC = LENGTH(@p_column) - LENGTH(@p_padding);
	
		IF (@v_l2 <= 0) OR (@p_start = 0 and @p_end = 0) RETURN @p_padding; 
		IF (@p_end + @p_start) < @v_l2 
	 	   BEGIN
	 		SET @p_start = @v_l2/2;
	 	    SET @p_end= @v_l2/2;
	       END
	    RETURN  SUBSTRING(@p_column, 1, @p_start) + @p_padding + SUBSTRING(@p_column, @v_l1 - @p_end + 1, @p_end) ;   
END;
$$
LANGUAGE pltsql;

CREATE OR REPLACE FUNCTION sys.default_string()
RETURNS VARCHAR(776)
AS $$
BEGIN  	
	 
	    RETURN 'X';
	   
END;
$$
LANGUAGE pltsql;

CREATE  OR REPLACE FUNCTION sys.default_num()
RETURNS NUMERIC
AS $$
BEGIN  
	
	RETURN  0;
	   
END;
$$
LANGUAGE pltsql;


CREATE  OR REPLACE FUNCTION sys.default_date()
RETURNS VARCHAR(50)
AS $$
BEGIN  
	
	RETURN  '1900-01-01 00:00:00.00000000';
	   
END;
$$
LANGUAGE pltsql;


CREATE  OR REPLACE FUNCTION sys.random_string(IN "@p_column" TEXT)
RETURNS VARCHAR(776)
AS $$
BEGIN
  RETURN REPEAT(STRING_AGG (SUBSTR('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', CEIL (RANDOM() * 62), 1), ''),LENGTH(@col));
END;
$$
LANGUAGE pltsql;

CREATE  OR REPLACE FUNCTION sys.random_num(IN "@p_low" INT , IN "@p_high" INT) 
   RETURNS INT 
AS $$
BEGIN
   RETURN FLOOR(RANDOM()* (@p_high - @p_low + 1) + @p_low);
END;
$$
LANGUAGE pltsql;

CREATE OR REPLACE PROCEDURE sys.genmaskingview(IN "@p_database" text, IN "@p_source_schema" text, IN "@p_source_table" text, IN "@p_view_schema" text)
 LANGUAGE pltsql
AS '{"version_num": "1", "typmod_array": ["-1", "-1", "-1", "-1"], "original_probin": ""}', $procedure$
BEGIN 
	DECLARE @v_source_table NVARCHAR(100) = LOWER (@p_source_table);
  	DECLARE @v_database NVARCHAR(100) = LOWER (@p_database);
    DECLARE @v_source_schema NVARCHAR(100) = LOWER (@p_source_schema);
    DECLARE @v_view_schema NVARCHAR(100) = LOWER (@p_view_schema);
	DECLARE @v_physical_source_schema  NVARCHAR(100) = @v_database + '_' + @v_source_schema;
    DECLARE @v_physical_view_schema    NVARCHAR(100) = @v_database + '_' + @v_view_schema;
	DECLARE @v_masking NVARCHAR(776);
    DECLARE @v_unmasked_roles NVARCHAR(776) = '';
    DECLARE @v_unmasked_masked_columns NVARCHAR(776) = '';
    DECLARE @v_unmasked_columns NVARCHAR(776) = '';
    DECLARE @v_masked_columns NVARCHAR(776) = '';
    DECLARE @v_sql_string NVARCHAR(776) = '';
	DECLARE @v_column NVARCHAR(100);
    DECLARE @v_columns NVARCHAR(776);
    DECLARE @v_with_clause NVARCHAR(776);
    DECLARE @v_mstring NVARCHAR(776);
	DECLARE @v_datatype NVARCHAR(100);
	DECLARE @v_masked_string NVARCHAR(776);
	DECLARE @v_msg NVARCHAR(776);
	DECLARE @v_err INT8 = 33557097;
   	DECLARE @v_out NVARCHAR(100);
    DECLARE @v_func NVARCHAR(100);
    DECLARE @v_cnt tinyint = 0;
    DECLARE @v_padding NVARCHAR(100);
    DECLARE @v_start NVARCHAR(10);
    DECLARE @v_end NVARCHAR(10);
    DECLARE @v_sql NVARCHAR(776);
    DECLARE @v_dsql NVARCHAR(776);

	DECLARE @v_recCursor CURSOR FOR
			WITH t AS (SELECT c.column_name, c.data_type  AS datatype 
				      FROM  INFORMATION_SCHEMA.columns c
				      WHERE LOWER(c.table_name) = @v_source_table
				      AND   LOWER(c.table_schema) = @v_source_schema
				      AND   LOWER(c.table_catalog) =  @v_database
				     )
			 SELECT t.column_name, t.datatype, masking FROM t INNER JOIN sys.pii_masked_columns m ON m.column_name = t.column_name 
             WHERE LOWER(m.table_name) = @v_source_table AND LOWER(m.schema_name) = @v_source_schema and LOWER(m.database_name) = @v_database
                    UNION all
             SELECT t.column_name, t.datatype,'' FROM t WHERE t.column_name NOT IN 
            (SELECT column_name FROM sys.pii_masked_columns m WHERE LOWER(m.table_name) = @v_source_table AND LOWER(m.schema_name) = @v_source_schema and LOWER(m.database_name) = @v_database)
      		FOR READ ONLY;

		IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE LOWER(name) = @v_database)
			BEGIN
	            SET @v_msg = FORMATMESSAGE('Source table database %s does not exist.', @p_database);
				THROW @v_err, @v_msg, 1;
	        END

	    IF NOT EXISTS (SELECT 1 from INFORMATION_SCHEMA.schemata
 						WHERE LOWER(schema_name) = @v_view_schema
 						AND   LOWER(catalog_name) = @v_database)
	  		BEGIN
	  			SET @v_msg = FORMATMESSAGE('Schema %s does not exist.', @p_view_schema);	 
           		THROW @v_err, @v_msg, 1;
	  		END 
	  		
      	IF @v_physical_source_schema = @v_physical_view_schema 
	        BEGIN
	            SET @v_msg = FORMATMESSAGE('Source table cannot be in the same schema as the view schema %s.', @p_source_schema);
				THROW @v_err, @v_msg, 1;
	        END
			
		IF NOT EXISTS (SELECT 1 FROM PG_TABLES WHERE LOWER(schemaname) = @v_physical_source_schema and tablename = @v_source_table) 
			BEGIN
	            SET @v_msg = FORMATMESSAGE('Source table %s does not exist in schema %s.', @p_source_table, @p_source_schema);
				THROW @v_err, @v_msg, 1;
	        END

		IF  current_schema() NOT like @v_database + '%'
			BEGIN
	            SET @v_msg = FORMATMESSAGE('Current database is not %s.', @p_database);
				THROW @v_err, @v_msg, 1;
	        END
	        
        OPEN @v_recCursor;
		
		FETCH NEXT FROM @v_recCursor INTO @v_column,@v_datatype, @v_masking;
		WHILE @@FETCH_STATUS = 0
  			BEGIN

	  			SET @v_func = '';
	  			SET @v_out = '';
	  		    SET @v_masked_string = '';
	
	  			IF @v_masking = ''
	  			    	BEGIN
		  			    	  IF @v_unmasked_columns = '' 
			  			     	 SET @v_unmasked_columns = @v_column;
			  			      	 ELSE SET @v_unmasked_columns = @v_unmasked_columns + ', ' + @v_column;
		  			   	END
		  			ELSE
	                    BEGIN
				  			SET @v_masked_string = sys.MaskingString(@v_masking, @v_column, @v_datatype);
				  		    SET @v_mstring = ' CASE WHEN cnt = 1 THEN ' + @v_column + ' ELSE ' + @v_masked_string + ' END AS ' + @v_column;
						 	IF @v_masked_columns = '' 
					  			      SET @v_masked_columns = @v_mstring;
					  			      ELSE SET @v_masked_columns = @v_masked_columns + ', ' + @v_mstring;
	  	   				END
  			   
  				FETCH NEXT FROM @v_recCursor INTO @v_column,@v_datatype, @v_masking;
  			END
  		
		CLOSE @v_recCursor;
	    DEALLOCATE @v_recCursor;	
  	  
  	    IF @v_unmasked_columns = ''
				SET @v_columns = @v_masked_columns;
	  	        ELSE
					IF @v_masked_columns = '' 
				    	SET  @v_columns = @v_unmasked_columns;
			        	ELSE 
						SET @v_columns = @v_unmasked_columns + ',' + @v_masked_columns

		SET @v_with_clause = ' WITH t AS (SELECT COUNT(*) as cnt from sys.unmasked_roles ' +
  	   					' WHERE table_name = ' + '''' + @v_source_table + '''' +
 	   					' AND schema_name = ' + '''' + @v_source_schema + '''' +
       					' AND database_name =' + '''' + @v_database + '''' +
       					' AND role = ORIGINAL_LOGIN())';

		SET @v_sql =  'CREATE VIEW ' + @p_view_schema + '.' + @p_source_table + ' AS ' + @v_with_clause + ' SELECT ' + @v_columns + ' FROM ' + @v_source_schema + '.' + @p_source_table + ', t';
;
	    IF (EXISTS (SELECT 1 from INFORMATION_SCHEMA.views
 						WHERE LOWER(table_schema) = @v_view_schema
 						AND   LOWER(table_name) = @v_source_table
 						AND   LOWER(table_catalog) = @v_database)) 
	  		BEGIN
	            SET @v_dsql = 'DROP VIEW ' +  @v_view_schema + '.' + @v_source_table;
				EXEC (@v_dsql);
	        END
        EXEC (@v_sql);
END;
$procedure$
;



CREATE OR REPLACE PROCEDURE sys.MaskingReconciliation(IN "@p_database" TEXT, IN "@p_source_schema" TEXT, IN "@p_view_schema" TEXT)
AS $$
BEGIN
	  
		DECLARE  @v_table sys.NVARCHAR(100);
	    DECLARE  @v_vs sys.NVARCHAR(100) = LOWER(@p_database + '_' + @p_view_schema);
		DECLARE  @v_msg sys.NVARCHAR(200);
		DECLARE  @v_ds  sys.NVARCHAR(200) = LOWER(@p_database + '_' + @p_source_schema);
		DECLARE  @v_ret INT = 0;
	    DECLARE  @v_err INT = 33557097;
		DECLARE  @v_recCursor CURSOR FOR SELECT TABLENAME FROM PG_TABLES WHERE SCHEMANAME = @v_ds;
	
	  	IF NOT EXISTS (SELECT * FROM pg_catalog.pg_namespace WHERE LOWER(nspname) = @v_vs)
	  		BEGIN
	  			SET @v_msg = FORMATMESSAGE('Schema %s does not exist.', @v_vs);	 
           		THROW @v_err, @v_msg, 1;
	  		END
	  		
	  	IF NOT EXISTS (SELECT * FROM PG_TABLES WHERE LOWER(schemaname) = @v_ds)
	  		BEGIN
	  			SET @v_msg = FORMATMESSAGE('Schema %s does not exist.', @v_ds);	 
           		THROW @v_err, @v_msg, 1;
	  		END
	  		
	  	OPEN @v_recCursor;
	
		FETCH NEXT FROM @v_recCursor INTO @v_table;
			
		WHILE @@FETCH_STATUS = 0
  			BEGIN
				    SET @v_msg = FORMATMESSAGE('maskingReconciliation:Processing %s %s ', @v_ds, @v_table);
					print @v_msg

				    EXEC @v_ret = sys.genmaskingview @p_database, @p_source_schema, @v_table, @p_view_schema;
					
					IF @v_ret = -1 
						BEGIN
							SET @v_msg = FORMATMESSAGE('maskingReconciliation:Failed to process %s %s', @v_ds, @v_table);	 
           				    THROW @v_err, @v_msg, 1;
						END
						
				   	SET @v_msg = FORMATMESSAGE('maskingReconciliation:Processed %s.%s ', @v_ds, @v_table);
					print @v_msg
	  			
					FETCH NEXT FROM @v_recCursor INTO @v_table;
				   
			END;
			
			CLOSE @v_recCursor;
		    DEALLOCATE @v_recCursor;
END;
$$
LANGUAGE pltsql;

GRANT SELECT, UPDATE, DELETE, INSERT ON sys.pii_masked_columns TO PUBLIC;
GRANT SELECT, UPDATE, DELETE, INSERT ON sys.unmasked_roles TO PUBLIC;


