-- THRAGG PROTOCOL — Supabase Database Schema v2
-- ================================================
-- Run this entire file in your Supabase project's SQL Editor.
-- supabase.com → your project → SQL Editor → New query → paste → Run

-- ── ACTUAL WORKOUTS ───────────────────────────────────────────
-- Core training log. Sets and laps are embedded as JSONB arrays.
create table if not exists actual_workouts (
  id                   text primary key,
  planned_workout_id   text,
  program_id           text,
  date                 date not null,
  session              int  default 1,
  type                 text not null check (type in ('strength','run','conditioning','mobility')),
  pillar               text not null check (pillar in ('strong','durable','fast','mobility')),
  title                text,
  duration             int,
  notes                text,
  vest_weight_lbs      int  default 0,
  mile_time_sec        int,
  deviation_from_plan  text default 'unplanned' check (deviation_from_plan in ('none','modified','rescheduled','unplanned')),
  sets                 jsonb default '[]'::jsonb,
  laps                 jsonb default '[]'::jsonb,
  created_at           timestamptz default now()
);

-- ── PR LEDGER ─────────────────────────────────────────────────
-- Append-only record of every personal record set.
-- "Current PR" = latest entry per metric.
create table if not exists pr_ledger (
  id            text primary key,
  workout_id    text references actual_workouts(id) on delete cascade,
  metric        text not null check (metric in ('deadlift','squat','bench','mile_time','murph_time')),
  value         float not null,
  date          date  not null,
  vest_worn     boolean default false,
  previous_pr   float,
  notes         text,
  created_at    timestamptz default now()
);

-- ── MILESTONES ────────────────────────────────────────────────
-- Written once when a trigger fires. Never recomputed.
create table if not exists milestones (
  id              text primary key,
  workout_id      text references actual_workouts(id) on delete set null,
  type            text not null check (type in ('threshold_met','phase_complete','pr_set','streak')),
  pillar          text check (pillar in ('strong','durable','fast','overall','mobility')),
  label           text not null,
  date            date not null,
  threshold_value float,
  created_at      timestamptz default now()
);

-- ── ROW LEVEL SECURITY ────────────────────────────────────────
-- Personal single-user app: allow all operations from anon key.
-- If you add authentication later, replace these with user-scoped policies.
alter table actual_workouts enable row level security;
alter table pr_ledger       enable row level security;
alter table milestones      enable row level security;

drop policy if exists "thragg_allow_all" on actual_workouts;
drop policy if exists "thragg_allow_all" on pr_ledger;
drop policy if exists "thragg_allow_all" on milestones;

create policy "thragg_allow_all" on actual_workouts for all using (true) with check (true);
create policy "thragg_allow_all" on pr_ledger       for all using (true) with check (true);
create policy "thragg_allow_all" on milestones       for all using (true) with check (true);

-- ── INDEXES ───────────────────────────────────────────────────
create index if not exists idx_workouts_date   on actual_workouts(date desc);
create index if not exists idx_workouts_pillar on actual_workouts(pillar);
create index if not exists idx_workouts_type   on actual_workouts(type);
create index if not exists idx_pr_metric       on pr_ledger(metric, date desc);
create index if not exists idx_milestones_date on milestones(date desc);
