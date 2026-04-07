--To hide the replcation SP's, execute the query returned by this.
--To revert the changes, find the comment below labeled <Action> and change the variable form @cmd1 to @rollback
DECLARE @cmd1 varchar(1000)
DECLARE @rollback varchar(1000)
DECLARE @cmd2 varchar(1500)
DECLARE @sp varchar (500)

SET @cmd1 = 'EXEC sp_addextendedproperty 
@name = N''microsoft_database_tools_support'', 
@value = ''<Hide? , sysname, 1>'', 
@level0type =''schema'', 
@level0name =''dbo'',  
@level1type = ''procedure'', 
@level1name = '

SET @rollback = 'EXEC sp_dropextendedproperty 
@name = N''microsoft_database_tools_support'', 
@level0type =''schema'', 
@level0name =''dbo'', 
@level1type = ''procedure'', 
@level1name = '  

DECLARE cur CURSOR
  FOR SELECT name FROM dbo.sysobjects  WHERE (type = 'P') and (name like 'sp_MSins_%' or name like 'sp_MSdel_%' or name like 'sp_MSupd_%')
OPEN cur
FETCH NEXT FROM cur into @sp;

WHILE @@FETCH_STATUS = 0  
    BEGIN  
		-- <Action>; Using @cmd1 will move the replication SP to System SP; changing it to @rollback will move it back with the user SP's
		SET @cmd2 = @cmd1 + '''' + @sp + ''''
		print @cmd2
		print 'GO'
    FETCH NEXT FROM cur   
    INTO @sp;
END   
CLOSE cur;  
DEALLOCATE cur;  


