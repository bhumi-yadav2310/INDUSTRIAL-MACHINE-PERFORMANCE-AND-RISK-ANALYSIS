CREATE TABLE machine_master(
	machine_id SERIAL PRIMARY KEY,
	machine_name VARCHAR(50) NOT NULL,
	machine_type  VARCHAR(20) NOT NULL,
	install_date DATE NOT NULL,
	rated_capacity INT,--units per hour
	loaction VARCHAR(50)
);
CREATE TABLE production_log(
	log_id SERIAL PRIMARY KEY,
	machine_id INT REFERENCES machine_master(machine_id),
	production_date DATE NOT NULL,
	shift CHAR(1) CHECK (shift IN ('A','B','C')),
	produced_qty INT NOT NULL,
	planned_qty INT NOT NULL,
	run_time_minutes INT NOT NULL	
);
CREATE TABLE downtime_log(
	downtime_id SERIAL PRIMARY KEY,
	machine_id INT REFERENCES machine_master(machine_id),
	downtime_date DATE NOT NULL,
	start_time TIMESTAMP NOT NULL,
	end_time TIMESTAMP NOT NULL,
	downtime_reason VARCHAR(50),
	is_planned BOOLEAN
);
CREATE TABLE maintenance_log(
	maintenance_id SERIAL PRIMARY KEY,
	machine_id INT REFERENCES machine_master(machine_id),
	failure_date DATE NOT NULL,
	repair_start TIMESTAMP NOT NULL,
	repair_end TIMESTAMP NOT NULL,
	failure_type VARCHAR(50),
	maintenance_type VARCHAR(50) --preventitive/corrective
);