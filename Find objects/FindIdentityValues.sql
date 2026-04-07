SELECT 
  [database] = db_name(),
  [schema] = s.name,
  [table] = t.name, 
  [identity_column] = i.name,
  [data_type] = t2.name,
  [last_identity] = IDENT_CURRENT(t.name),
  [identity_increment] = IDENT_INCR(t.name),
  CASE 
    WHEN t2.name = 'tinyint' THEN (255 - IDENT_CURRENT(t.name) ) / IDENT_INCR(t.name)
	WHEN t2.name = 'smallint' THEN (32767 - IDENT_CURRENT(t.name)) / IDENT_INCR(t.name)
	WHEN t2.name = 'int' THEN  (2147483647 - IDENT_CURRENT(t.name) ) / IDENT_INCR(t.name)
	WHEN t2.name = 'bigint' THEN (9223372036854775807 - IDENT_CURRENT(t.name)) / IDENT_INCR(t.name)
  END AS [Remaining_identity_values],
  CASE 
	WHEN t2.name = 'tinyint' THEN (255-(255 - IDENT_CURRENT(t.name) ) / IDENT_INCR(t.name))/255
	WHEN t2.name = 'smallint' THEN (32767-(32767 - IDENT_CURRENT(t.name)) / IDENT_INCR(t.name))/32767
	WHEN t2.name = 'int' THEN  (2147483647- (2147483647 - IDENT_CURRENT(t.name) ) / IDENT_INCR(t.name))/2147483647
	WHEN t2.name = 'bigint' THEN (9223372036854775807-(9223372036854775807 - IDENT_CURRENT(t.name)) / IDENT_INCR(t.name))/9223372036854775807
  END AS [PercentFull],
  'select max('+i.name+') from ['+db_name()+'].['+s.name+'].['+t.name+'] ' as query
  FROM sys.schemas AS s 
  INNER JOIN sys.tables AS t
  ON s.[schema_id] = t.[schema_id]
  join sys.identity_columns i on i.object_id = t.object_id
  join sys.types t2 on t2.user_type_id =  i.user_type_id
  where t.is_ms_shipped = 0

