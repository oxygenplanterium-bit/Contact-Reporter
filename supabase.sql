-- Contact Reporter: run this once in its OWN Supabase project (SQL Editor -> New query -> paste -> Run).
-- Do not run it in the Nursery Manager project.

create table if not exists public.docs (
  path text primary key,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

-- The owner is the only account that signs in with this email address.
create or replace function public.is_owner() returns boolean
language sql stable as $$ select lower(coalesce(auth.jwt() ->> 'email','')) = 'oxygenplanterium@gmail.com' $$;

-- A caller is a person whose account the owner has approved.
-- When the owner switches subscriptions on (cr/settings has on = true), a person also needs an end date (ex, milliseconds) in the future.
create or replace function public.is_ok() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.docs u
    where u.path = 'cr/users/' || auth.uid()::text and u.data ->> 'st' = 'ok'
      and (
        coalesce((select s.data ->> 'on' from public.docs s where s.path = 'cr/settings'), 'false') <> 'true'
        or coalesce((u.data ->> 'ex')::numeric, 0) > extract(epoch from now()) * 1000
      )
  )
$$;


-- A "Captain" is an approved person whose phone number is in a contact, in a list the caller can see, that carries a tag equal to the caller's own name.
-- Callers may read the account record and call logs of their Captains, and nobody else's.
create or replace function public.is_captain(target text) returns boolean
language sql stable security definer set search_path = public as $$
  select public.is_ok() and target <> auth.uid()::text and exists (
    select 1
    from public.docs me, public.docs g, lateral jsonb_each(g.data -> 'ct') c
    where me.path = 'cr/users/' || target and me.data ->> 'st' = 'ok'
      and g.path like 'cr/g/%' and jsonb_typeof(g.data -> 'ct') = 'object'
      and exists (select 1 from unnest(string_to_array(lower(coalesce(c.value ->> 'tg', '')), ',')) t, public.docs cu
                  where cu.path = 'cr/users/' || auth.uid()::text
                    and regexp_replace(btrim(t), '\s+', ' ', 'g') = regexp_replace(btrim(lower(coalesce(cu.data ->> 'n', ''))), '\s+', ' ', 'g')
                    and btrim(t) <> '')
      and (g.data ->> 'all' = 'true' or (g.data -> 'to') ? auth.uid()::text)
      and length(regexp_replace(coalesce(me.data ->> 'ph', ''), '\D', '', 'g')) >= 10
      and right(regexp_replace(coalesce(c.value ->> 'p', ''), '\D', '', 'g'), 10)
        = right(regexp_replace(me.data ->> 'ph', '\D', '', 'g'), 10)
  )
$$;
grant execute on function public.is_captain(text) to authenticated;

alter table public.docs enable row level security;
drop policy if exists docs_select on public.docs;
drop policy if exists docs_insert on public.docs;
drop policy if exists docs_update on public.docs;
drop policy if exists docs_delete on public.docs;

-- This app has no SuperUsers. Remove the old SuperUser helpers and any SuperUser data left in the database.
drop function if exists public.group_has_mine(jsonb);
drop function if exists public.is_my_user(text);
drop function if exists public.is_su();
update public.docs set data = data - 'rl' - 'sp' where path like 'cr/users/%' and (data ? 'rl' or data ? 'sp');

-- Paths:  cr/users/<user id>      the person's account record (name, phone, pending or approved)
--         cr/g/<group id>         a group of contacts and the callers it is assigned to
--         cr/log/<date>/<user id> that person's calls and reports for the day
--         cr/online/<user id>     the time the person's app last reported it was open (the owner sees a green dot)
-- Owner: everything. A person: their own account record, the groups assigned to them, and their own call log.
create policy docs_select on public.docs for select to authenticated using (
  public.is_owner()
  or path = 'cr/users/' || auth.uid()::text
  or path = 'cr/settings'
  or path = 'cr/pay/' || auth.uid()::text
  or (public.is_ok() and (
        (path like 'cr/g/%' and (data ->> 'all' = 'true' or (data -> 'to') ? auth.uid()::text
           or (jsonb_typeof(data -> 'to') = 'array' and exists (select 1 from jsonb_array_elements_text(data -> 'to') t where public.is_captain(t)))))
     or (path like 'cr/log/%' and split_part(path, '/', 4) = auth.uid()::text)
     or (path like 'cr/users/%' and public.is_captain(split_part(path, '/', 3)))
     or (path like 'cr/log/%' and public.is_captain(split_part(path, '/', 4)))))
);
-- A new person can create only their own record, and only as pending.
create policy docs_insert on public.docs for insert to authenticated with check (
  public.is_owner()
  or (path = 'cr/users/' || auth.uid()::text and data ->> 'st' = 'pending' and not (data ? 'ex'))
  or (path = 'cr/pay/' || auth.uid()::text and data ->> 'st' = 'pending')
  or (public.is_ok() and path like 'cr/log/%' and split_part(path, '/', 4) = auth.uid()::text)
  or (public.is_ok() and path = 'cr/online/' || auth.uid()::text)
);
create policy docs_update on public.docs for update to authenticated
  using (public.is_owner() or (public.is_ok() and path like 'cr/log/%' and split_part(path, '/', 4) = auth.uid()::text) or (public.is_ok() and path = 'cr/online/' || auth.uid()::text) or path = 'cr/pay/' || auth.uid()::text)
  with check (public.is_owner() or (public.is_ok() and path like 'cr/log/%' and split_part(path, '/', 4) = auth.uid()::text) or (public.is_ok() and path = 'cr/online/' || auth.uid()::text) or (path = 'cr/pay/' || auth.uid()::text and data ->> 'st' = 'pending'));
create policy docs_delete on public.docs for delete to authenticated using (public.is_owner());

-- Merge helper: nested objects merge, null removes a key
create or replace function public.jsonb_deep_merge(a jsonb, b jsonb) returns jsonb
language plpgsql immutable as $$
declare k text; v jsonb; r jsonb := coalesce(a, '{}'::jsonb);
begin
  for k, v in select key, value from jsonb_each(b) loop
    if v = 'null'::jsonb then
      r := r - k;
    elsif jsonb_typeof(v) = 'object' then
      r := jsonb_set(r, array[k], public.jsonb_deep_merge(case when jsonb_typeof(r -> k) = 'object' then r -> k else '{}'::jsonb end, v), true);
    else
      r := jsonb_set(r, array[k], v, true);
    end if;
  end loop;
  return r;
end $$;

create or replace function public.patch_doc(p_path text, p_patch jsonb) returns void
language plpgsql as $$
declare n int;
begin
  update public.docs set data = public.jsonb_deep_merge(data, p_patch), updated_at = now() where path = p_path;
  get diagnostics n = row_count;
  if n = 0 then raise exception 'not_found'; end if;
end $$;

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.docs to authenticated;
grant execute on function public.patch_doc(text, jsonb), public.is_owner(), public.is_ok() to authenticated;

-- Live updates
alter table public.docs replica identity full;
do $$ begin
  alter publication supabase_realtime add table public.docs;
exception when duplicate_object then null; end $$;
