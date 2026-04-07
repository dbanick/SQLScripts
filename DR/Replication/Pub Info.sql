use distribution
go
select @@SERVERNAME as ServerName, DB_NAME() as Distribution_DB, publication, publication_id, publisher_db, publication_type, description from MSpublications
go
