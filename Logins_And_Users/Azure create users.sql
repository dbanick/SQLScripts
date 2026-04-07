--use master
go
CREATE LOGIN dschmer WITH password='****'
GO

CREATE USER dschmer FOR LOGIN dschmer WITH DEFAULT_SCHEMA=[dbo] 
GO

--use DB
go
CREATE USER dschmer
	FOR LOGIN dschmer
	
GO

-- Add user to the database owner role
EXEC sp_addrolemember N'db_datareader', N'dschmer'
GO
