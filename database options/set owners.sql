select name, 'ALTER AUTHORIZATION ON DATABASE::' + name + ' TO sa', owner_sid  from sys.databases
where owner_sid != '0x01'
