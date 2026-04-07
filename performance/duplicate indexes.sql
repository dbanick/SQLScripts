/*
The first query finds exact matches. The indexes must have the same key columns in the same order, and the same included columns but in any order. These indexes are sure targets for elimination. The only caution would be to check for index hints. 
*/
 
-- exact duplicates
with indexcols as
(
select object_id as id, index_id as indid, name,
(select case keyno when 0 then NULL else colid end as [data()]
from sys.sysindexkeys as k
where k.id = i.object_id
and k.indid = i.index_id
order by keyno, colid
for xml path('')) as cols,
(select case keyno when 0 then colid else NULL end as [data()]
from sys.sysindexkeys as k
where k.id = i.object_id
and k.indid = i.index_id
order by colid
for xml path('')) as inc
from sys.indexes as i
)
select
object_schema_name(c1.id) + '.' + object_name(c1.id) as 'table',
c1.name as 'index',
c2.name as 'exactduplicate'
from indexcols as c1
join indexcols as c2
on c1.id = c2.id
and c1.indid < c2.indid
and c1.cols = c2.cols
and c1.inc = c2.inc;
 
/*
The second variation of this query finds partial, or duplicate, indexes that share leading key columns, e.g. Ix1(col1, col2, col3) and Ix2(col1, col2) would be considered duplicate indexes. This query only examines key columns and does not consider included columns.
These types of indexes are probable dead indexes walking.
*/

-- Overlapping indxes
with indexcols as
(
select object_id as id, index_id as indid, name,
(select case keyno when 0 then NULL else colid end as [data()]
from sys.sysindexkeys as k
where k.id = i.object_id
and k.indid = i.index_id
order by keyno, colid
for xml path('')) as cols
from sys.indexes as i
)
select
object_schema_name(c1.id) + '.' + object_name(c1.id) as 'table',
c1.name as 'index',
c2.name as 'partialduplicate'
from indexcols as c1
join indexcols as c2
on c1.id = c2.id
and c1.indid < c2.indid
and (c1.cols like c2.cols + '%'
or c2.cols like c1.cols + '%') ;