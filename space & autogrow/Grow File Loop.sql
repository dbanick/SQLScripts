/* Grow file in 8 GB Chunks */

declare @sizeint int = 0,
		@size nvarchar(6),
		@cmd nvarchar (2048)

while @sizeint < 24 -- set to max size GB
begin
	set @sizeint = @sizeint + 8
	set @size = convert(nvarchar(4),@sizeint) + N'GB';
	set @cmd = N'
	alter database DATABASE
	modify file (name = ''FILE'', size = '+ @size + N');'
	exec sp_executesql @cmd
end
