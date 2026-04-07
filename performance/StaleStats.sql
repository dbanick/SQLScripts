SELECT 
    s.[name] AS StatsName,
    o.[name] AS TableName,
    i.rowmodctr AS RowModifications,
    p.[rows] AS [RowCount],
    cast(i.rowmodctr * 1.0 / p.[rows] as decimal(18,2)) AS ModificationRatio,
    CASE 
        WHEN i.rowmodctr > (p.[rows] * 0.20 + 500) THEN 'Likely Stale'
        ELSE 'Likely OK'
    END AS Status
FROM 
    sys.stats AS s
    INNER JOIN sys.objects AS o ON s.object_id = o.object_id
    INNER JOIN sys.sysindexes AS i ON s.object_id = i.id AND s.stats_id = i.indid
    INNER JOIN (
        SELECT 
            ps.object_id, 
            SUM(ps.rows) AS [rows]
        FROM 
            sys.partitions AS ps
        WHERE 
            ps.index_id IN (0, 1)
        GROUP BY 
            ps.object_id
    ) AS p ON s.object_id = p.object_id
WHERE 
    o.type = 'U' -- user tables only
	and p.rows > 100
ORDER BY 
    ModificationRatio DESC;
