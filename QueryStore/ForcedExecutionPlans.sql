SELECT TOP 1000
    p.query_id,
    p.plan_id,
    p.last_force_failure_reason_desc,
    p.force_failure_count,
    p.last_compile_start_time,
    p.last_execution_time,
    q.last_bind_duration,
    q.query_parameterization_type_desc,
    q.context_settings_id,
    c.set_options,
    c.STATUS
FROM sys.query_store_plan p
INNER JOIN sys.query_store_query q
    ON p.query_id = q.query_id
INNER JOIN sys.query_context_settings c
    ON c.context_settings_id = q.context_settings_id
LEFT JOIN sys.query_store_query_text t
    ON q.query_text_id = t.query_text_id
WHERE p.is_forced_plan = 1
    AND p.last_force_failure_reason != 0;