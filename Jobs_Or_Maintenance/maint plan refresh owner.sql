
https://connect.microsoft.com/SQLServer/feedback/details/295846/job-owner-reverts-to-previous-owner-when-scheduled-maintenance-plan-is-edited#details 

update msdb.dbo.sysssispackages
set [ownersid] = suser_sid('<user name>')
where [name] in ('maint plan xxx'
, 'maint plan xxx'
)

 update [msdb].[dbo].[sysdtspackages90]
set [ownersid] = suser_sid('<user name>')
where [name] in ('maint plan xxx'
, 'maint plan xxx'
)