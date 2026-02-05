# Industrial Machine Performance & Risk Analysis

## Project Overview
This project analyzes industrial machine data to provide insights on **production efficiency, downtime, and reliability**. Built entirely in **PostgreSQL**, it demonstrates key industrial KPIs and advanced insights for manufacturing operations:

- Total and unplanned downtime per machine  
- Machine reliability: MTBF (Mean Time Between Failures) & MTTR (Mean Time To Repair)  
- Total production per shift  
- Production vs downtime correlation  
- Root causes of downtime (material shortage, machine breakdown)  
- At-Risk machine identification for preventive maintenance  

> Note: Data insertion is optional. Queries and table structures are included; sample data can be added for testing.

---

## Tables Description

1. **machine_master** – Machine details  
   - `machine_id` – Unique ID  
   - `machine_name` – Name of machine  
   - `installation_date` – Installation date  
   - `location` – Machine location  

2. **production_log** – Daily production per machine  
   - `machine_id` – Machine identifier  
   - `production_date` – Date of production  
   - `produced_qty` – Units produced  

3. **downtime_log** – Downtime events  
   - `machine_id` – Machine identifier  
   - `downtime_date` – Date of downtime  
   - `start_time` / `end_time` – Duration of downtime  
   - `is_planned` – TRUE if planned maintenance, FALSE otherwise  
   - `downtime_reason` – Reason for downtime (e.g., No Material, Breakdown)  

4. **maintenance_log** – Repairs and failures  
   - `machine_id` – Machine identifier  
   - `repair_start` / `repair_end` – Repair duration  
   - `failure_date` – Failure occurrence  

---

## Core KPIs & Analyses

- **Total Downtime per Machine** – Aggregated downtime to identify machines with highest production loss.  
- **Planned vs Unplanned Downtime** – Helps determine which downtime can be reduced via preventive maintenance.  
- **Total Production per Shift** – Evaluates production efficiency across shifts.  
- **Production vs Downtime Correlation** – Quantifies the impact of downtime on overall production.  
- **MTBF & MTTR** – Key reliability metrics:  
  - **MTBF:** Average time between failures per machine  
  - **MTTR:** Average repair time per machine  

---

## Machine-wise Insights 

- **LATHE_02** – Downtime: 1920 min, MTBF: 720 hrs, Production: 14674 units  
  **Status:** Medium Risk  
  **Insight:** Moderate downtime with good production; monitor trends and maintain preventive maintenance.  

- **CONV_01** – Downtime: 1680 min, MTBF: 864 hrs, Production: 14341 units  
  **Status:** Medium Risk  
  **Insight:** Moderate downtime; maintain preventive maintenance to avoid escalation.  

- **CNC_01** – Downtime: 2160 min, MTBF: 720 hrs, Production: 13939 units  
  **Status:** High Risk  
  **Insight:** High downtime and moderate production; urgent preventive maintenance required.  

- **CONV_02** – Downtime: 1920 min, MTBF: (moderate), Production: 13856 units  
  **Status:** Medium Risk  
  **Insight:** Moderate downtime; keep preventive schedule and monitor efficiency.  

- **LATHE_01** – Downtime: 1680 min, MTBF: 1200 hrs, Production: 13769 units  
  **Status:** Medium Risk  
  **Insight:** Moderate downtime with high reliability; continue regular checks.  

- **PRESS_02** – Downtime: 2160 min, MTBF: (low), Production: 13736 units  
  **Status:** High Risk  
  **Insight:** Very high downtime; prioritize maintenance to avoid production loss.  

- **ROBOT_02** – Downtime: 1920 min, MTBF: 900 hrs, Production: 13691 units  
  **Status:** Medium Risk  
  **Insight:** Moderate downtime; schedule maintenance to prevent escalation.  

- **ROBOT_01** – Downtime: 0–840 min, MTBF: 617.14 hrs, Production: ~13500 units  
  **Status:** Normal  
  **Insight:** Low downtime; machine is reliable and performing optimally.  

- **PRESS_01** – Downtime: 2040 min, MTBF: (low), Production: ~13500 units  
  **Status:** High Risk  
  **Insight:** Significant downtime; schedule urgent preventive maintenance.  

- **CNC_02** – Downtime: 1680 min, MTBF: 960 hrs, Production: ~13500 units  
  **Status:** Medium Risk  
  **Insight:** Moderate downtime with fair production; maintain efficiency with preventive maintenance.  

---

## Downtime Reason Analysis 

- **No Material**  
  - Jan 2024: 18 occurrences, 2160 min  
  - Feb 2024: 16 occurrences, 1920 min  
  - Mar 2024: 7 occurrences, 840 min  
  **Insight:** Material shortage is a frequent cause of downtime; production planning and inventory management need improvement.  

- **Breakdown / Machine Failure**  
  - Jan 2024: 14 occurrences, 1680 min  
  - Mar 2024: 18 occurrences, 2160 min  
  - Apr 2024: 54% of downtime  
  **Insight:** Machine breakdowns are significant; preventive maintenance and machine health monitoring are critical.  

---

## How to Run

1. Open PostgreSQL (`psql`) and create a new database.  
2. Run `0_create_tables.sql` to create all tables.  
3. Optional: Run `1_insert_data.sql` to add sample data.  
4. Run queries in order:  
   - `2_core_analysis.sql`  
   - `3_advanced_insights.sql`  
   - `4_final_summary.sql`  
5. Review the **final summary and machine insights** for actionable recommendations.  

---

## Skills Demonstrated

- SQL Skills: Table creation, joins, aggregation, window functions, CTEs, CASE statements  
- Industrial Data Analysis: Downtime analysis, production metrics, MTBF/MTTR, predictive maintenance  
