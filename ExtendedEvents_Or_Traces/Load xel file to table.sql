insert into CustomerData.dbo.XML_DATA --replace table name
select cast(event_data as xml)  --replace filepath
from fn_xe_file_target_read_file('C:\Deadlocks_0_131092843409680000\Deadlocks_0_131092843409680000.xel',NULL,NULL,NULL)
