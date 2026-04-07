--Check if a database is online at a glance


--pull property from each db
SELECT name, 
       DATABASEPROPERTYEX(name, 'Recovery') as recoverymodel,
       DATABASEPROPERTYEX(name, 'Status') as dbstatus
FROM   master.dbo.sysdatabases
ORDER BY 1



--two other methods to check the status of a single database

use master
select databasepropertyex('cpmdemo1','isautoclose')
go
select databasepropertyex('cpmdemo1','status')
go

 --OR
 
--0 is online 1 is offline
use master
select databaseproperty('cognos','isShutdown') 

--http://www.mssqltips.com/tip.asp?tip=1033

