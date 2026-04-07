 -- Page Life Expectancy (PLE) value for default instance
SELECT cntr_value AS[Page Life Expectancy]
FROM sys.dm_os_performance_counters
WHERE OBJECT_NAME = N'SQLServer:Buffer Manager'-- Modify this if you have named instances
AND counter_name = N'Page life expectancy';
-- PLE is a good measurement of memory pressure.
-- Higher PLE is better. Below 300 is generally bad.
-- Watch the trend, not the absolute value.