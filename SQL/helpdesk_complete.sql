-- ============================================================
-- HELPDESK PERFORMANCE & SLA ANALYTICS
-- COMPLETE SQL SCRIPT — All Steps Combined
-- ============================================================

USE master;
GO
-- ============================================================
-- SCRIPT 01: DATABASE SETUP & TABLE CREATION
-- ============================================================

CREATE DATABASE HelpdeskAnalytics;
GO

USE HelpdeskAnalytics;
GO

-- ─────────────────────────────────────────
-- CREATE TABLES
-- Order: parent tables first, then tickets
-- ─────────────────────────────────────────

CREATE TABLE departments (
    dept_id     INT           PRIMARY KEY,
    dept_name   VARCHAR(100)  NOT NULL,
    floor       VARCHAR(50)   NOT NULL,
    headcount   INT           NOT NULL CHECK (headcount > 0)
);
GO

CREATE TABLE agents (
    agent_id    INT           PRIMARY KEY,
    agent_name  VARCHAR(100)  NOT NULL,
    team        VARCHAR(10)   NOT NULL,
    shift       VARCHAR(20)   NOT NULL,
    location    VARCHAR(50)   NOT NULL,
    join_date   DATE          NOT NULL
);
GO

CREATE TABLE sla_policy (
    policy_id            INT          PRIMARY KEY,
    category             VARCHAR(50)  NOT NULL,
    priority             VARCHAR(20)  NOT NULL,
    response_sla_hrs     INT          NOT NULL,
    resolution_sla_hrs   INT          NOT NULL,
    escalation_hrs       INT          NOT NULL,
    CONSTRAINT uq_sla_category_priority UNIQUE (category, priority)
);
GO

CREATE TABLE tickets (
    ticket_id            INT           PRIMARY KEY,
    created_date         NVARCHAR(100) NULL,
    resolved_date        NVARCHAR(100) NULL,
    first_response_date  DATETIME2     NULL,
    category             NVARCHAR(50)  NOT NULL,
    priority             NVARCHAR(20)  NOT NULL,
    status               NVARCHAR(20)  NOT NULL,
    department_id        INT           NOT NULL,
    agent_id             INT           NOT NULL,
    reopened_flag        INT           NOT NULL DEFAULT 0,
    resolution_notes     NVARCHAR(500) NULL
);
GO

-- ─────────────────────────────────────────
-- NOTE: After creating tables, import data
-- using SSMS Import Flat File wizard:
-- Right click HelpdeskAnalytics
-- → Tasks → Import Flat File
-- Import in this order:
-- 1. departments.csv
-- 2. agents.csv
-- 3. sla_policy.csv
-- 4. tickets.csv
-- ─────────────────────────────────────────

-- Verify row counts after import
SELECT 'departments' AS table_name, COUNT(*) AS row_count FROM departments UNION ALL
SELECT 'agents',                     COUNT(*)               FROM agents     UNION ALL
SELECT 'sla_policy',                 COUNT(*)               FROM sla_policy UNION ALL
SELECT 'tickets',                    COUNT(*)               FROM tickets;
GO

-- Sanity check — preview data
SELECT TOP 5 * FROM tickets ORDER BY ticket_id;
SELECT TOP 5 * FROM agents;
GO

-- NULL check on resolved_date by status
SELECT
    status,
    COUNT(*)                                                    AS total,
    SUM(CASE WHEN resolved_date IS NULL THEN 1 ELSE 0 END)     AS null_resolved_date
FROM tickets
GROUP BY status
ORDER BY total DESC;
GO

-- FK integrity check — both should return 0
SELECT COUNT(*) AS orphan_dept_tickets
FROM tickets t
LEFT JOIN departments d ON t.department_id = d.dept_id
WHERE d.dept_id IS NULL;

SELECT COUNT(*) AS orphan_agent_tickets
FROM tickets t
LEFT JOIN agents a ON t.agent_id = a.agent_id
WHERE a.agent_id IS NULL;
GO


-- ============================================================
-- SCRIPT 02: DATA CLEANING & DATA TYPE CORRECTION
-- ============================================================

-- ─────────────────────────────────────────
-- CHECK DATA TYPES ASSIGNED BY WIZARD
-- ─────────────────────────────────────────

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'tickets'
ORDER BY ORDINAL_POSITION;
GO

