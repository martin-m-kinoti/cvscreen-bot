-- Recruiter view of applicant CV-screens. Run in the Supabase dashboard SQL editor.
--
-- Why a function: the `applications` table has RLS that limits each candidate to
-- their own rows, and the applicant email lives in `auth.users`, which the anon
-- key cannot read. This SECURITY DEFINER function runs as its owner, joins the
-- two, and only returns rows when the caller is a recruiter.

create or replace function public.admin_list_applications(p_job_title text default null)
returns table (
  id            uuid,
  user_id       uuid,
  name          text,
  email         text,
  job_title     text,
  overall_score numeric,
  status        text,
  created_at    timestamptz
)
language sql
security definer
set search_path = public
as $$
  select
    a.id,
    a.user_id,
    a.name,
    u.email,
    a.job_title,
    a.overall_score,
    a.status,
    a.created_at
  from public.applications a
  join auth.users u on u.id = a.user_id
  where (select role from public.profiles where id = auth.uid()) = 'recruiter'
    and (p_job_title is null or a.job_title = p_job_title)
  order by a.overall_score desc nulls last, a.created_at desc;
$$;

revoke all on function public.admin_list_applications(text) from public;
grant execute on function public.admin_list_applications(text) to authenticated;

notify pgrst, 'reload schema';
