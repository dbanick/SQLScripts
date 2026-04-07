sp_detach_db 'ben_test_db'

sp_attach_db  @dbname =  'ben_test_db',
@filename1 =  'C:\Program Files\Ben_test_db.mdf', 
@filename2 = 'C:\Program Files\Ben_test_db2.ndf',
@filename3 = 'C:\Program Files\ben_test_db_log.ldf'
   