-- ─────────────────────────────────────────
-- FIX AGENTS TEAM COLUMN
-- Wizard imported L1/L2/L3 as money (1.00/2.00/3.00)
-- Fix using agent_id ranges from generation script
-- ─────────────────────────────────────────

-- Add clean varchar column
ALTER TABLE agents ADD team_clean VARCHAR(10);
GO

-- Populate using CAST to FLOAT to handle money type
UPDATE agents SET team_clean =
    CASE
        WHEN CAST(team AS FLOAT) = 1 THEN 'L1'
        WHEN CAST(team AS FLOAT) = 2 THEN 'L2'
        WHEN CAST(team AS FLOAT) = 3 THEN 'L3'
    END;
GO

-- Drop old broken column, rename clean one
ALTER TABLE agents DROP COLUMN team;
GO

EXEC sp_rename 'agents.team_clean', 'team', 'COLUMN';
GO

-- Fix team distribution using agent_id ranges
-- agents 1-10 = L1, 11-17 = L2, 18-20 = L3
UPDATE agents SET team = 'L1' WHERE agent_id BETWEEN 1  AND 10;
UPDATE agents SET team = 'L2' WHERE agent_id BETWEEN 11 AND 17;
UPDATE agents SET team = 'L3' WHERE agent_id BETWEEN 18 AND 20;
GO

-- Verify team fix
SELECT team, COUNT(*) AS count FROM agents GROUP BY team;
-- Expected: L1=10, L2=7, L3=3
GO

-- ─────────────────────────────────────────
-- FIX DATE COLUMNS: nvarchar → DATETIME
-- ─────────────────────────────────────────

-- Add clean datetime columns
ALTER TABLE tickets ADD created_date_clean   DATETIME NULL;
ALTER TABLE tickets ADD resolved_date_clean  DATETIME NULL;
GO

-- Convert using TRY_CONVERT (handles NULLs safely)
UPDATE tickets
SET created_date_clean = TRY_CONVERT(DATETIME, created_date, 120);
GO

UPDATE tickets
SET resolved_date_clean = TRY_CONVERT(DATETIME, resolved_date, 120);
GO

-- ─────────────────────────────────────────
-- FIX REOPENED_FLAG: int → BIT
-- ─────────────────────────────────────────

ALTER TABLE tickets ADD reopened_flag_clean BIT NULL;
GO

UPDATE tickets
SET reopened_flag_clean = CAST(reopened_flag AS BIT);
GO

-- ─────────────────────────────────────────
-- STANDARDISE TEXT COLUMNS
-- Trim whitespace from all key fields
-- ─────────────────────────────────────────

UPDATE tickets
SET
    category = LTRIM(RTRIM(category)),
    priority = LTRIM(RTRIM(priority)),
    status   = LTRIM(RTRIM(status));
GO

UPDATE agents
SET
    agent_name = LTRIM(RTRIM(agent_name)),
    shift      = LTRIM(RTRIM(shift)),
    location   = LTRIM(RTRIM(location));
GO

UPDATE departments
SET
    dept_name = LTRIM(RTRIM(dept_name)),
    floor     = LTRIM(RTRIM(floor));
GO

-- Check for unexpected values in controlled vocabulary
SELECT DISTINCT category FROM tickets ORDER BY category;
SELECT DISTINCT priority  FROM tickets ORDER BY priority;
SELECT DISTINCT status    FROM tickets ORDER BY status;
GO

-- ─────────────────────────────────────────
-- NULL ANALYSIS
-- ─────────────────────────────────────────

-- NULL counts across key columns
SELECT
    SUM(CASE WHEN created_date_clean  IS NULL THEN 1 ELSE 0 END) AS null_created,
    SUM(CASE WHEN resolved_date_clean IS NULL THEN 1 ELSE 0 END) AS null_resolved,
    SUM(CASE WHEN agent_id            IS NULL THEN 1 ELSE 0 END) AS null_agent,
    SUM(CASE WHEN department_id       IS NULL THEN 1 ELSE 0 END) AS null_dept
FROM tickets;
-- Expected: null_created=0, null_resolved~1177
GO

-- Confirm resolved_date NULLs align with open tickets (valid NULLs)
SELECT
    status,
    COUNT(*)                                                    AS total_tickets,
    SUM(CASE WHEN resolved_date_clean IS NULL THEN 1 ELSE 0 END) AS null_resolved_count
