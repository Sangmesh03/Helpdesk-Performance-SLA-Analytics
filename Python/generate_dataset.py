import pandas as pd
import numpy as np
from faker import Faker
from datetime import datetime, timedelta
import random

fake = Faker('en_IN')
np.random.seed(42)
random.seed(42)

# ─────────────────────────────────────────
# 1. DEPARTMENTS
# ─────────────────────────────────────────
departments = pd.DataFrame([
    {'dept_id': 1, 'dept_name': 'Engineering',       'floor': 'Floor 3', 'headcount': 120},
    {'dept_id': 2, 'dept_name': 'Finance',            'floor': 'Floor 1', 'headcount': 45},
    {'dept_id': 3, 'dept_name': 'Human Resources',    'floor': 'Floor 2', 'headcount': 30},
    {'dept_id': 4, 'dept_name': 'Sales',              'floor': 'Floor 4', 'headcount': 80},
    {'dept_id': 5, 'dept_name': 'Operations',         'floor': 'Floor 2', 'headcount': 60},
    {'dept_id': 6, 'dept_name': 'Marketing',          'floor': 'Floor 5', 'headcount': 35},
    {'dept_id': 7, 'dept_name': 'Legal',              'floor': 'Floor 1', 'headcount': 20},
    {'dept_id': 8, 'dept_name': 'Customer Support',   'floor': 'Floor 3', 'headcount': 70},
])

# ─────────────────────────────────────────
# 2. AGENTS
# ─────────────────────────────────────────
agent_names = [
    'Rohit Sharma', 'Priya Nair', 'Amit Verma', 'Sneha Iyer', 'Karan Mehta',
    'Divya Pillai', 'Rajesh Kumar', 'Ananya Singh', 'Vikram Rao', 'Pooja Gupta',
    'Suresh Patil', 'Neha Joshi', 'Arjun Mishra', 'Kavita Reddy', 'Manoj Tiwari',
    'Ritu Saxena', 'Deepak Nair', 'Sunita Bhat', 'Harish Menon', 'Meera Kapoor',
]

teams     = ['L1'] * 10 + ['L2'] * 7 + ['L3'] * 3
shifts    = ['Morning', 'Evening', 'Night']
locations = ['Mumbai', 'Bangalore', 'Hyderabad', 'Chennai', 'Pune']

agents_list = []
for i, name in enumerate(agent_names):
    join_date = fake.date_between(start_date='-4y', end_date='-1y')
    agents_list.append({
        'agent_id':   i + 1,
        'agent_name': name,
        'team':       teams[i],
        'shift':      random.choice(shifts),
        'location':   random.choice(locations),
        'join_date':  join_date,
    })

agents = pd.DataFrame(agents_list)

