-- CV-screening results. One row per application.
-- Column meanings (this is the EXISTING table; no schema change required):
--   id         = the application's own row id (primary key)
--   user_id    = the applicant's auth.users uuid
--   job_title  = the advertised job this application targets (text snapshot)
-- There is no job_id column; duplicate-per-job is handled in the app by
-- matching (user_id, job_title) before submitting.

create table if not exists public.applications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),

  name text not null,
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

-- A candidate can only read/write their own rows (matched on user_id).
drop policy if exists "Users can view own application record" on public.applications;
create policy "Users can view own application record"
  on public.applications for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can insert own application record" on public.applications;
create policy "Users can insert own application record"
  on public.applications for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update own application record" on public.applications;
create policy "Users can update own application record"
  on public.applications for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create index if not exists applications_user_id_idx
  on public.applications (user_id);
