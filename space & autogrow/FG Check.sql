
/* Cleanup Temp Tables */

IF EXISTS (SELECT * FROM tempdb..sysobjects with (nolock) WHERE name like '#drives_new%' AND type in (N'U')) 
DROP TABLE #drives_new


/* Create temp table to store disk drive information from output of sys.dm_os_volume_stats */
CREATE TABLE #drives_new ( 
	[dbid] int,
	fileid int,
	drive varchar(150) COLLATE database_default, 
	FreeSpace numeric(20,2) NULL, 
	TotalSize numeric(20,2) NULL 
) 

	
		/* Populate temp table with disk drive information from output of sys.dm_os_volume_stats */
		INSERT #drives_new
		SELECT 
		f.database_id, 
		f.[file_id],
		vs.volume_mount_point, 
		vs.available_bytes/1024/1024 AS [avail_mb], 
		vs.total_bytes/1024/1024 AS [total_mb]
		FROM sys.master_files AS f
		CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.[file_id]) AS vs
		OPTION (RECOMPILE);


SELECT 
					dbname = DB_NAME(), 
					lname = RTRIM(LEFT(f.[name],128)), 
					phname = RTRIM(LEFT(f.[physical_name],256)), 
					COALESCE(fg.[name], 'LOG') AS [FG_Name],
					f.[file_id] AS [File_ID],
					total_size = f.[size]/128.0,
					used_mb = CONVERT(numeric(20,2),CONVERT(float,CONVERT(numeric(20,2),FILEPROPERTY(f.[name],'SpaceUsed'))/128)), 
					CASE WHEN CONVERT(numeric(20,2),CONVERT(float,CONVERT(numeric(20,2),FILEPROPERTY(f.[name],'SpaceUsed'))/128)) != 0 
						THEN CONVERT(nvarchar(10),CONVERT(numeric(20,2),CONVERT(float,CONVERT(numeric(20,2),FILEPROPERTY(f.[name],'SpaceUsed'))/128) / CONVERT(float,CONVERT(float,f.[size])/128) * 100)) 
						ELSE '0' END AS percent_used, 
					CASE WHEN f.[growth] = 0 
						THEN 0 ELSE 1 END AS IsAutogrow, 
					CASE 
						WHEN f.[is_percent_growth] = 1 AND f.[max_size] > 0 
						AND CONVERT(numeric(20,2),CONVERT(float,CONVERT(float,f.[size])/128) * (str(f.[growth]))/100) + CONVERT(float,CONVERT(float,f.[size])/128) < [max_size]/128.0 
						AND CONVERT(float,CONVERT(float,CONVERT(float,f.[size])/128) * (str(growth))/100) < d.[FreeSpace]
							THEN 1 
						WHEN f.[is_percent_growth] = 1 AND f.[max_size] = -1 
						AND CONVERT(numeric(20,2),CONVERT(float,CONVERT(float,f.[size])/128) * (str(f.[growth]))/100) < d.[FreeSpace]
							THEN 1 
						WHEN f.[is_percent_growth] = 0 AND f.[max_size] > 0 
						AND CONVERT(numeric(20,2),growth/128.0) + CONVERT(float,CONVERT(float,[size])/128) < [max_size]/128.0 
						AND CONVERT(float,growth/128.0) < d.[FreeSpace] 
							THEN 1 
						WHEN f.[is_percent_growth] = 0 AND f.[max_size] = -1 
						AND CONVERT(numeric(20,6),growth/128.0) < d.[FreeSpace] 
							THEN 1 
						ELSE 0 END AS growth_check, 
					CASE 
						WHEN f.[is_percent_growth] = 1 AND f.[max_size] > 0 
						AND CONVERT(numeric(20,2),CONVERT(float,CONVERT(float,f.[size])/128) * (str(f.[growth]))/100) + CONVERT(float,CONVERT(float,f.[size])/128) < [max_size]/128.0 
						AND CONVERT(float,CONVERT(float,CONVERT(float,f.[size])/128) * (str(growth))/100) < d.[FreeSpace]
							THEN FLOOR(ISNULL(d.[FreeSpace] / NULLIF(CONVERT(float,CONVERT(float,CONVERT(float,f.[size])/128) * (str(growth))/100),0), 0))
						WHEN f.[is_percent_growth] = 1 AND f.[max_size] = -1 
						AND CONVERT(numeric(20,2),CONVERT(float,CONVERT(float,f.[size])/128) * (str(f.[growth]))/100) < d.[FreeSpace]
							THEN FLOOR(ISNULL(d.[FreeSpace] / NULLIF(CONVERT(numeric(20,2),CONVERT(float,CONVERT(float,f.[size])/128) * (str(f.[growth]))/100),0), 0))
						WHEN f.[is_percent_growth] = 0 AND f.[max_size] > 0 
						AND CONVERT(numeric(20,2),growth/128.0) + CONVERT(float,CONVERT(float,[size])/128) < [max_size]/128.0 
						AND CONVERT(float,growth/128.0) < d.[FreeSpace] 
							THEN FLOOR(ISNULL(d.[FreeSpace] / NULLIF(CONVERT(float,growth/128.0),0), 0))
						WHEN f.[is_percent_growth] = 0 AND f.[max_size] = -1 
						AND CONVERT(numeric(20,6),growth/128.0) < d.[FreeSpace] 
							THEN FLOOR(ISNULL(d.[FreeSpace] /  NULLIF(CONVERT(numeric(20,6),growth/128.0),0), 0))
						ELSE 0 END AS Growths_Left, 
					CASE 
						WHEN [max_size] = -1 AND growth <> 0 
						THEN 0 
						ELSE 1 END AS Is_restricted, 
					[max_size], 
					[FreeSpace], 
					[size] 
					FROM sys.database_files AS f
					LEFT JOIN sys.filegroups AS fg
						ON f.data_space_id = fg.data_space_id
					LEFT OUTER JOIN #drives_new AS d ON f.[file_id] = d.[fileid] AND d.[dbid]= DB_ID()
					ORDER BY dbname ASC
					OPTION (RECOMPILE);