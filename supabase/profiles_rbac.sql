-- Role-based access for CV Screen.
-- Run this in the Supabase dashboard SQL editor. It gives every signed-in user
-- a profiles row with a role, lets them read only their own row, and keeps role
-- changes server-side so the client cannot grant itself recruiter access.

-- 1. profiles table (one row per auth user).
create table if not exists public.profiles (
  id         uuid primary key references auth.users on delete cascade,
  role       text not null default 'candidate'
             check (role in ('candidate', 'recruiter')),
  created_at timestamptz not null default now()
);

-- 2. Auto-create a candidate profile whenever a user signs up.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id) values (new.id)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 3. Row Level Security: a user can read their own profile.
--    No insert/update/delete policy is granted to anon or authenticated roles,
--    so the Flutter app can only read its own role, never change it.
alter table public.profiles enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
  on public.profiles
  for select
  using (auth.uid() = id);

-- 4. Backfill profiles for users that already exist.
insert into public.profiles (id)
select id from auth.users
on conflict (id) do nothing;

-- 5. Promote a recruiter (run per person; replace the id).
--    Do this in the dashboard or with the service role key, not from the app.
-- update public.profiles set role = 'recruiter' where id = '<auth-user-uuid>';
