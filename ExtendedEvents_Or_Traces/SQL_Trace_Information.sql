How to tell if there is a trace running:

Here is how you view the number of traces currently running:

    SELECT count(*) FROM :: fn_trace_getinfo(default) WHERE property = 5 and value = 1


Here is how you can find more detail about the running traces:

    SELECT * FROM :: fn_trace_getinfo(default)


You can terminate a trace with the 'sp_trace_setstatus' stored procedure using the traceid:

    EXEC sp_trace_setstatus 1, @status = 0
    EXEC sp_trace_setstatus 1, @status = 2

setting the status to 0 stops the trace
setting the status to 2 closes the trace and deletes its definition from the server