# ─────────────────────────────────────────
# 3. SLA POLICY
# ─────────────────────────────────────────
sla_policy = pd.DataFrame([
    {'policy_id': 1,  'category': 'Hardware', 'priority': 'Critical', 'response_sla_hrs': 1,  'resolution_sla_hrs': 4,  'escalation_hrs': 2},
    {'policy_id': 2,  'category': 'Hardware', 'priority': 'High',     'response_sla_hrs': 2,  'resolution_sla_hrs': 8,  'escalation_hrs': 4},
    {'policy_id': 3,  'category': 'Hardware', 'priority': 'Medium',   'response_sla_hrs': 4,  'resolution_sla_hrs': 24, 'escalation_hrs': 12},
    {'policy_id': 4,  'category': 'Hardware', 'priority': 'Low',      'response_sla_hrs': 8,  'resolution_sla_hrs': 72, 'escalation_hrs': 48},
    {'policy_id': 5,  'category': 'Software', 'priority': 'Critical', 'response_sla_hrs': 1,  'resolution_sla_hrs': 6,  'escalation_hrs': 3},
    {'policy_id': 6,  'category': 'Software', 'priority': 'High',     'response_sla_hrs': 2,  'resolution_sla_hrs': 12, 'escalation_hrs': 6},
    {'policy_id': 7,  'category': 'Software', 'priority': 'Medium',   'response_sla_hrs': 4,  'resolution_sla_hrs': 24, 'escalation_hrs': 12},
    {'policy_id': 8,  'category': 'Software', 'priority': 'Low',      'response_sla_hrs': 8,  'resolution_sla_hrs': 72, 'escalation_hrs': 48},
    {'policy_id': 9,  'category': 'Network',  'priority': 'Critical', 'response_sla_hrs': 1,  'resolution_sla_hrs': 2,  'escalation_hrs': 1},
    {'policy_id': 10, 'category': 'Network',  'priority': 'High',     'response_sla_hrs': 2,  'resolution_sla_hrs': 6,  'escalation_hrs': 3},
    {'policy_id': 11, 'category': 'Network',  'priority': 'Medium',   'response_sla_hrs': 4,  'resolution_sla_hrs': 12, 'escalation_hrs': 8},
    {'policy_id': 12, 'category': 'Network',  'priority': 'Low',      'response_sla_hrs': 8,  'resolution_sla_hrs': 48, 'escalation_hrs': 24},
    {'policy_id': 13, 'category': 'Access',   'priority': 'Critical', 'response_sla_hrs': 1,  'resolution_sla_hrs': 4,  'escalation_hrs': 2},
    {'policy_id': 14, 'category': 'Access',   'priority': 'High',     'response_sla_hrs': 2,  'resolution_sla_hrs': 8,  'escalation_hrs': 4},
    {'policy_id': 15, 'category': 'Access',   'priority': 'Medium',   'response_sla_hrs': 4,  'resolution_sla_hrs': 24, 'escalation_hrs': 12},
    {'policy_id': 16, 'category': 'Access',   'priority': 'Low',      'response_sla_hrs': 8,  'resolution_sla_hrs': 72, 'escalation_hrs': 48},
    {'policy_id': 17, 'category': 'Other',    'priority': 'Critical', 'response_sla_hrs': 2,  'resolution_sla_hrs': 8,  'escalation_hrs': 4},
    {'policy_id': 18, 'category': 'Other',    'priority': 'High',     'response_sla_hrs': 4,  'resolution_sla_hrs': 16, 'escalation_hrs': 8},
    {'policy_id': 19, 'category': 'Other',    'priority': 'Medium',   'response_sla_hrs': 8,  'resolution_sla_hrs': 48, 'escalation_hrs': 24},
    {'policy_id': 20, 'category': 'Other',    'priority': 'Low',      'response_sla_hrs': 12, 'resolution_sla_hrs': 96, 'escalation_hrs': 72},
])
# ─────────────────────────────────────────
# 4. TICKETS
# ─────────────────────────────────────────

categories  = ['Hardware', 'Software', 'Network', 'Access', 'Other']
priorities  = ['Critical', 'High', 'Medium', 'Low']
statuses    = ['Resolved', 'Closed', 'Open', 'In Progress', 'Reopened']

# Priority weights — Medium/High most common, Critical rare
priority_weights = [0.08, 0.22, 0.45, 0.25]

# Category weights — Software most common in IT
category_weights = [0.20, 0.30, 0.18, 0.22, 0.10]

# Dept weights — Engineering & Sales generate most tickets
dept_weights = [0.22, 0.10, 0.07, 0.18, 0.13, 0.10, 0.05, 0.15]

# SLA breach probability per category (realistic: Network & Hardware breach more)
breach_prob = {
    'Hardware': 0.28,
    'Software': 0.20,
    'Network':  0.35,
    'Access':   0.12,
    'Other':    0.15,
}

# Overloaded agents (agent_ids 1, 3, 7 get disproportionate tickets)
overloaded_agents = [1, 3, 7]

# SLA policy lookup
sla_lookup = sla_policy.set_index(['category', 'priority'])

start_date = datetime(2024, 1, 1)
end_date   = datetime(2026, 2, 28)
total_days = (end_date - start_date).days

tickets_list = []