FROM tickets
GROUP BY status
ORDER BY total_tickets DESC;
GO

-- ─────────────────────────────────────────
-- DUPLICATE CHECK
-- ─────────────────────────────────────────

SELECT ticket_id, COUNT(*) AS occurrence_count
FROM tickets
GROUP BY ticket_id
HAVING COUNT(*) > 1;
-- Should return 0 rows
GO

-- ─────────────────────────────────────────
-- DATE LOGIC VALIDATION
-- ─────────────────────────────────────────

-- resolved_date must be after created_date
SELECT COUNT(*) AS date_anomalies
FROM tickets
WHERE resolved_date_clean IS NOT NULL
AND resolved_date_clean <= created_date_clean;
-- Should return 0
GO

-- ─────────────────────────────────────────
-- CLEANING SUMMARY
-- ─────────────────────────────────────────

SELECT 'Total tickets loaded'                               AS check_item,
       CAST(COUNT(*) AS VARCHAR)                            AS result
FROM tickets
UNION ALL
SELECT 'Valid NULL resolved_date (open tickets)',
       CAST(SUM(CASE WHEN resolved_date_clean IS NULL 
                     THEN 1 ELSE 0 END) AS VARCHAR)
FROM tickets
UNION ALL
SELECT 'Distinct categories', CAST(COUNT(DISTINCT category) AS VARCHAR) FROM tickets
UNION ALL
SELECT 'Distinct priorities', CAST(COUNT(DISTINCT priority)  AS VARCHAR) FROM tickets
UNION ALL
SELECT 'Distinct statuses',   CAST(COUNT(DISTINCT status)    AS VARCHAR) FROM tickets;
GO


-- ============================================================
-- SCRIPT 03: DERIVED COLUMNS & ANALYTICAL QUERIES
-- ============================================================

-- ─────────────────────────────────────────
-- SECTION 1: ADD DERIVED COLUMNS
-- ─────────────────────────────────────────

-- Resolution time in hours (decimal precision)
ALTER TABLE tickets ADD resolution_hours DECIMAL(10,2) NULL;
GO

UPDATE tickets
SET resolution_hours =
    CAST(
        DATEDIFF(MINUTE, created_date_clean, resolved_date_clean) / 60.0
    AS DECIMAL(10,2))
WHERE resolved_date_clean IS NOT NULL;
GO

-- First response time in hours
ALTER TABLE tickets ADD response_hours DECIMAL(10,2) NULL;
GO

UPDATE tickets
SET response_hours =
    CAST(
        DATEDIFF(MINUTE, created_date_clean, first_response_date) / 60.0
    AS DECIMAL(10,2));
GO

-- SLA breach flag for resolution
-- Join on category + priority to get specific threshold per ticket
ALTER TABLE tickets ADD sla_breach_flag BIT NULL;
GO

UPDATE t
SET t.sla_breach_flag =
    CASE
        WHEN t.resolved_date_clean IS NULL              THEN NULL
        WHEN t.resolution_hours > s.resolution_sla_hrs  THEN 1
        ELSE 0
    END
FROM tickets t
JOIN sla_policy s
    ON t.category = s.category
    AND t.priority = s.priority;
GO

-- SLA breach flag for first response
ALTER TABLE tickets ADD response_breach_flag BIT NULL;
GO

UPDATE t
SET t.response_breach_flag =
    CASE
        WHEN t.response_hours > s.response_sla_hrs THEN 1
        ELSE 0
    END
FROM tickets t
JOIN sla_policy s
    ON t.category = s.category
    AND t.priority = s.priority;
GO

-- Time intelligence columns for Power BI
ALTER TABLE tickets ADD day_of_week  VARCHAR(15) NULL;
ALTER TABLE tickets ADD hour_of_day  INT         NULL;
ALTER TABLE tickets ADD month_year   VARCHAR(10) NULL;
ALTER TABLE tickets ADD week_number  INT         NULL;
GO

UPDATE tickets
SET
    day_of_week = DATENAME(WEEKDAY, created_date_clean),
    hour_of_day = DATEPART(HOUR,    created_date_clean),
    month_year  = FORMAT(created_date_clean, 'MMM-yyyy'),
    week_number = DATEPART(WEEK,    created_date_clean);
GO

