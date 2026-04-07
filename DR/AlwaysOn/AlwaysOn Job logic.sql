if (select
        ars.role_desc
    from sys.dm_hadr_availability_replica_states ars
    inner join sys.availability_groups ag
    on ars.group_id = ag.group_id
    where ag.name = 'YourAvailabilityGroupName'
    and ars.is_local = 1) = 'PRIMARY'
begin
    -- this server is the primary replica, do something here
end
else
begin
    -- this server is not the primary replica, (optional) do something here
end
