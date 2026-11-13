create table if not exists public.applications (
  id uuid primary key references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),

  name text not null,
  job_id uuid,
  job_title text,

  -- Percentage values (0-100)
  overall_score numeric(5,2) not null check (overall_score between 0 and 100),
  skill_match numeric(5,2) not null check (skill_match between 0 and 100),
  experience_match numeric(5,2) not null check (experience_match between 0 and 100),
  education_match numeric(5,2) not null check (education_match between 0 and 100),
  cert_match numeric(5,2) not null check (cert_match between 0 and 100),

  summary text,
  strengths text[] default '{}',
  weaknesses text[] default '{}',
  status text not null default 'pending'
    check (status in ('Strong Match', 'Possible Match', 'Not a Match'))
);

alter table public.applications enable row level security;

-- Users can only see and modify their own row
create policy "Users can view own application record"
  on public.applications for select
  to authenticated
  using ((select auth.uid()) = id);

create policy "Users can insert own application record"
  on public.applications for insert
  to authenticated
  with check ((select auth.uid()) = id);

create policy "Users can update own application record"
  on public.applications for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- Update to allow a user to make multiple applications for different jobs, but only one application per job.
-- the old id column becomes the user reference
alter table public.applications rename column id to user_id;

-- drop the old primary key (it was on that column)
alter table public.applications drop constraint applications_pkey;

-- add a proper row id
alter table public.applications
  add column id uuid primary key default gen_random_uuid();

create index if not exists applications_user_id_idx
  on public.applications (user_id);

-- Add the job title column to an already-created table (safe to re-run).
-- n8n should insert `job_title` (it is sent to the webhook) so My Applications
-- can show which role each review belongs to.
alter table public.applications
  add column if not exists job_title text;

-- One application per (user, job). `job_id` is sent to the webhook and must be
-- inserted by n8n; the unique index then rejects a second application to the
-- same job. NULL job_id rows are ignored by the index, so legacy rows are safe.
alter table public.applications
  add column if not exists job_id uuid;

create unique index if not exists applications_user_job_uniq
  on public.applications (user_id, job_id);