-- Verify derived columns
SELECT TOP 5
    ticket_id, category, priority,
    resolution_hours, response_hours,
    sla_breach_flag, response_breach_flag,
    day_of_week, hour_of_day, month_year
FROM tickets
ORDER BY ticket_id;
GO

-- Breach flag distribution
SELECT
    sla_breach_flag,
    COUNT(*)                                                    AS ticket_count,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS percentage
FROM tickets
WHERE sla_breach_flag IS NOT NULL
GROUP BY sla_breach_flag;
GO


-- ─────────────────────────────────────────
-- SECTION 2: ANALYTICAL QUERIES
-- ─────────────────────────────────────────

-- QUERY 1: SLA Breach Rate by Category
SELECT
    category,
    COUNT(*)                                                    AS total_tickets,
    SUM(CAST(sla_breach_flag AS INT))                           AS breached_tickets,
    CAST(SUM(CAST(sla_breach_flag AS INT)) * 100.0
         / COUNT(*) AS DECIMAL(5,2))                            AS breach_rate_pct,
    CAST(AVG(resolution_hours) AS DECIMAL(10,2))                AS avg_resolution_hrs
FROM tickets
WHERE sla_breach_flag IS NOT NULL
GROUP BY category
ORDER BY breach_rate_pct DESC;
GO

-- QUERY 2: Agent Performance Ranking (uses window functions)
SELECT
    a.agent_id,
    a.agent_name,
    a.team,
    COUNT(t.ticket_id)                                          AS total_tickets,
    CAST(AVG(t.resolution_hours) AS DECIMAL(10,2))              AS avg_resolution_hrs,
    SUM(CAST(t.sla_breach_flag AS INT))                         AS breach_count,
    CAST(SUM(CAST(t.sla_breach_flag AS INT)) * 100.0 /
        NULLIF(COUNT(CASE WHEN t.sla_breach_flag IS NOT NULL
                          THEN 1 END), 0) AS DECIMAL(5,2))      AS breach_rate_pct,
    RANK() OVER (ORDER BY COUNT(t.ticket_id) DESC)              AS workload_rank,
    RANK() OVER (ORDER BY AVG(t.resolution_hours) ASC)          AS speed_rank
FROM agents a
LEFT JOIN tickets t ON a.agent_id = t.agent_id
GROUP BY a.agent_id, a.agent_name, a.team
ORDER BY total_tickets DESC;
GO

-- QUERY 3: Department Ticket Burden
SELECT
    d.dept_name,
    d.headcount,
    COUNT(t.ticket_id)                                          AS total_tickets,
    SUM(CASE WHEN t.status IN ('Open','In Progress')
             THEN 1 ELSE 0 END)                                 AS open_tickets,
    CAST(COUNT(t.ticket_id) * 1.0
         / d.headcount AS DECIMAL(5,2))                         AS tickets_per_employee,
    CAST(SUM(CASE WHEN t.status IN ('Open','In Progress')
                  THEN 1 ELSE 0 END) * 100.0
         / COUNT(t.ticket_id) AS DECIMAL(5,2))                  AS open_rate_pct
FROM departments d
LEFT JOIN tickets t ON d.dept_id = t.department_id
GROUP BY d.dept_id, d.dept_name, d.headcount
ORDER BY open_tickets DESC;
GO

-- QUERY 4: Peak Hour Heatmap Data
SELECT
    day_of_week,
    hour_of_day,
    COUNT(*)                                                    AS ticket_count
FROM tickets
GROUP BY day_of_week, hour_of_day
ORDER BY
    CASE day_of_week
        WHEN 'Monday'    THEN 1
        WHEN 'Tuesday'   THEN 2
        WHEN 'Wednesday' THEN 3
        WHEN 'Thursday'  THEN 4
        WHEN 'Friday'    THEN 5
        WHEN 'Saturday'  THEN 6
        WHEN 'Sunday'    THEN 7
    END,
    hour_of_day;
GO

-- QUERY 5: Monthly Trend Analysis
SELECT
    month_year,
    COUNT(*)                                                    AS total_tickets,
    SUM(CASE WHEN sla_breach_flag = 1 THEN 1 ELSE 0 END)       AS breached_tickets,
    CAST(SUM(CASE WHEN sla_breach_flag = 1 THEN 1 ELSE 0 END)
         * 100.0 / NULLIF(COUNT(CASE WHEN sla_breach_flag
         IS NOT NULL THEN 1 END), 0) AS DECIMAL(5,2))           AS breach_rate_pct,
    CAST(AVG(resolution_hours) AS DECIMAL(10,2))                AS avg_resolution_hrs
