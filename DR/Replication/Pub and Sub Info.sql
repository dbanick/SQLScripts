SELECT distinct srv.name publication_server, p.publisher_db, p.publication as publication_name,p.publication_type, 
ss.name as subscription_server, s.subscriber_db, da.subscription_type  
FROM MSpublications p  JOIN MSsubscriptions s ON p.publication_id = s.publication_id  
JOIN sys.servers ss ON s.subscriber_id = ss.server_id  JOIN sys.servers srv ON srv.server_id = p.publisher_id  
JOIN MSdistribution_agents da ON da.publisher_id = p.publisher_id  AND da.subscriber_id = s.subscriber_id
UNION
SELECT distinct srv.name publication_server, p.publisher_db, p.publication as publication_name,p.publication_type, 
coalesce(ss.name, s.subscriber) as subscription_server, 
s.subscriber_db, s.subscription_type as subscription_type
FROM MSpublications p  JOIN MSmerge_subscriptions s ON p.publication_id = s.publication_id  
left JOIN sys.servers ss ON s.subscriber_id = ss.server_id  
JOIN sys.servers srv ON srv.server_id = p.publisher_id