--check for hypothetical indexes in this database. This will generate commands to drop them but doesn't execute the drop

SELECT  OBJECT_NAME(object_id), 'DROP INDEX ' + OBJECT_NAME(object_id) + '.' + name, *
FROM    sys.indexes
WHERE   is_hypothetical = 1
--and OBJECT_NAME(object_id) like 'SOP%'
order by 1 desc
