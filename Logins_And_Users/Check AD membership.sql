-- Create a linked server to ADSI  and a login to the linked server.
-- AD service account will have minimum rights over the domail: read only.
-- Generally all accounts have read rights on AD.
-- Add ADSI as linked server using sp_alllinkedserver and sp_addlinkedserverlogin
-- OR use SQL-EM to add ADSI as linked server and the login.


-- sp_addlinkedserver 'ADSI', 'Active Directory Service Interfaces', 'ADSDSOObject', 'adsdatasource'
-- EXEC sp_addlinkedsrvlogin 'ADSI', 'false'



-- Usage <EXEC inADgroup ADgroup, userAccount>
-- Returns the user name if the userAccount is a direct or nested
-- member of the ADgroup.




create procedure [dbo].[inADgroup](@adgp char(200) , @uid char(20))
as
	SET NOCOUNT ON

declare @SQL nvarchar(4000) , @gpDN char(200)
declare @min int, @max int, @cnt int


-- Hold the groupDN and its nested group DNs in a temp table
CREATE TABLE #tmpCHKad( gpDN char(200) , id  INT IDENTITY (1, 1) NOT NULL )
SELECT @cnt=0



-- Write in the input group DN to temp table
SET 
@SQL='<LDAP://AD Domain>;(sAMAccountName=' + ltrim(rtrim(@adgp)) + ');distinguishedName;subtree' 
SET @SQL= 'INSERT INTO #tmpCHKad SELECT * FROM OpenQuery(ADSI,''' +  @SQL + ''')' 
EXEC sp_executesql @SQL
SELECT @min=1


-- Write in the 1st level
SELECT @gpDN = gpDN FROM #tmpCHKad
SET 		
@SQL='<LDAP://AD Domain>;(&(ObjectCategory=group)(memberOf=' + ltrim(rtrim(@gpDN)) + '));distinguishedName;subtree' 
SET @SQL='INSERT INTO #tmpCHKad SELECT * FROM OpenQuery(ADSI,''' + @SQL + ''')'
EXEC sp_executesql @SQL
SELECT @max = @@IDENTITY


-- Write in 2nd level +
WHILE (@max > @min )  
	BEGIN

	DECLARE gp_curs CURSOR FOR
	SELECT gpDN FROM #tmpCHKad WHERE id >@min and id <=@max
	OPEN gp_curs
	FETCH NEXT FROM gp_curs INTO @gpDN

	WHILE (@@FETCH_STATUS=0)
	    BEGIN
		SET 
		@SQL='<LDAP://AD Domain>;(&(ObjectCategory=group)(memberOf=' + ltrim(rtrim(@gpDN)) + '));distinguishedName;subtree' 
		SET @SQL='INSERT INTO #tmpCHKad SELECT * FROM OpenQuery(ADSI,''' + @SQL + ''')'
		EXEC sp_executesql @SQL
		FETCH NEXT FROM gp_curs INTO @gpDN		
	END
	SELECT @min=@max
	SELECT @max = @@IDENTITY
	CLOSE gp_curs
	DEALLOCATE gp_curs


END


-- Now that we have all the group DNs in the table, check if the input uid is a member of any of the group
-- Write in uid fiull name in a temp table: calling this from Apps will return the records.
-- ADSI behaves differently from SQL querry analyzer and any apps.
 CREATE TABLE #tmpCHKad2( uname char(100) )



-- Loop thru 1st temp table and build 2nd temp table
DECLARE chkgp_curs CURSOR FOR
	SELECT gpDN from #tmpCHKad
OPEN chkgp_curs
FETCH NEXT FROM chkgp_curs INTO @gpDN

WHILE (@@FETCH_STATUS=0)
	BEGIN

	SET 
	@SQL='<LDAP://AD Domain>;(&(ObjectCategory=user)(sAMAccountName='+ltrim(rtrim(@uid)) + ')(memberOf=' + ltrim(rtrim(@gpDN)) + '));name;subtree' 
	SET @SQL='INSERT INTO #tmpCHKad2 SELECT name FROM OpenQuery(ADSI,''' + @SQL + ''')'
	EXEC sp_executesql @SQL
	SELECT @cnt=@@ROWCOUNT

	IF (@CNT > 0)
		BREAK

	FETCH NEXT FROM chkgp_curs INTO @gpDN

END
CLOSE chkgp_curs
DEALLOCATE chkgp_curs


-- Select from 2nd temp table
SELECT uname FROM #tmpCHKad2



