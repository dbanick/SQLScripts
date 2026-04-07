--Compare two tables in the same database
SELECT * FROM Table_A
UNION
SELECT * FROM Table_B
EXCEPT
SELECT * FROM Table_A 
INTERSECT
SELECT * FROM Table_B 

--Compare rows side-by-side
SELECT * FROM ( 
SELECT [ID], [Name], [IsMockTemplate], [Description], [Created], [LastModified], [ViewID], [ViewXml], [UniqueId], [Version], [CustomApplicationType] from APM_ApplicationTemplate 
UNION ALL
SELECT [ID], [Name], [IsMockTemplate], [Description], [Created], [LastModified], [ViewID], [ViewXml], [UniqueId], [Version], [CustomApplicationType] from APM_ApplicationTemplate_OriginalCopyCorrupt
) cmpr ORDER BY ID;

--Compare by matching data values
SELECT A.ID,
	CASE WHEN A.Setting = B.Setting THEN 'Match' 
	ELSE 'Mismatch' 
	END AS Setting_Compare
FROM APM_ExternalSetting A
JOIN APM_ExternalSetting_OriginalCopyCorrupt B
ON (A.ID = B.ID)

--Compare more columns by matching data values
SELECT A.[ID], 
CASE WHEN A.[Name] = B.[Name] THEN 'Match'
	ELSE 'Mismatch' 
	END AS Name_Compare,
CASE WHEN A.[IsMockTemplate] = B.[IsMockTemplate] THEN 'Match' 
	ELSE 'Mismatch' 
	END AS IsMockTemplate_Compare,
CASE WHEN A.[Description] IS NULL THEN 'NULL'
	WHEN A.[Description] = '' THEN 'NULL'
	WHEN A.[Description] = B.[Description] THEN 'Match'
	ELSE 'Mismatch' 
	END AS Description_Compare,
CASE WHEN A.[Created] IS NULL THEN 'NULL'
	WHEN A.[Created] = '' THEN 'NULL'
	WHEN A.[Created] = B.[Created] THEN 'Match'
	ELSE 'Mismatch' 
	END AS Created_Compare,
CASE WHEN A.[LastModified] IS NULL THEN 'NULL'
	WHEN A.[LastModified] = '' THEN 'NULL'
	WHEN A.[LastModified] = B.[LastModified] THEN 'Match'
	ELSE 'Mismatch' 
	END AS LastModified_Compare,
CASE WHEN A.[ViewID] IS NULL THEN 'NULL'
	WHEN A.[ViewID] = '' THEN 'NULL'
	WHEN A.[ViewID] = B.[ViewID] THEN 'Match'
	ELSE 'Mismatch' 
	END AS ViewID_Compare,
CASE WHEN A.[ViewXml] IS NULL THEN 'NULL'
	WHEN A.[ViewXml] = '' THEN 'NULL'
	WHEN A.[ViewXml] = B.[ViewXml] THEN 'Match'
	ELSE 'Mismatch' 
	END AS ViewXml_Compare,
CASE WHEN A.[UniqueId] IS NULL THEN 'NULL'
	WHEN A.[UniqueId] = B.[UniqueId] THEN 'Match' 
	ELSE 'Mismatch' 
	END AS UniqueID_Compare,
CASE WHEN A.[Version] IS NULL THEN 'NULL'
	WHEN A.[Version] = '' THEN 'NULL'
	WHEN A.[Version] = B.[Version] THEN 'Match'
	ELSE 'Mismatch' 
	END AS Version_Compare,
CASE WHEN A.[CustomApplicationType] IS NULL THEN 'NULL'
	WHEN A.[CustomApplicationType] = '' THEN 'NULL'
	WHEN A.[CustomApplicationType] = B.[CustomApplicationType] THEN 'Match' 
	ELSE 'Mismatch' 
	END AS CustomApplicationType_Compare
