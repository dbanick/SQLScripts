--To add an article without making a snapshot of all other articles (generate snapshot only for the new one)

--Enable these options:
EXEC sp_changepublication
  @publication = 'MainPub',
  @property = N'allow_anonymous',
  @value = 'false'
GO

EXEC sp_changepublication
  @publication = 'MainPub',
  @property = N'immediate_sync',
  @value = 'false'
GO 

--Add article via T-SQL
sp_addarticle

--Refresh subscriptions
sp_refreshsubscriptions

-- Generate snapshot