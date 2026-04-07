USE master
Go
SELECT
DB_NAME(database_id) AS "Database Name"
, name AS "Logical File Name"
, physical_name AS "Physical File Location"
, state_desc AS "State"
FROM
sys.master_files
--WHERE
--database_id IN (DB_ID(N'msdb'), DB_ID(N'model'),DB_ID(N'tempdb'))
ORDER BY
DB_NAME(database_id);
Go