FROM APM_ApplicationTemplate A
JOIN  APM_ApplicationTemplate_OriginalCopyCorrupt B
ON A.ID = B.ID



--Compare database tables and columns between two databases
--A linked server must be configured if the compared databases are on two separate instances
--Queries sys.objects, sys.columns, and sys.types in master database(s) 

DECLARE @Sourcedb sysname 
DECLARE @Destdb sysname 
DECLARE @Tablename sysname 
DECLARE @SQL varchar(max) 
 
SELECT @Sourcedb = '[<InstanceName>].[<DatabaseName>]' 
SELECT @Destdb   = '[<InstanceName>].[<DatabaseName>]' 
SELECT @Tablename = '%' --  '%' for all tables 
 
SELECT @SQL = ' SELECT Tablename  = ISNULL(Source.tablename,Destination.tablename) 
                      ,ColumnName = ISNULL(Source.Columnname,Destination.Columnname) 
                      ,Source.Datatype 
                      ,Source.Length 
                      ,Source.precision 
                      ,Destination.Datatype 
                      ,Destination.Length 
                      ,Destination.precision 
                      ,[Column]  = 
                       Case  
                       When Source.Columnname IS NULL then ''Column Missing in the Source'' 
                       When Destination.Columnname IS NULL then ''Column Missing in the Destination'' 
                       ELSE '''' 
                       end 
                      ,DataType = CASE WHEN Source.Columnname IS NOT NULL  
                                        AND Destination.Columnname IS NOT NULL  
                                        AND Source.Datatype <> Destination.Datatype THEN ''Data Type mismatch''  
                                  END 
                      ,Length   = CASE WHEN Source.Columnname IS NOT NULL  
                                        AND Destination.Columnname IS NOT NULL  
                                        AND Source.Length <> Destination.Length THEN ''Length mismatch''  
                                  END 
                      ,Precision = CASE WHEN Source.Columnname IS NOT NULL  
                                        AND Destination.Columnname IS NOT NULL 
                                        AND Source.precision <> Destination.precision THEN ''precision mismatch'' 
                                    END 
                      ,Collation = CASE WHEN Source.Columnname IS NOT NULL  
                                        AND Destination.Columnname IS NOT NULL 
                                        AND ISNULL(Source.collation_name,'''') <> ISNULL(Destination.collation_name,'''') THEN ''Collation mismatch'' 
                                        END 
                        
   FROM  
 ( 
 SELECT Tablename  = so.name  
      , Columnname = sc.name 
      , DataType   = St.name 
      , Length     = Sc.max_length 
      , precision  = Sc.precision 
      , collation_name = Sc.collation_name 
  FROM ' + @Sourcedb + '.SYS.objects So 
  JOIN ' + @Sourcedb + '.SYS.columns Sc 
    ON So.object_id = Sc.object_id 
  JOIN ' + @Sourcedb + '.SYS.types St 
    ON Sc.system_type_id = St.system_type_id 
   AND Sc.user_type_id   = St.user_type_id 
 WHERE SO.TYPE =''U'' 
   AND SO.Name like ''' + @Tablename + ''' 
  ) Source 
 FULL OUTER JOIN 
 ( 
  SELECT Tablename  = so.name  
      , Columnname = sc.name 
      , DataType   = St.name 
      , Length     = Sc.max_length 
      , precision  = Sc.precision 
      , collation_name = Sc.collation_name 
  FROM ' + @Destdb + '.SYS.objects So 
  JOIN ' + @Destdb + '.SYS.columns Sc 
    ON So.object_id = Sc.object_id 
  JOIN ' + @Destdb + '.SYS.types St 
    ON Sc.system_type_id = St.system_type_id 
   AND Sc.user_type_id   = St.user_type_id 
WHERE SO.TYPE =''U'' 
  AND SO.Name like ''' + @Tablename + ''' 
 ) Destination  
 ON source.tablename = Destination.Tablename  
 AND source.Columnname = Destination.Columnname ' 
 
EXEC (@Sql)