# Helpdesk Performance & SLA Analytics

**End-to-end IT support operations dashboard built with SQL Server, Power BI, and Python**

![Dashboard Preview](Screenshots/Executive%20Overview.png)

---

## Business Problem

Large IT companies receive hundreds of support tickets daily across departments — hardware failures, software issues, access requests, network problems. Without structured analysis, IT managers have no visibility into:

- Which ticket categories are breaching SLA deadlines repeatedly
- Which agents are overloaded vs underutilised
- Whether high-priority tickets are actually being resolved faster than low-priority ones
- What time of day and week sees the highest ticket load
- Which departments generate the most unresolved tickets
- Whether SLA compliance is improving or stagnating over time

The result is reactive IT support instead of proactive — problems keep recurring, SLAs get missed, and leadership has no data to make staffing or process decisions.

---

## Solution

An end-to-end analytics dashboard that gives IT managers a single view of support operations — tracking ticket volumes, SLA compliance, agent performance, and department-wise burden across 26 months of data (January 2024 – February 2026).

**Key insights the dashboard surfaces:**
- SLA breach rate by category and priority
- Average resolution time by agent and ticket type
- Peak ticket submission periods (day/week/month)
- Departments with highest unresolved ticket backlog
- First-call resolution rate trends
- Agent workload vs breach rate correlation

---

## Tech Stack

| Tool | Purpose |
|------|---------|
| Python (Faker, Pandas, NumPy) | Synthetic dataset generation with realistic patterns |
| SQL Server | Data storage, cleaning, transformation, analytical views |
| Power BI (DAX) | Interactive 3-page dashboard |

---

## Dataset

Synthetic dataset designed to mirror real IT helpdesk operations at a mid-large Indian IT company. All data generated using Python with realistic patterns deliberately embedded.

**4 tables — 8,000+ records:**

| Table | Rows | Description |
|-------|------|-------------|
| tickets | 8,000 | Core fact table — one row per support ticket |
| agents | 20 | Support agent details — L1/L2/L3 teams, shifts, locations |
| departments | 8 | Requesting departments with headcount for normalisation |
| sla_policy | 20 | SLA thresholds by category + priority combination |

**Realistic patterns embedded in the data:**
- Monday and Friday have higher ticket volumes — post-weekend issues and pre-weekend rushes
- Network and Hardware categories breach SLA at higher rates (35-37%) vs Access (13%)
- 3 agents carry disproportionate workload — 973, 973, 928 tickets vs team average of 400
- Q1 2025 ticket spike simulating a system migration event
- 23.49% overall SLA breach rate — realistic for a mid-size IT operation
- 9.23% ticket reopen rate — indicating premature closure issues

---

## Project Structure

```
Helpdesk-Performance-SLA-Analytics/
│
├── Data/
│   ├── tickets.csv
│   ├── agents.csv
│   ├── departments.csv
│   └── sla_policy.csv
│
├── Python/
│   └── generate_dataset.py
│
├── SQL/
│   └── helpdesk_complete.sql
│
├── PowerBI/
│   └── Helpdesk_Performance_SLA_Analytics.pbix
│
├── Screenshots/
│   ├── Executive Overview.png
│   ├── SLA & Resolution Deep Dive.png
│   └── Agent & Department Performance.png
│
└── README.md
```

---

## SQL Scripts

The SQL script (`helpdesk_complete.sql`) is structured in 3 sections and is the backbone of the entire project.

**Script 01 — Schema Creation & Data Load**
- CREATE TABLE scripts for all 4 tables with primary keys, foreign keys, and CHECK constraints
- Referential integrity enforced at database level — not in Power BI
- Verification queries confirming row counts and zero orphan records

**Script 02 — Data Cleaning & Type Correction**
- Data type fixes — nvarchar → DATETIME using TRY_CONVERT (handles NULLs safely vs CONVERT)
- agents.team column fix — wizard imported L1/L2/L3 as money type (1.00/2.00/3.00), corrected to VARCHAR
- NULL analysis — distinguishing valid NULLs (open tickets have no resolved_date) from invalid ones
- Whitespace trimming on all VARCHAR columns using LTRIM/RTRIM
- Duplicate detection on ticket_id
- Date logic validation — resolved_date must be after created_date

