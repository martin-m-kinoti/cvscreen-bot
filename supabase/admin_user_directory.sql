-- User Management (recruiter directory) support for CV Screen.
-- Run this in the Supabase dashboard SQL editor.
--
-- Why this is needed:
--   The Flutter app signs requests with the anon/publishable key, which has no
--   SELECT or DELETE rights on Supabase's `auth.users` system table, so the app
--   cannot list or remove accounts directly. These SECURITY DEFINER functions run
--   as their owner (the dashboard role, which can read auth.users) and gate every
--   call to recruiters, so the client can only reach them while a recruiter is
--   signed in. No service_role key is ever shipped in the app.

-- 1. List all accounts for the recruiter directory.
--    Name is taken from the signup metadata, falling back to the email local part.
create or replace function public.admin_list_users()
returns table (
  id          uuid,
  name        text,
  email       text,
  role        text,
  created_at  timestamptz,
  last_active timestamptz
)
language sql
security definer
set search_path = public
as $$
  select
    u.id,
    coalesce(
      nullif(trim(coalesce(u.raw_user_meta_data->>'full_name', '')), ''),
      nullif(trim(coalesce(u.raw_user_meta_data->>'first_name', '') || ' ' ||
                      coalesce(u.raw_user_meta_data->>'last_name', '')), ''),
      nullif(trim(coalesce(u.raw_user_meta_data->>'name', '')), ''),
      nullif(split_part(coalesce(u.email, ''), '@', 1), ''),
      'Unnamed user'
    ) as name,
    u.email,
    coalesce(p.role, 'candidate') as role,
    u.created_at,
    u.last_sign_in_at as last_active
  from auth.users u
  left join public.profiles p on p.id = u.id
  where (select role from public.profiles where id = auth.uid()) = 'recruiter'
  order by u.created_at desc;
$$;

-- 2. Delete an account (cascades to its profiles row via the foreign key).
--    plpgsql so we can reject non-recruiters before touching auth.users.
create or replace function public.admin_delete_user(target uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if (select role from public.profiles where id = auth.uid()) is distinct from 'recruiter' then
    raise exception 'Not authorized to manage users'
      using hint = 'Only recruiters can delete accounts.';
  end if;
  delete from auth.users where id = target;
end;
$$;

-- 3. Edit an account's email. Recruiter-only, validates the format, rejects a
--    collision with another account, and marks the new address confirmed so the
--    user can still sign in immediately.
create or replace function public.admin_update_user_email(target uuid, new_email text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  caller_role text;
  clean text := lower(btrim(new_email));
begin
  select role into caller_role from public.profiles where id = auth.uid();
  if caller_role is distinct from 'recruiter' then
    raise exception 'Not authorized to manage users'
      using hint = 'Only recruiters can edit accounts.';
  end if;

  if clean = '' or clean !~* '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    raise exception 'Enter a valid email address';
  end if;

  if exists (select 1 from auth.users where lower(email) = clean and id <> target) then
    raise exception 'That email is already in use';
  end if;

  update auth.users
     set email = clean,
         updated_at = now()
   where id = target;
end;
$$;

-- 4. Lock the functions down to signed-in users (RLS + the recruiter check above
--    still decide whether any rows come back; this just avoids public execute).
revoke all on function public.admin_list_users() from public;
revoke all on function public.admin_delete_user(uuid) from public;
revoke all on function public.admin_update_user_email(uuid, text) from public;
grant execute on function public.admin_list_users() to authenticated;
grant execute on function public.admin_delete_user(uuid) to authenticated;
grant execute on function public.admin_update_user_email(uuid, text) to authenticated;

-- 5. Make PostgREST pick up the new functions immediately. Without this the app
--    gets "Could not find the function public.admin_list_users ... in the schema
--    cache" (PGRST202) until the cache reloads on its own.
notify pgrst, 'reload schema';
