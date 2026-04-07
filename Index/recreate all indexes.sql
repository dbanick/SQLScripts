--this will generate TSQL to create all indexes in a db

declare
@object_id int,
@index_id tinyint,
@schema_name sysname,
@table_name sysname,
@index_name sysname,
@type tinyint,
@uniqueness bit,
@indexed_column sysname,
@included_column sysname,
@indexed_columns varchar(max),
@included_columns varchar(max),
@has_included_cols bit,
@is_descending_key bit,
@stmt varchar(max),
@crlf char(2)

set @crlf = char(13) + char(10)

declare indexes cursor
for
select
schema_name = s.name,
table_name = t.name,
index_id = i.index_id,
index_name = i.name,
type = i.type,
uniqueness = i.is_unique
from
sys.schemas s
join sys.tables t on s.schema_id = t.schema_id
join sys.indexes i on t.object_id = i.object_id
where
i.type > 0 -- none -heap
order
by s.name,
t.name,
i.index_id

open indexes

fetch
indexes
into
@schema_name,
@table_name ,
@index_id ,
@index_name ,
@type ,
@uniqueness

while @@fetch_status<>(-1)
begin

select @object_id = object_id(@schema_name + '.' + @table_name)
set @indexed_columns = '('

declare indexed_columns cursor
for
select
c.name,
ic.is_descending_key
from
sys.index_columns ic
join sys.columns c on ic.column_id = c.column_id
and ic.object_id = c.object_id
where
ic.object_id = @object_id
and ic.index_id = @index_id
and ic.is_included_column = 0
order by
ic.index_column_id

open indexed_columns

fetch indexed_columns
into @indexed_column, @is_descending_key

while @@fetch_status<>(-1)
begin

set @indexed_columns = @indexed_columns + @indexed_column +
case @is_descending_key when 1 then ' desc ' else '' end + ', '

fetch indexed_columns
into @indexed_column, @is_descending_key

end

close indexed_columns
deallocate indexed_columns

set @indexed_columns = left(@indexed_columns, len(@indexed_columns)-1) + ')'

if exists
(select object_id
from sys.index_columns
where object_id = @object_id
and index_id = @index_id
and is_included_column = 1 )
begin
set @included_columns = 'include ('

declare included_columns cursor
for
select
c.name,
ic.is_descending_key
from
sys.index_columns ic
join sys.columns c on ic.column_id = c.column_id
and ic.object_id = c.object_id
where
ic.object_id = @object_id
and ic.index_id = @index_id
and ic.is_included_column = 1
order by
ic.index_column_id

open included_columns

fetch included_columns
into @included_column, @is_descending_key

while @@fetch_status<>(-1)
begin

set @included_columns = @included_columns + @included_column +
case @is_descending_key when 1 then ' desc ' else '' end + ', '

fetch included_columns
into @included_column, @is_descending_key

end

close included_columns
deallocate included_columns

set @included_columns = left(@included_columns, len(@included_columns)-1) + ')' + @crlf

end

set @stmt =
'create ' +
case @uniqueness when 1 then 'unique ' else '' end +
case @type when 1 then 'clustered ' else '' end +
'index ' + @index_name + @crlf +
'on ' + @schema_name + '.' + @table_name + @indexed_columns + @crlf +
isnull(@included_columns,'') +
'g' + 'o' + @crlf + @crlf

print @stmt

fetch
indexes
into
@schema_name,
@table_name ,
@index_id ,
@index_name ,
@type ,
@uniqueness

end

close indexes
deallocate indexes