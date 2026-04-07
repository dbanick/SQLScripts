declare
@schema sysname,
@table sysname,
@index sysname,
@stmt varchar(max)

declare indexes cursor
for
select
s.name,
t.name,
i.name
from
sys.schemas s
join sys.tables t on t.schema_id = s.schema_id
join sys.indexes i on t.object_id = i.object_id
--where
--s.name = 'piza'
--and t.name = 'prospect'

open indexes

fetch indexes
into @schema,
@table,
@index

while @@fetch_status<>(-1)
begin

set @stmt = 'drop index ' + @schema + '.' + @table + '.' + @index

print @stmt

fetch indexes
into @schema,
@table,
@index

end

close indexes
deallocate indexes