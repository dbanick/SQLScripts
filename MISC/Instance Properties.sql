Declare @Owners varchar(300), @cluster varchar(1), @crkey varchar(300), @crkey1 varchar(300)
set @cluster = (Select CAST(SERVERPROPERTY('IsClustered') as varchar(2)))
If 	@cluster = 1
		Begin	
			create table #t1 (col1 varchar(4000))
			insert into #t1 select NodeName+',' from sys.dm_os_cluster_nodes

			set @Owners = ''
			declare crkeycursor CURSOR for SELECT col1 FROM #t1
			Open crkeycursor

			Fetch next from crkeycursor
			into @crkey

			WHILE @@FETCH_STATUS = 0
				BEGIN 
					set @Owners = @Owners+' '+@crkey
			


			Fetch next from crkeycursor
			into @crkey
			end
			CLOSE crkeycursor
			DEALLOCATE crkeycursor	

		set @Owners = (select substring(@Owners,1,len(@Owners)-1))
		--select @Owners 
		drop table #t1
		End
  else
	set @Owners = (select CAST(serverproperty('ComputerNamePhysicalNetBIOS') as varchar(200)))

DECLARE @test varchar(200), 
	@key varchar(100),
	@TcpPortKey varchar(300),
	@keyhome varchar(400),
	@servicehome varchar(400),
	@TcpEnabledKey varchar(100),
	@port varchar(6)

		SET @key = (SELECT @@servicename)
		SET @servicehome = 'SYSTEM\CurrentControlSet\Services'
		SET @keyhome = 'SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL'
		
		EXEC master..xp_regread @rootkey='HKEY_LOCAL_MACHINE',@key=@keyhome,@value_name=@key,@value=@test OUTPUT
		SET @keyhome = (SELECT convert(varchar(400),@test) as ServiceName)
		SET @keyhome = 'SOFTWARE\Microsoft\Microsoft SQL Server\'+ @keyhome
		SET @TcpEnabledKey = @keyhome + '\MSSQLServer\Supersocketnetlib\TCP'
		SET @TcpPortKey = @TcpEnabledKey + '\IPAll'
		
		--Port #
		EXEC master..xp_regread @rootkey='HKEY_LOCAL_MACHINE',@key=@TcpPortKey,@value_name='TcpPort',@value=@test OUTPUT
		SET @port = (SELECT convert(varchar(10),@test) as Port)
		IF @port is NULL
			EXEC master..xp_regread @rootkey='HKEY_LOCAL_MACHINE',@key=@TcpPortKey,@value_name='TcpDynamicPorts',@value=@test OUTPUT
		SET @port = (SELECT convert(varchar(10),@test) as Port)


SELECT @@SERVERNAME as 'ServerName', SERVERPROPERTY('MachineName') AS [Machine Name],
SERVERPROPERTY('InstanceName') AS [Instance], 
@port as 'Port #',
SERVERPROPERTY('IsClustered') AS [Is Clustered], 
@Owners as 'Instance Owners',
substring(@@VERSION,1,25) as 'SQLVersion',
SERVERPROPERTY('Edition') AS [Edition], SERVERPROPERTY('ProductLevel') AS [Product Level], 
SERVERPROPERTY('ProductVersion') AS [Product Version],
SERVERPROPERTY('IsHadrEnabled') AS [Is HADR Enabled],SERVERPROPERTY('HadrManagerStatus') AS [HADR Manager Status];