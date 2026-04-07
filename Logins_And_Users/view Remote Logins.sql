 select a.srvname, b.remote_name from sysservers as a
JOIN sys.remote_logins as b on b.server_id=a.srvid
order by a.srvname