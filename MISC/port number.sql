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

select @@SERVERNAME as ServerName, @port as port