FROM tickets
GROUP BY month_year
ORDER BY MIN(created_date_clean);
GO

-- QUERY 6: First Call Resolution Rate
SELECT
    category,
    COUNT(*)                                                    AS total_resolved,
    SUM(CASE WHEN reopened_flag_clean = 0 THEN 1 ELSE 0 END)   AS first_call_resolved,
    CAST(SUM(CASE WHEN reopened_flag_clean = 0 THEN 1 ELSE 0 END)
         * 100.0 / COUNT(*) AS DECIMAL(5,2))                    AS fcr_rate_pct
FROM tickets
WHERE status IN ('Resolved', 'Closed')
GROUP BY category
ORDER BY fcr_rate_pct DESC;
GO


-- ─────────────────────────────────────────
-- SECTION 3: VIEWS FOR POWER BI
-- ─────────────────────────────────────────

-- Main fact view — connect Power BI to this
CREATE OR ALTER VIEW vw_tickets_full AS
SELECT
    t.ticket_id,
    t.created_date_clean        AS created_date,
    t.resolved_date_clean       AS resolved_date,
    t.first_response_date,
    t.category,
    t.priority,
    t.status,
    t.resolution_hours,
    t.response_hours,
    t.sla_breach_flag,
    t.response_breach_flag,
    t.reopened_flag_clean       AS reopened_flag,
    t.day_of_week,
    t.hour_of_day,
    t.month_year,
    t.week_number,
    t.resolution_notes,
    a.agent_name,
    a.team                      AS agent_team,
    a.shift                     AS agent_shift,
    a.location                  AS agent_location,
    d.dept_name,
    d.headcount                 AS dept_headcount,
    s.response_sla_hrs,
    s.resolution_sla_hrs
FROM tickets t
LEFT JOIN agents      a ON t.agent_id      = a.agent_id
LEFT JOIN departments d ON t.department_id = d.dept_id
LEFT JOIN sla_policy  s ON t.category      = s.category
                        AND t.priority     = s.priority;
GO

-- Agent summary view
CREATE OR ALTER VIEW vw_agent_summary AS
SELECT
    a.agent_id,
    a.agent_name,
    a.team,
    a.shift,
    a.location,
    COUNT(t.ticket_id)                                          AS total_tickets,
    CAST(AVG(t.resolution_hours) AS DECIMAL(10,2))              AS avg_resolution_hrs,
    SUM(CAST(t.sla_breach_flag AS INT))                         AS breach_count,
    CAST(SUM(CAST(t.sla_breach_flag AS INT)) * 100.0 /
        NULLIF(COUNT(CASE WHEN t.sla_breach_flag IS NOT NULL
                          THEN 1 END), 0) AS DECIMAL(5,2))      AS breach_rate_pct,
    SUM(CASE WHEN t.status IN ('Open','In Progress')
             THEN 1 ELSE 0 END)                                 AS open_tickets
FROM agents a
LEFT JOIN tickets t ON a.agent_id = t.agent_id
GROUP BY a.agent_id, a.agent_name, a.team, a.shift, a.location;
GO

-- Department summary view
CREATE OR ALTER VIEW vw_dept_summary AS
SELECT
    d.dept_id,
    d.dept_name,
    d.headcount,
    COUNT(t.ticket_id)                                          AS total_tickets,
    SUM(CASE WHEN t.status IN ('Open','In Progress')
             THEN 1 ELSE 0 END)                                 AS open_tickets,
    CAST(COUNT(t.ticket_id) * 1.0
         / d.headcount AS DECIMAL(5,2))                         AS tickets_per_employee,
    SUM(CAST(t.sla_breach_flag AS INT))                         AS breach_count
FROM departments d
LEFT JOIN tickets t ON d.dept_id = t.department_id
GROUP BY d.dept_id, d.dept_name, d.headcount;
GO

-- Verify all views
SELECT TOP 5 * FROM vw_tickets_full;
SELECT * FROM vw_agent_summary ORDER BY total_tickets DESC;
SELECT * FROM vw_dept_summary  ORDER BY open_tickets  DESC;
GO
