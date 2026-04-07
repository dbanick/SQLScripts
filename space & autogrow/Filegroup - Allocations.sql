SELECT * 
FROM sys.allocation_units AS AU
JOIN sys.filegroups AS F 
ON AU.data_space_id = F.data_space_id
where f.name = 'Abshire_CRMAttachment_BgConsent' --replace with filegroup name
ORDER BY F.name;