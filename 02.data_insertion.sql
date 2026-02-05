INSERT INTO machine_master
	(machine_name, machine_type, install_date, rated_capacity, loaction)
	VALUES
		('CNC_01', 'CNC', '2023-01-15', 120, 'Shop_Floor_1'),
		('CNC_02', 'CNC', '2023-03-10', 115, 'Shop_Floor_1'),
		('PRESS_01', 'Press', '2022-11-20', 200, 'Shop_Floor_2'),
		('PRESS_02', 'Press', '2023-06-05', 195, 'Shop_Floor_2'),
		('LATHE_01', 'Lathe', '2024-01-12', 90,  'Shop_Floor_3'),
		('LATHE_02', 'Lathe', '2024-02-18', 95,  'Shop_Floor_3'),
		('CONV_01', 'Conveyor', '2022-09-01', 300, 'Assembly'),
		('CONV_02', 'Conveyor', '2023-08-14', 310, 'Assembly'),
		('ROBOT_01', 'Robot', '2024-03-01', 150, 'Welding'),
		('ROBOT_02', 'Robot', '2024-04-10', 155, 'Welding');

INSERT INTO production_log
(machine_id, production_date, shift, produced_qty, planned_qty, run_time_minutes)
SELECT
    m.machine_id,
    d::DATE AS production_date,
    s.shift,
    (random()*20 + 80)::INT AS produced_qty,
    100 AS planned_qty,
    (random()*120 + 360)::INT AS run_time_minutes
FROM machine_master m
JOIN generate_series(
        DATE '2024-01-01',
        DATE '2024-06-30',
        INTERVAL '1 day'
     ) AS d ON true
JOIN (VALUES ('A'),('B'),('C')) AS s(shift) ON true
WHERE random() > 0.15;

INSERT INTO downtime_log
(machine_id, downtime_date, start_time, end_time, downtime_reason, is_planned)
SELECT
    m.machine_id,
    d::DATE AS downtime_date,
    d + INTERVAL '2 hour' AS start_time,
    d + INTERVAL '4 hour' AS end_time,
    CASE 
        WHEN random() < 0.5 THEN 'Breakdown'
        ELSE 'No Material'
    END AS downtime_reason,
    CASE 
        WHEN random() < 0.3 THEN true
        ELSE false
    END AS is_planned
FROM machine_master m
JOIN generate_series(
        DATE '2024-01-01',
        DATE '2024-06-30',
        INTERVAL '7 days'
     ) AS d ON true
WHERE random() < 0.6;

INSERT INTO maintenance_log
(machine_id, failure_date, repair_start, repair_end, failure_type, maintenance_type)
SELECT
    m.machine_id,
    d::DATE AS failure_date,
    d + INTERVAL '1 hour' AS repair_start,
    d + INTERVAL '5 hour' AS repair_end,
    CASE 
        WHEN random() < 0.5 THEN 'Mechanical'
        ELSE 'Electrical'
    END AS failure_type,
    CASE 
        WHEN random() < 0.7 THEN 'Corrective'
        ELSE 'Preventive'
    END AS maintenance_type
FROM machine_master m
JOIN generate_series(
        DATE '2024-01-01',
        DATE '2024-06-30',
        INTERVAL '15 days'
     ) AS d ON true
WHERE random() < 0.5;

ALTER TABLE machine_master 
RENAME COLUMN loaction TO location;