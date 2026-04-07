--Checks to see if read only routing is configured

select @@servername

SELECT ag.name AS availability_group_name,

 r.replica_server_name AS when_primary_replica_is,

 rorl.routing_priority,

 r2.replica_server_name AS secondary_replica_name,

 r2.secondary_role_allow_connections_desc AS read_only_replica_secondary_role_allow_connections_desc,

 r2.availability_mode_desc AS read_only_replica_replica_availability_mode,

 r2.failover_mode_desc AS read_only_replica_replica_failover_mode,

 r2.read_only_routing_url AS replica_read_only_routing_url

FROM sys.availability_groups ag

INNER JOIN sys.availability_replicas r ON ag.group_id = r.group_id

LEFT OUTER JOIN sys.availability_read_only_routing_lists rorl ON r.replica_id = rorl.replica_id

LEFT OUTER JOIN sys.availability_replicas r2 ON rorl.read_only_replica_id = r2.replica_id

ORDER BY ag.name, r.replica_server_name, rorl.routing_priority