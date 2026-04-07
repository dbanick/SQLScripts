/*
    obtain the identify of the login that "owns" the database by looking at the 
    UserName column in the output from the following command:
*/
RESTORE HEADERONLY FROM DISK = 'D:\SQLServer\Temp\CDCTest.bak'

/*
    This login is the owner of the database
*/
CREATE LOGIN CDCTestLogin 
WITH PASSWORD = 'LozierPituophisUnconsciousShelduck4'
    , SID = 0x2ECDACB721D7E84E8A28DCFE1C758799;

/*
    Ensure the login is a member of the 'sysadmin' server-level fixed role.
*/
EXEC sp_addsrvrolemember @loginame = 'CDCTestLogin', @rolename = 'sysadmin';
GO


/*
    Restore the database, with the KEEP_CDC option
*/
RESTORE DATABASE CDCTest FROM DISK = 'D:\SQLServer\Temp\CDCTest.bak'
WITH MOVE 'CDCTest' TO 'D:\SQLServer\MV2012\Data\CDCTest.mdf'
    , MOVE 'CDCTest_log' TO 'D:\SQLServer\MV2012\Logs\CDCTest_log.LDF'
    , REPLACE
    , KEEP_CDC;