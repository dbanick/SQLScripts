--return SSIS Package information from 2005 & 2008
use msdb 
declare @rootLabel sysname
declare @separatorChar varchar(200)
declare @SEARCH_STRING varchar(200)
SET @rootLabel = 'Analytics'
SET @separatorChar = '\'
set @SEARCH_STRING = 'Assimilation'

;with ChildFolders
as (
    select 
        PARENT.parentfolderid, 
        PARENT.folderid,
        PARENT.foldername,
        cast(@RootLabel as sysname) as RootFolder,
        cast(CASE 
            WHEN (LEN(PARENT.foldername) = 0) THEN @SeparatorChar 
            ELSE PARENT.foldername 
        END as varchar(max)) as FullPath,
        0 as Lvl
    from msdb.dbo.sysssispackagefolders PARENT
    where PARENT.parentfolderid is null
    UNION ALL
    select 
        CHILD.parentfolderid, CHILD.folderid, CHILD.foldername,
        case ChildFolders.Lvl
            when 0 then CHILD.foldername
            else ChildFolders.RootFolder
        end as RootFolder,
        cast(
            CASE WHEN (ChildFolders.FullPath = @SeparatorChar) THEN '' 
                ELSE ChildFolders.FullPath 
            END + @SeparatorChar + CHILD.foldername as varchar(max)
        ) as FullPath,
        ChildFolders.Lvl + 1 as Lvl
    from msdb.dbo.sysssispackagefolders CHILD
    inner join ChildFolders 
    on ChildFolders.folderid = CHILD.parentfolderid
)
Select
    CONVERT(NVARCHAR(50),P.id) As PackageId,
    F.RootFolder,
    F.FullPath,
    SUSER_SNAME(ownersid) as PackageOwner,
    P.name as PackageName,
    P.[description] as PackageDescription,
    P.isencrypted as isEncrypted,
    CASE P.packageformat
        WHEN 0 THEN '2005'
        WHEN 1 THEN '2008'
        ELSE 'N/A'
    END AS PackageFormat,
    CASE P.packagetype
        WHEN 0 THEN 'Default Client'
        WHEN 1 THEN 'SQL Server Import and Export Wizard'
        WHEN 2 THEN 'DTS Designer in SQL Server 2000'
        WHEN 3 THEN 'SQL Server Replication'
        WHEN 5 THEN 'SSIS Designer'
        WHEN 6 THEN 'Maintenance Plan Designer or Wizard'
        ELSE 'Unknown'
    END as PackageType,
    P.createdate as CreationDate,
    P.vermajor,
    P.verminor,
    P.verbuild,
    P.vercomments,
	(
     DATALENGTH(CONVERT(NVARCHAR(MAX),cast(cast(P.packagedata as varbinary(max)) as xml),0)) 
     - DATALENGTH(REPLACE(CONVERT(NVARCHAR(MAX),cast(cast(P.packagedata as varbinary(max)) as xml),0),@SEARCH_STRING,N''))
     ) / DATALENGTH(@SEARCH_STRING)                                                     AS INSTANCE_COUNT
   ,CHARINDEX(@SEARCH_STRING,CONVERT(NVARCHAR(MAX),cast(cast(P.packagedata as varbinary(max)) as xml),0),1)                      AS FIRST_POS_CHARINDEX
   ,PATINDEX(NCHAR(37) + @SEARCH_STRING + NCHAR(37),CONVERT(NVARCHAR(MAX),cast(cast(P.packagedata as varbinary(max)) as xml),0)) AS FIRST_POS_PATINDEX,
    DATALENGTH(P.packagedata) /1024 AS PackageSizeKb,
    cast(cast(P.packagedata as varbinary(max)) as xml) as PackageData
from ChildFolders F
inner join msdb.dbo.sysssispackages P 
on P.folderid = F.folderid
--return only packages that match search string
where (
     DATALENGTH(CONVERT(NVARCHAR(MAX),cast(cast(P.packagedata as varbinary(max)) as xml),0)) 
     - DATALENGTH(REPLACE(CONVERT(NVARCHAR(MAX),cast(cast(P.packagedata as varbinary(max)) as xml),0),@SEARCH_STRING,N''))
     ) / DATALENGTH(@SEARCH_STRING) > 0
order by F.FullPath asc, P.name asc
; 