**Script 03 — Derived Columns & Analytical Queries**
- `resolution_hours` — DATEDIFF in minutes divided by 60.0 for decimal precision (not DATEDIFF in hours which truncates)
- `response_hours` — first response time calculation
- `sla_breach_flag` — joined to sla_policy on category + priority to get specific threshold per ticket type
- `response_breach_flag` — first response SLA violation flag
- `day_of_week`, `hour_of_day`, `month_year`, `week_number` — time intelligence columns
- 6 analytical queries: breach rates, agent rankings using RANK() window functions, department burden, peak hour heatmap, monthly trends, FCR rate
- 3 Power BI views — `vw_tickets_full`, `vw_agent_summary`, `vw_dept_summary`

---

## Dashboard — 3 Pages

### Page 1 — Executive Overview

High-level health snapshot for IT leadership.

![Page 1](Screenshots/Executive%20Overview.png)

**KPI Cards:** Total Tickets · SLA Breach % · Avg Resolution Hrs · Open Backlog · FCR Rate % · Critical Tickets

**Visuals:**
- Monthly Ticket Volume & SLA Breach Trend — dual-axis line chart showing volume and breach rate together
- Ticket Volume by Category — Network highlighted in red as highest breach category
- SLA Compliance vs Breach — donut chart with three segments: Compliant / Breached / Open/Unresolved
- Ticket Volume by Priority Over Time — stacked column across all 26 months
- Slicers: Date Range · Department · Priority
- Key Insights callout box

---

### Page 2 — SLA & Resolution Deep Dive

Where and why SLAs are being breached.

![Page 2](Screenshots/SLA%20%26%20Resolution%20Deep%20Dive.png)

**KPI Cards:** SLA Breach Rate · Avg Resolution Hrs · Total Breached Tickets · Reopen Rate %

**Visuals:**
- **Peak Hour Heatmap** — Matrix visual with conditional formatting gradient (dark navy → red) showing ticket load by Day × Hour. Monday 11am–1pm is peak. This directly answers staffing decisions.
- Avg Resolution Time by Category — Other category takes longest at 44hrs despite lower volume
- SLA Breach Rate by Category — Network 37.5% vs Access 13.1%
- Monthly SLA Breach Rate Trend — line chart with average reference line showing no improvement trend
- Top Agents by SLA Breach Rate — individual accountability view
- Slicers: Category · Priority

---

### Page 3 — Agent & Department Performance

Staffing decisions — who needs support, who is overloaded.

![Page 3](Screenshots/Agent%20%26%20Department%20Performance.png)

**KPI Cards:** Total Tickets · Avg Tickets per Agent · Overall Breach Rate · Open Backlog

**Visuals:**
- Agent Performance Summary Table — conditional formatting on Breach % column (green to red gradient)
- Ticket Volume by Agent — top 3 overloaded agents highlighted in red
- Total Tickets by Department — Engineering leads at 1,791 tickets
- Tickets per Employee by Dept — Marketing highest burden at 22.97 (highlighted)
- **Agent Workload vs SLA Breach Rate** — scatter chart showing two dimensions simultaneously. Agents in the top-right quadrant have both high workload AND high breach rate — the clearest signal for staffing intervention.
- Slicers: Team (L1/L2/L3) · Department

---

## Key Findings

| Finding | Value | Business Implication |
|---------|-------|---------------------|
| Overall SLA breach rate | 23.49% | Nearly 1 in 4 tickets misses SLA deadline |
| Network category breach rate | 37.5% | Highest — needs dedicated network support staffing |
| Access category breach rate | 13.1% | Lowest — process working well, can be a model |
| SLA breach trend over 26 months | No improvement | Systemic staffing issue, not random variation |
| Peak ticket window | Monday 11am–1pm | Schedule more agents on Monday morning shifts |
| Agent overload — top 3 | 973, 973, 928 tickets | vs avg 400 — redistribution decision needed immediately |
| Marketing dept burden | 22.97 tickets/employee | Highest ratio — potential IT training gap for Marketing staff |
| Other category resolution | 44 hrs avg | Longest time despite lowest volume — skill gap for complex issues |
| First Call Resolution rate | 95.34% | Strong — minimal ticket reopening overall |
| Reopen rate | 9.23% | ~737 tickets reopened — agents closing prematurely |
| Open backlog | 1,177 tickets | 14.7% of all tickets unresolved |

