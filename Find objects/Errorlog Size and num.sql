CREATE TABLE #error_log
(
    log_number INT,
    log_date DATE,
    log_size INT
);
INSERT #error_log ( log_number, log_date, log_size )
EXEC ( 'EXEC sys.sp_enumerrorlogs;' );

SELECT log_number, log_date, cast(log_size as decimal(12,2))/1024/1024 as log_size
FROM   #error_log AS el