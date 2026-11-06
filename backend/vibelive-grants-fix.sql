-- VibeLive — grant fix: table-level privileges for API roles.
-- RLS policies already control WHICH rows; these grants control WHETHER the
-- anon/authenticated roles may touch the tables at all (they could not: 42501).

grant usage on schema public to anon, authenticated;

-- Anonymous visitors: read-only at table level (RLS still filters rows;
-- only public-read policies return anything to anon).
grant select on all tables in schema public to anon;

-- Signed-in users: full DML at table level (RLS policies restrict each
-- user to their own rows / member-only data).
grant select, insert, update, delete on all tables in schema public to authenticated;

-- Functions the app calls directly.
grant execute on function public.send_gift(uuid, text, uuid, text) to authenticated;
grant execute on function public.is_conversation_member(uuid) to authenticated, anon;

-- Same treatment for any future tables in this schema.
alter default privileges in schema public grant select on tables to anon;
alter default privileges in schema public
  grant select, insert, update, delete on tables to authenticated;
