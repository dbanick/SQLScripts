sp_dropserver 'old_name'
go
sp_addserver 'new_name', 'local'
go

 ------------

sp_dropserver <'old_name\instancename'>
GO
sp_addserver <'new_name\instancename'>, local
GO