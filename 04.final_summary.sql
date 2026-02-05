--Final Summary
WITH downtime_summary AS (
    SELECT
        m.machine_id,
        m.machine_name,
        SUM(EXTRACT(EPOCH FROM (d.end_time - d.start_time)) / 60) AS total_downtime_minutes
    FROM downtime_log d
    JOIN machine_master m
      ON d.machine_id = m.machine_id
    GROUP BY m.machine_id, m.machine_name
),

-- 2. MTBF per machine
mtbf_summary AS (
    WITH failure_intervals AS (
        SELECT
            ml.machine_id,
            ml.failure_date::timestamp AS failure_ts,
            LAG(ml.failure_date::timestamp) OVER (
                PARTITION BY ml.machine_id ORDER BY ml.failure_date
            ) AS prev_failure_ts
        FROM maintenance_log ml
    )
    SELECT
        m.machine_id,
        ROUND(AVG(EXTRACT(EPOCH FROM (failure_ts - prev_failure_ts)) / 3600), 2) AS mtbf_hours
    FROM failure_intervals f
    JOIN machine_master m
      ON f.machine_id = m.machine_id
    WHERE prev_failure_ts IS NOT NULL
    GROUP BY m.machine_id
),

-- 3. MTTR per machine
mttr_summary AS (
    SELECT
        m.machine_id,
        ROUND(AVG(EXTRACT(EPOCH FROM (ml.repair_end - ml.repair_start)) / 60), 2) AS mttr_minutes
    FROM maintenance_log ml
    JOIN machine_master m
      ON ml.machine_id = m.machine_id
    GROUP BY m.machine_id
),

-- 4. Machine summary for At-Risk status
machine_summary AS (
    SELECT
        p.machine_id,
        m.machine_name,
        SUM(p.produced_qty) AS total_production,
        SUM(CASE WHEN d.is_planned = FALSE 
                 THEN EXTRACT(EPOCH FROM (d.end_time - d.start_time)) / 60
                 ELSE 0 END) AS unplanned_downtime
    FROM production_log p
    LEFT JOIN downtime_log d
      ON p.machine_id = d.machine_id
      AND DATE_TRUNC('day', p.production_date) = DATE_TRUNC('day', d.downtime_date)
    JOIN machine_master m
      ON p.machine_id = m.machine_id
    GROUP BY p.machine_id, m.machine_name
),

-- 5. Calculate percentile thresholds for risk
thresholds AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_production) AS prod_25,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY total_production) AS prod_50,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY unplanned_downtime) AS downtime_75,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY unplanned_downtime) AS downtime_50
    FROM machine_summary
),

-- 6. Final At-Risk status per machine
risk_summary AS (
    SELECT
        ms.machine_id,
        CASE
            WHEN ms.unplanned_downtime >= t.downtime_75
                 OR ms.total_production <= t.prod_25 THEN 'High Risk'
            WHEN ms.unplanned_downtime >= t.downtime_50
                 OR ms.total_production <= t.prod_50 THEN 'Medium Risk'
            ELSE 'Normal'
        END AS status
    FROM machine_summary ms
    CROSS JOIN thresholds t
)

-- 7. Combine everything into the final summary
SELECT
    m.machine_name,
    COALESCE(ds.total_downtime_minutes,0) AS total_downtime_minutes,
    COALESCE(mt.mtbf_hours,0) AS mtbf_hours,
    COALESCE(tr.mttr_minutes,0) AS mttr_minutes,
    COALESCE(rs.status,'Normal') AS machine_status
FROM machine_master m
LEFT JOIN downtime_summary ds
  ON m.machine_id = ds.machine_id
LEFT JOIN mtbf_summary mt
  ON m.machine_id = mt.machine_id
LEFT JOIN mttr_summary tr
  ON m.machine_id = tr.machine_id
LEFT JOIN risk_summary rs
  ON m.machine_id = rs.machine_id
ORDER BY machine_status DESC, total_downtime_minutes DESC;