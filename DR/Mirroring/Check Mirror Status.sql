select @@servername as instance,
db_name(database_id) as 'DBName', 
mirroring_state_desc, 
mirroring_role_desc, 
mirroring_partner_Instance, 
mirroring_witness_name,
mirroring_witness_state_desc,
mirroring_connection_timeout
from master.sys.database_mirroring 
where mirroring_role_desc != 'NULL'