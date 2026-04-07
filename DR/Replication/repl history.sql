SELECT [agent_id]
,A.publication
      ,[runstatus]
      ,[start_time]
      ,[time]
      ,[duration]
      ,[comments]
      ,[xact_seqno]
      ,[current_delivery_rate]
      ,[current_delivery_latency]
      ,[delivered_transactions]
      ,[delivered_commands]
      ,[average_commands]
      ,[delivery_rate]
      ,[delivery_latency]
      ,[total_delivered_commands]
      ,[error_id]
      ,[updateable_row]
      ,[timestamp]
  FROM [distribution].[dbo].[MSdistribution_history]
join MSdistribution_agents A
on [MSdistribution_history].agent_id = A.id
order  by 4 desc