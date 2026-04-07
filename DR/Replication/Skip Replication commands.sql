use distribution -- The following needs to be executed in the distribution database
go

/*******************************************************************************************************************/
/* To detemine where it failed                                                                                     */
/*  you need the starting transaction log sequence number of the failed execution batch(xact_seqno) and command_ID */
/*******************************************************************************************************************/


exec sp_helpsubscriptionerrors  
	   @publisher =  'pub'			-- Instance Name of the Publisher
        ,  @publisher_db =  'pub'		-- Database Name on the Publisher
        ,  @publication =  'pub'		-- Publication Name
        ,  @subscriber =  'sub'			-- Instance Name of the Subscriber
        ,  @subscriber_db =  'sub'	-- Database Name on Subscriber
 

-- Get command that was running and look for the command_ID from sp_helpsubscriptionerrors
 
use distribution
exec sp_browsereplcmds 
           @xact_seqno_start = '0x0011546D00017599001B00000000'  -- Replace with xact_seqno column from sp_helpsubscriptionerrors
         , @xact_seqno_end = '0x0011546D00017599001B00000000'	 -- Replace with xact_seqno column from sp_helpsubscriptionerrors


-- To skip a replication command. ** TO ONLY BE PERFORMED BY SR. DBA. **

/*
-- This must be ran on the subscription database on the subscriber instance
-- *Note* the @xact_seqno cannot have quotes around it in this section, unlike the previous sections


use subscriber_db
exec sp_setsubscriptionxactseqno
	 @publisher = 'pub'				-- Instance Name of the Publisher
	,@publisher_db = 'pub'			-- Database Name on the Publisher
	,@publication = 'pub'			-- Publication Name
	,@xact_seqno = 0x0011546D00017599001B00000000	-- Replace with xact_seqno column from sp_helpsubscriptionerrors

*/