create table if not exists public.applications (
  id uuid primary key references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),

  name text not null,

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