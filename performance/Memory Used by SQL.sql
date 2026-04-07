SELECT OBJECT_NAME, cntr_value/1024 as 'MBs used'
from master.dbo.sysperfinfo
where counter_name = 'Total Server Memory (KB)'
