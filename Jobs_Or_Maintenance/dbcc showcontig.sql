CREATE TABLE #Fragmentation(
  ObjectName varCHAR (255),
  ObjectId INT,
  IndexName varCHAR (255),
  IndexId INT,
  Level INT,
  Pages INT,
  Rows INT,
  MinimumRecordSize INT,
  MaximumRecordSize INT,
  AverageRecordSize DECIMAL,
  ForwardedRecords INT,
  Extents INT,
  ExtentSwitches INT,
  AverageFreeBytes INT,
  AvergePageDensity INT,
  ScanDensity DECIMAL,
  BestCount INT,
  ActualCount INT,
  LogicalFragmentation DECIMAL,
  ExtentFragmentation DECIMAL
)
GO


insert into #Fragmentation exec sp_executeSQL N'dbcc showcontig (''Table1'') with tableresults;'
insert into #Fragmentation exec sp_executeSQL N'dbcc showcontig (''Table2'') with tableresults;'

select * from #Fragmentation
drop table #Fragmentation