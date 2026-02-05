SELECT * FROM machine_master;
SELECT * FROM production_log LIMIT 20;
SELECT * FROM downtime_log LIMIT 20;
SELECT * FROM maintenance_log LIMIT 20;


SELECT
    p.machine_id,
    m.machine_name,
    p.production_date,
    p.shift,
    p.produced_qty
FROM production_log p
JOIN machine_master m
  ON p.machine_id = m.machine_id
LIMIT 20;

SELECT machine_id, SUM(produced_qty)
FROM production_log
GROUP BY machine_id;

SELECT
    DATE_TRUNC('month', production_date),
    SUM(produced_qty)
FROM production_log
GROUP BY 1;

SELECT machine_id, COUNT(*)
FROM downtime_log
GROUP BY machine_id;

---Active days per machine per machine
WITH daily_activity AS (
    SELECT
        machine_id,
        DATE_TRUNC('month', production_date) AS month,
        COUNT(DISTINCT production_date) AS active_days
    FROM production_log
    GROUP BY machine_id, DATE_TRUNC('month', production_date)
)
SELECT
    m.machine_name,
    d.month,
    d.active_days
FROM daily_activity d
JOIN machine_master m ON d.machine_id = m.machine_id
ORDER BY m.machine_name, d.month;

--Monthly Utilization (% of run time)
WITH monthly_runtime AS (
    SELECT
        machine_id,
        DATE_TRUNC('month', production_date) AS month,
        SUM(run_time_minutes) AS total_run_time,
        SUM(planned_qty * 60) AS planned_time_minutes  -- assuming planned_qty correlates to planned run time
    FROM production_log
    GROUP BY machine_id, DATE_TRUNC('month', production_date)
)
SELECT
    m.machine_name,
    mr.month,
    ROUND((total_run_time::NUMERIC / planned_time_minutes) * 100, 2) AS utilization_percent
FROM monthly_runtime mr
JOIN machine_master m ON mr.machine_id = m.machine_id
ORDER BY m.machine_name, mr.month;

--Toyal downtime per machine
SELECT
    m.machine_name,
    SUM(EXTRACT(EPOCH FROM (d.end_time - d.start_time)) / 60) AS total_downtime_minutes
FROM downtime_log d
JOIN machine_master m
  ON d.machine_id = m.machine_id
GROUP BY m.machine_name
ORDER BY total_downtime_minutes DESC;

--Planned VS Unplanned downtime
SELECT
    m.machine_name,
    SUM(CASE 
		WHEN d.is_planned THEN EXTRACT(EPOCH FROM (d.end_time - d.start_time)) / 60 
		ELSE 0 
	END) AS planned_minutes,
    SUM(CASE
		WHEN NOT d.is_planned THEN EXTRACT(EPOCH FROM (d.end_time - d.start_time)) / 60
		ELSE 0
	END) AS unplanned_minutes
FROM downtime_log d
JOIN machine_master m
  ON d.machine_id = m.machine_id
GROUP BY m.machine_name
ORDER BY unplanned_minutes DESC;

--Downtime by reason
SELECT
    downtime_reason,
    COUNT(*) AS occurrences,
    SUM(EXTRACT(EPOCH FROM (end_time - start_time)) / 60) AS total_minutes
FROM downtime_log
GROUP BY downtime_reason
ORDER BY total_minutes DESC;

--Downtime Per Month
SELECT
    DATE_TRUNC('month', downtime_date) AS month,
    SUM(EXTRACT(EPOCH FROM (end_time - start_time)) / 60) AS monthly_downtime_minutes
FROM downtime_log
GROUP BY month
ORDER BY month;

--MTBF per machine
WITH failure_intervals AS (
    SELECT
        ml.machine_id,
        ml.failure_date::timestamp AS failure_ts,
        LAG(ml.failure_date::timestamp) OVER (
            PARTITION BY ml.machine_id 
            ORDER BY ml.failure_date
        ) AS prev_failure_ts
    FROM maintenance_log ml
)
SELECT
    m.machine_name,
    ROUND(
        AVG(EXTRACT(EPOCH FROM (failure_ts - prev_failure_ts)) / 3600),
        2
    ) AS mtbf_hours
FROM failure_intervals f
JOIN machine_master m
  ON f.machine_id = m.machine_id