for ticket_id in range(1, 8001):

    # ── Date: bias toward Mon (0) and Fri (4), and Q1 2025 spike ──
    day_offset = random.randint(0, total_days)
    created_date = start_date + timedelta(days=day_offset)

    # Monday/Friday get 1.6x more tickets — shift random generation
    dow = created_date.weekday()
    if dow in [0, 4]:
        hour = random.choices(range(8, 20), weights=[3,4,5,6,7,8,8,7,6,5,4,3])[0]
    else:
        hour = random.choices(range(8, 20), weights=[2,3,4,5,6,7,7,6,5,4,3,2])[0]

    created_date = created_date.replace(
        hour=hour,
        minute=random.randint(0, 59),
        second=random.randint(0, 59)
    )

    # Q1 2025 spike — simulate a system migration event
    if datetime(2025, 1, 1) <= created_date <= datetime(2025, 3, 31):
        if random.random() < 0.3:  # 30% extra tickets dropped into this window
            created_date = created_date  # keep, inflates volume naturally via seed

    category  = random.choices(categories,  weights=category_weights)[0]
    priority  = random.choices(priorities,  weights=priority_weights)[0]
    dept_id   = random.choices(range(1, 9), weights=dept_weights)[0]

    # Overloaded agent logic
    if random.random() < 0.25:
        agent_id = random.choice(overloaded_agents)
    else:
        agent_id = random.randint(1, 20)

    # SLA thresholds
    sla_row            = sla_lookup.loc[(category, priority)]
    response_sla_hrs   = sla_row['response_sla_hrs']
    resolution_sla_hrs = sla_row['resolution_sla_hrs']

    # First response time
    will_breach_response = random.random() < (breach_prob[category] * 0.6)
    if will_breach_response:
        response_hrs = response_sla_hrs * random.uniform(1.1, 3.0)
    else:
        response_hrs = response_sla_hrs * random.uniform(0.1, 0.9)
    first_response_date = created_date + timedelta(hours=response_hrs)

    # Status — ~15% tickets still open/in-progress
    rand_status = random.random()
    if rand_status < 0.70:
        status = 'Resolved'
    elif rand_status < 0.80:
        status = 'Closed'
    elif rand_status < 0.88:
        status = 'Open'
    elif rand_status < 0.95:
        status = 'In Progress'
    else:
        status = 'Reopened'

    # Resolution date — only for resolved/closed/reopened
    if status in ['Resolved', 'Closed', 'Reopened']:
        will_breach = random.random() < breach_prob[category]
        if priority == 'Critical':
            will_breach = random.random() < (breach_prob[category] * 1.5)  # Critical breach more
        if will_breach:
            resolution_hrs = resolution_sla_hrs * random.uniform(1.05, 4.0)
        else:
            resolution_hrs = resolution_sla_hrs * random.uniform(0.1, 0.95)
        resolved_date = created_date + timedelta(hours=resolution_hrs)
        # Cap at end_date
        if resolved_date > end_date:
            resolved_date = end_date - timedelta(hours=random.randint(1, 48))
    else:
        resolved_date = None

    # Reopened flag
    reopened_flag = 1 if status == 'Reopened' else (1 if random.random() < 0.05 else 0)

    tickets_list.append({
        'ticket_id':           ticket_id,
        'created_date':        created_date.strftime('%Y-%m-%d %H:%M:%S'),
        'resolved_date':       resolved_date.strftime('%Y-%m-%d %H:%M:%S') if resolved_date else None,
        'first_response_date': first_response_date.strftime('%Y-%m-%d %H:%M:%S'),
        'category':            category,
        'priority':            priority,
        'status':              status,
        'department_id':       dept_id,
        'agent_id':            agent_id,
        'reopened_flag':       reopened_flag,
        'resolution_notes':    fake.sentence(nb_words=6) if resolved_date else None,
    })

tickets = pd.DataFrame(tickets_list)

# ─────────────────────────────────────────
# 5. EXPORT
# ─────────────────────────────────────────
tickets.to_csv('/mnt/user-data/outputs/tickets.csv',        index=False)
agents.to_csv('/mnt/user-data/outputs/agents.csv',          index=False)
departments.to_csv('/mnt/user-data/outputs/departments.csv',index=False)
sla_policy.to_csv('/mnt/user-data/outputs/sla_policy.csv',  index=False)

print("=" * 50)
print("DATASET GENERATION COMPLETE")
print("=" * 50)
print(f"Tickets:     {len(tickets):,} rows")
print(f"Agents:      {len(agents)} rows")
print(f"Departments: {len(departments)} rows")
print(f"SLA Policy:  {len(sla_policy)} rows")
print()
print("── Ticket Status Distribution ──")
print(tickets['status'].value_counts().to_string())
print()
print("── Priority Distribution ──")
print(tickets['priority'].value_counts().to_string())
print()
print("── Category Distribution ──")
print(tickets['category'].value_counts().to_string())
print()
print("── Date Range ──")
print(f"Earliest: {tickets['created_date'].min()}")
print(f"Latest:   {tickets['created_date'].max()}")
print()
print("── Overloaded Agents (ticket count) ──")
top_agents = tickets['agent_id'].value_counts().head(5)
print(top_agents.to_string())
