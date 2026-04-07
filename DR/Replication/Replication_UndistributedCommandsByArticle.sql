use distribution
go  
SELECT 
  ps.srvname as 'Publisher',
  s.publisher_db as 'PublisherDB',
  ss.srvname as 'Subscriber',  
  s.subscriber_db as 'SubscriberDB',
  a.source_owner as 'Schema',
  a.source_object as 'Object',
  SUM(CASE WHEN xact_seqno > h.maxseq THEN 1 ELSE 0 END) as 'UndeliveredCommands'
FROM dbo.MSrepl_commands (NOLOCK) t  
JOIN dbo.MSsubscriptions (NOLOCK) s   
  ON t.article_id = s.article_id 
  AND t.publisher_database_id=s.publisher_database_id  
JOIN (SELECT agent_id,'maxseq'= isnull(max(xact_seqno),0x0) FROM dbo.MSdistribution_history (NOLOCK) GROUP BY agent_id) h  
  ON h.agent_id=s.agent_id
JOIN dbo.MSarticles (NOLOCK) a
  ON a.article_id = t.article_id
  AND a.publication_id = s.publication_id
JOIN dbo.MSPublications (NOLOCK) p
  on p.publication_id =  s.publication_id
  AND p.publication_type <> 1 -- exclude snapshot replication
JOIN dbo.MSreplservers (NOLOCK) ps 
  ON p.publisher_id = ps.srvid 
JOIN dbo.MSreplservers (NOLOCK) ss 
  ON s.subscriber_id = ss.srvid 
GROUP BY ps.srvname,
  s.publisher_db,
  ss.srvname,  
  s.subscriber_db,
  a.source_owner,
  a.source_object
HAVING SUM(CASE WHEN xact_seqno > h.maxseq THEN 1 ELSE 0 END) > 0
ORDER BY SUM(CASE WHEN xact_seqno > h.maxseq THEN 1 ELSE 0 END) desc  

