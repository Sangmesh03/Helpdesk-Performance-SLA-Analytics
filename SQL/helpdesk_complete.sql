CREATE DATABASE HelpdeskAnalytics;
GO

USE HelpdeskAnalytics;
GO



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

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'tickets'
ORDER BY ORDINAL_POSITION;
GO



ALTER TABLE agents ADD team_clean VARCHAR(10);
GO

UPDATE agents SET team_clean =
    CASE
        WHEN CAST(team AS FLOAT) = 1 THEN 'L1'
        WHEN CAST(team AS FLOAT) = 2 THEN 'L2'
        WHEN CAST(team AS FLOAT) = 3 THEN 'L3'
    END;
GO

ALTER TABLE agents DROP COLUMN team;
GO

EXEC sp_rename 'agents.team_clean', 'team', 'COLUMN';
GO


ALTER TABLE tickets ADD created_date_clean   DATETIME NULL;
ALTER TABLE tickets ADD resolved_date_clean  DATETIME NULL;
GO

UPDATE tickets
SET created_date_clean = TRY_CONVERT(DATETIME, created_date, 120);
GO

UPDATE tickets
SET resolved_date_clean = TRY_CONVERT(DATETIME, resolved_date, 120);
GO

ALTER TABLE tickets ADD reopened_flag_clean BIT NULL;
GO
UPDATE tickets
SET reopened_flag_clean = CAST(reopened_flag AS BIT);
GO

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

SELECT ticket_id, COUNT(*) AS occurrence_count
FROM tickets
GROUP BY ticket_id
HAVING COUNT(*) > 1;
GO

ALTER TABLE tickets ADD resolution_hours DECIMAL(10,2) NULL;
GO
UPDATE tickets
SET resolution_hours =
    CAST(
        DATEDIFF(MINUTE, created_date_clean, resolved_date_clean) / 60.0
    AS DECIMAL(10,2))
WHERE resolved_date_clean IS NOT NULL;
GO

ALTER TABLE tickets ADD response_hours DECIMAL(10,2) NULL;
GO

UPDATE tickets
SET response_hours =
    CAST(
        DATEDIFF(MINUTE, created_date_clean, first_response_date) / 60.0
    AS DECIMAL(10,2));
GO


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

