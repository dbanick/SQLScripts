--check external mail queue to see if it is backlogged or catching up
Use MSDB 
Select count(*) from ExternalMailQueue


--if service broker queue for mail is broke, you can enable with this:
use msdb 
--Alter queue ExternalMailQueue with status = on 