---

## DAX Measures

Key measures built in Power BI (stored in single `Measures_` table):

```dax
-- SLA Breach Rate (text for KPI card display)
SLA Breach Rate % =
FORMAT(
    DIVIDE(
        SUMX(vw_tickets_full, IF(vw_tickets_full[sla_breach_flag] = TRUE(), 1, 0)),
        CALCULATE(COUNTROWS(vw_tickets_full),
            NOT(ISBLANK(vw_tickets_full[sla_breach_flag]))),
        0
    ) * 100, "0.00") & "%"

-- FCR Rate
FCR Rate % =
FORMAT(
    DIVIDE(
        COUNTROWS(FILTER(vw_tickets_full,
            vw_tickets_full[reopened_flag] = FALSE() &&
            (vw_tickets_full[status] = "Resolved" ||
             vw_tickets_full[status] = "Closed"))),
        COUNTROWS(FILTER(vw_tickets_full,
            vw_tickets_full[status] = "Resolved" ||
            vw_tickets_full[status] = "Closed")),
        0
    ) * 100, "0.00") & "%"

-- Open Backlog
Open Backlog =
COUNTROWS(FILTER(vw_tickets_full,
    vw_tickets_full[status] = "Open" ||
    vw_tickets_full[status] = "In Progress"))

-- Breach Count
Breach Count =
SUMX(vw_tickets_full,
    IF(vw_tickets_full[sla_breach_flag] = TRUE(), 1, 0))
```

---

## SLA Policy Reference

| Category | Priority | Response SLA | Resolution SLA |
|----------|----------|-------------|----------------|
| Network | Critical | 1 hr | 2 hrs |
| Hardware | Critical | 1 hr | 4 hrs |
| Software | Critical | 1 hr | 6 hrs |
| Hardware | High | 2 hrs | 8 hrs |
| Software | High | 2 hrs | 12 hrs |
| Access | Medium | 4 hrs | 24 hrs |
| Any | Low | 8 hrs | 72 hrs |

---

## How to Run

**Dataset generation:**
```bash
pip install faker pandas numpy
python Python/generate_dataset.py
```

**SQL setup:**
1. Open SQL Server Management Studio
2. Connect to your local instance
3. Run `SQL/helpdesk_complete.sql` section by section — not all at once
4. Import CSVs from `Data/` folder using SSMS Import Flat File wizard (Tasks → Import Flat File)
5. Import in order: departments → agents → sla_policy → tickets
6. Run the views section to create `vw_tickets_full`, `vw_agent_summary`, `vw_dept_summary`

**Power BI:**
1. Open `PowerBI/Helpdesk_Performance_SLA_Analytics.pbix`
2. Home → Transform data → Data source settings → update to your local SQL Server instance
3. Refresh data

---

## Why This Project

Most fresher analytics portfolios use e-commerce or banking datasets from Kaggle. This project was deliberately designed to target Indian IT services companies (TCS, Infosys, Wipro, HCL, Cognizant) where internal helpdesk operations are a real daily concern. The schema design, SLA policy structure, and business questions mirror how ServiceNow and Jira Service Management operate in practice.

The scatter chart on Page 3 and heatmap on Page 2 are intentionally differentiating choices — they show two-dimensional analysis that goes beyond standard bar and line charts seen in typical fresher projects.

---

## About

Built as part of an independent data analytics portfolio to demonstrate end-to-end DA skills — data design, SQL engineering, Power BI dashboard development, and business storytelling.

**Tools:** SQL Server · Power BI · DAX · Python · Pandas · Faker

**Domain:** IT Operations · Helpdesk Analytics · SLA Management

**Connect:** [LinkedIn](https://www.linkedin.com/in/pratikshadandriyal) · [GitHub](https://github.com/pratikshadandriyal)



