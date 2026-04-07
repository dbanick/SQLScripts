use distribution -- The following needs to be executed in the distribution database
go

/*******************************************************************************************************************/
/* To detemine where it failed                                                                                     */
/*  you need the starting transaction log sequence number of the failed execution batch(xact_seqno) and command_ID */
/*******************************************************************************************************************/


exec sp_helpsubscriptionerrors  
	   @publisher =  'SQL-CL1-NY'			-- Instance Name of the Publisher
        ,  @publisher_db =  'DotNetNuke2'		-- Database Name on the Publisher
        ,  @publication =  'DNN2_FraudTables'		-- Publication Name
        ,  @subscriber =  'SQL-CL2-NY'			-- Instance Name of the Subscriber
        ,  @subscriber_db =  'FareportalReports'	-- Database Name on Subscriber
 

-- Get command that was running and look for the command_ID from sp_helpsubscriptionerrors
 
use distribution
exec sp_browsereplcmds 
           @xact_seqno_start = '0x0011546D00017599001B00000000'  -- Replace with xact_seqno column from sp_helpsubscriptionerrors
         , @xact_seqno_end = '0x0011546D00017599001B00000000'	 -- Replace with xact_seqno column from sp_helpsubscriptionerrors


-- To skip a replication command. ** TO ONLY BE PERFORMED BY WMT SQL. **
/*
-- This must be ran on the subscription database on the subscriber instance
-- *Note* the @xact_seqno cannot have quotes around it in this section, unlike the previous sections


use subscriber_db
exec sp_setsubscriptionxactseqno
	 @publisher = 'SQL-CL1-NY'				-- Instance Name of the Publisher
	,@publisher_db = 'DotNetNuke2'			-- Database Name on the Publisher
	,@publication = 'DNN2_FraudTables'			-- Publication Name
	,@xact_seqno = 0x0011546D00017599001B00000000	-- Replace with xact_seqno column from sp_helpsubscriptionerrors

*/