WHERE prev_failure_ts IS NOT NULL
GROUP BY m.machine_name
ORDER BY mtbf_hours DESC;

--MTTR per machine
SELECT
    m.machine_name,
    ROUND(
        AVG(EXTRACT(EPOCH FROM (ml.repair_end::timestamp - ml.repair_start::timestamp)) / 60),
        2
    ) AS mttr_minutes
FROM maintenance_log ml
JOIN machine_master m
  ON ml.machine_id = m.machine_id
GROUP BY m.machine_name
ORDER BY mttr_minutes DESC;

--Total peoduction per shift
SELECT
    p.shift,
    m.machine_name,
    SUM(p.produced_qty) AS total_production
FROM production_log p
JOIN machine_master m
  ON p.machine_id = m.machine_id
GROUP BY p.shift, m.machine_name
ORDER BY p.shift, total_production DESC;

--Total downtime per machine
SELECT
    m.machine_name,
    SUM(EXTRACT(EPOCH FROM (d.end_time - d.start_time)) / 60) AS total_downtime_minutes
FROM downtime_log d
JOIN machine_master m
  ON d.machine_id = m.machine_id
GROUP BY  m.machine_name
ORDER BY total_downtime_minutes DESC;

--Production VS Downtime Correlation 
WITH monthly_summary AS (
    SELECT
        p.machine_id,
        DATE_TRUNC('month', p.production_date) AS month,
        SUM(p.produced_qty) AS total_production,
        SUM(EXTRACT(EPOCH FROM COALESCE(d.end_time, p.production_date::timestamp) - COALESCE(d.start_time, p.production_date::timestamp)) / 60) AS downtime_minutes
    FROM production_log p
    LEFT JOIN downtime_log d
      ON p.machine_id = d.machine_id
      AND DATE_TRUNC('day', p.production_date) = DATE_TRUNC('day', d.downtime_date)
    GROUP BY p.machine_id, month
)
SELECT
    m.machine_name,
    month,
    total_production,
    downtime_minutes,
    ROUND(downtime_minutes / NULLIF(total_production,0), 2) AS downtime_per_unit
FROM monthly_summary ms
JOIN machine_master m
  ON ms.machine_id = m.machine_id
ORDER BY month, machine_name;

--Downtime Reason Trends
SELECT
    DATE_TRUNC('month', downtime_date) AS month,
    downtime_reason,
    COUNT(*) AS occurrences,
    SUM(EXTRACT(EPOCH FROM (end_time - start_time)) / 60) AS total_minutes
FROM downtime_log
GROUP BY month, downtime_reason
ORDER BY month, total_minutes DESC;

--At risk machines
WITH machine_summary AS (
    SELECT
        p.machine_id,
        m.machine_name,
        DATE_TRUNC('month', p.production_date) AS month,
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
    GROUP BY p.machine_id, m.machine_name, month
)
SELECT
    machine_name,
    month,
    total_production,
    unplanned_downtime,
    CASE
        WHEN unplanned_downtime > 40 OR total_production < 70 THEN 'High Risk'
        WHEN unplanned_downtime > 20 OR total_production < 100 THEN 'Medium Risk'
        ELSE 'Normal'
    END AS status
FROM machine_summary
ORDER BY status DESC, machine_name;

----Machine Cohort Analysis 
WITH machine_cohort AS (
    SELECT
        m.machine_id,
        m.machine_name,
        m.install_date,
        DATE_TRUNC('month', p.production_date) AS month,
        SUM(p.produced_qty) AS total_production,
        SUM(EXTRACT(EPOCH FROM (COALESCE(d.end_time, p.production_date::timestamp) - COALESCE(d.start_time, p.production_date::timestamp))) / 60) AS downtime_minutes
    FROM machine_master m
    LEFT JOIN production_log p
      ON m.machine_id = p.machine_id
    LEFT JOIN downtime_log d
      ON m.machine_id = d.machine_id
      AND DATE_TRUNC('day', p.production_date) = DATE_TRUNC('day', d.downtime_date)
    GROUP BY m.machine_id, m.machine_name, m.install_date, month
)
SELECT
    machine_name,
    install_date,
    month,
    total_production,
    downtime_minutes,
    ROUND(total_production / NULLIF(downtime_minutes,0), 2) AS efficiency_ratio
FROM machine_cohort
ORDER BY install_date, month;

