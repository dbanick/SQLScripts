--https://www.mssqltips.com/sqlservertip/5242/adding-users-to-azure-sql-databases/


-- under master, create the login
CREATE LOGIN test 
WITH PASSWORD = 'SuperSecret!'

ALTER ROLE dbmanager ADD MEMBER [test]; 
ALTER ROLE loginmanager ADD MEMBER [test];

-- select your db in the dropdown and create a user mapped to a login 
CREATE USER [test] FOR LOGIN [test] WITH DEFAULT_SCHEMA = dbo;

-- add user to role(s) in db 
ALTER ROLE db_datareader ADD MEMBER [test];
ALTER ROLE db_datawriter ADD MEMBER [test];
ALTER ROLE db_owner ADD MEMBER [test];

-- under master, create the login
CREATE LOGIN [name@domain.com] 
FROM EXTERNAL PROVIDER

-- add contained Azure AD user in user database
CREATE USER [name@domain.com] 
FROM EXTERNAL PROVIDER 
WITH DEFAULT_SCHEMA = dbo;  
  
-- add user to role(s) in db 
ALTER ROLE db_datareader ADD MEMBER [name@domain.com]; 
ALTER ROLE db_datawriter ADD MEMBER [name@domain.com];
ALTER ROLE db_owner ADD MEMBER [name@domain.com];