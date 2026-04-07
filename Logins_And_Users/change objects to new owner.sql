//script to change all objects to new owner
SELECT 'EXEC(''sp_changeobjectowner @objname = '''''+ 
  ltrim(u.name) + '.' + ltrim(s.name) + '''''' 
  + ', @newowner = dbo'')'
FROM  sysobjects s, 
      sysusers u
WHERE s.uid = u.uid
AND   u.name <> 'dbo'
AND   xtype in ('V', 'P', 'U')
AND   u.name not like 'INFORMATION%'
order by s.name