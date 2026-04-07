--create view [dbo].[VCommandLog] as
SELECT [ID],[DatabaseName],[SchemaName],[ObjectName]
      ,[ObjectType],[IndexName],[IndexType],[StatisticsName]
      ,[PartitionNumber],[ExtendedInfo],[Command]
      ,[CommandType],[StartTime],[EndTime]
      ,[ErrorNumber],[ErrorMessage]
   ,datediff(second,startTime,EndTime)  [DurationInSeconds]
   ,ExtendedInfo.value('(/ExtendedInfo/PageCount)[1]','bigint') as [pagecount]
   ,ExtendedInfo.value('(/ExtendedInfo/Fragmentation)[1]','numeric(7,5)') as [Fragmentation]
  FROM [dbo].[CommandLog]
WHERE CommandType = 'ALTER_INDEX' /* (DBCC_CHECKDB/UPDATE_STATISTICS/ALTER_INDEX) */
and StartTime >= '2022-07-09'
