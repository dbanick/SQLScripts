USE SSISDB;
SET NOCOUNT ON;
IF object_id('tempdb..#DELETE_CANDIDATES') IS NOT NULL
BEGIN
    DROP TABLE #DELETE_CANDIDATES;
END;

CREATE TABLE #DELETE_CANDIDATES
(
    operation_id bigint NOT NULL PRIMARY KEY
);

DECLARE @DaysRetention int = 30;
INSERT INTO
    #DELETE_CANDIDATES
(
    operation_id
)
SELECT
    IO.operation_id
FROM
    internal.operations AS IO
WHERE
    IO.start_time < DATEADD(day, -@DaysRetention, CURRENT_TIMESTAMP);

DELETE top (100000) T
FROM
    internal.event_message_context AS T
    INNER JOIN
        #DELETE_CANDIDATES AS DC
        ON DC.operation_id = T.operation_id;

DELETE top (100000) T
FROM
    internal.event_messages AS T
    INNER JOIN
        #DELETE_CANDIDATES AS DC
        ON DC.operation_id = T.operation_id;

DELETE top (100000) T
FROM
    internal.operation_messages AS T
    INNER JOIN
        #DELETE_CANDIDATES AS DC
        ON DC.operation_id = T.operation_id;

-- etc
-- Finally, remove the entry from operations

/*
DELETE T
FROM
    internal.operations AS T
    INNER JOIN
        #DELETE_CANDIDATES AS DC
        ON DC.operation_id = T.operation_id;
*/