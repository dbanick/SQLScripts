--transaction log tools

--why won't it reuse the log
SELECT name, log_reuse_wait_desc , create_date, state_desc, recovery_model_desc FROM sys.databases
--where name = 'logtest'

-- how are all databases doing on log space
dbcc sqlperf(logspace)

-- how many VLF's are there
dbcc loginfo

