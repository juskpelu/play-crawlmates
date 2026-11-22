-- Crawlmates skin marketplace: database setup for Supabase.
-- In your Supabase project open SQL Editor, choose New query, paste this whole file in and press Run.
-- Running it again is safe: it only adds what is missing and refreshes the functions.
--
-- How it stays safe with a public key in the game:
--   * players can only READ visible skins, and only the public columns
--   * everything else (uploading, reporting, counting wears, deleting your own upload) goes through
--     the functions below, which check every value and limit how often each player can act
--   * a skin hides itself once REPORT_LIMIT different players report it (default 3)

create table if not exists public.skins (
  id          uuid primary key default gen_random_uuid(),
  name        text not null check (name ~ '^[A-Z0-9 .!?''-]{1,16}$'),
  author      text not null check (author ~ '^[A-Z0-9 .!?''-]{1,12}$'),
  data        text not null check (char_length(data) <= 430 and data ~ '^1\.([0-9a-f]{6}){1,15}\.[0-9a-f]{168}[0-9a-f]{168}$'),
  data_hash   text not null unique,
  client      text not null,
  ip          text,
  token_hash  text not null,
  wears       integer not null default 0,
  reports     integer not null default 0,
  hidden      boolean not null default false,   -- set true to take a skin down by hand
  protected   boolean not null default false,   -- set true and reports can no longer hide it
  created_at  timestamptz not null default now()
);
create index if not exists skins_new_idx on public.skins (created_at desc) where not hidden;
create index if not exists skins_popular_idx on public.skins (wears desc, created_at desc) where not hidden;
create index if not exists skins_client_idx on public.skins (client, created_at);

create table if not exists public.skin_reports (
  skin_id    uuid not null references public.skins(id) on delete cascade,
  client     text not null,
  ip         text,
  reason     text,
  created_at timestamptz not null default now(),
  primary key (skin_id, client)
);
create table if not exists public.skin_wears (
  skin_id uuid not null references public.skins(id) on delete cascade,
  client  text not null,
  primary key (skin_id, client)
);
-- names and creator names containing any of these (ignoring spaces and symbols) are refused.
-- Add your own: insert into public.blocked_words(word) values ('WORD');
create table if not exists public.blocked_words (word text primary key check (word ~ '^[A-Z0-9]+$'));
insert into public.blocked_words(word) values ('FUCK'),('SHIT'),('CUNT'),('BITCH'),('WHORE'),('PORN'),('NAZI'),('HITLER'),('RAPE'),('PENIS'),('VAGINA')
  on conflict do nothing;

-- lock everything down, then open only what the game needs
alter table public.skins         enable row level security;
alter table public.skin_reports  enable row level security;
alter table public.skin_wears    enable row level security;
alter table public.blocked_words enable row level security;
revoke all on public.skins, public.skin_reports, public.skin_wears, public.blocked_words from anon, authenticated;
grant select (id, name, author, data, wears, created_at) on public.skins to anon, authenticated;
drop policy if exists "anyone can read visible skins" on public.skins;
create policy "anyone can read visible skins" on public.skins for select to anon, authenticated using (not hidden);

-- the player's address as Supabase's gateway passes it on (used only for rate limits)
create or replace function public.skin_request_ip() returns text
language sql stable set search_path = public as $$
  select nullif(btrim(split_part(coalesce(nullif(current_setting('request.headers', true), '')::json->>'x-forwarded-for', ''), ',', 1)), '')
$$;

create or replace function public.upload_skin(p_name text, p_author text, p_data text, p_client text)
returns json language plpgsql security definer set search_path = public as $$
declare
  v_name   text := upper(btrim(coalesce(p_name, '')));
  v_author text := upper(btrim(coalesce(p_author, '')));
  v_ip     text := skin_request_ip();
  v_token  text := replace(gen_random_uuid()::text, '-', '') || replace(gen_random_uuid()::text, '-', '');
  v_px     text;
  v_id     uuid;
begin
  if p_client is null or p_client !~ '^[a-z0-9-]{8,64}$' then raise exception 'BAD_CLIENT'; end if;
  if v_name !~ '^[A-Z0-9 .!?''-]{1,16}$' or v_author !~ '^[A-Z0-9 .!?''-]{1,12}$' then raise exception 'BAD_NAME'; end if;
  if exists (select 1 from blocked_words b
             where position(b.word in regexp_replace(v_name || v_author, '[^A-Z0-9]', '', 'g')) > 0) then
    raise exception 'BAD_NAME';
  end if;
  if p_data is null or char_length(p_data) > 430 or p_data !~ '^1\.([0-9a-f]{6}){1,15}\.[0-9a-f]{168}[0-9a-f]{168}$' then raise exception 'BAD_DATA'; end if;
  v_px := split_part(p_data, '.', 3);
  if char_length(replace(substr(v_px, 1, 168), '0', '')) < 4 or char_length(replace(substr(v_px, 169, 168), '0', '')) < 4 then
    raise exception 'EMPTY';
  end if;
  if (select count(*) from skins where client = p_client and created_at > now() - interval '1 hour') >= 5
     or (v_ip is not null and (select count(*) from skins where ip = v_ip and created_at > now() - interval '1 hour') >= 10)
     or (select count(*) from skins where created_at > now() - interval '1 minute') >= 30 then
    raise exception 'RATE_LIMIT';
  end if;
  if exists (select 1 from skins where data_hash = md5(p_data)) then raise exception 'DUPLICATE'; end if;
  insert into skins (name, author, data, data_hash, client, ip, token_hash)
    values (v_name, v_author, p_data, md5(p_data), p_client, v_ip, md5(v_token))
    returning id into v_id;
  return json_build_object('id', v_id, 'token', v_token);
end $$;

create or replace function public.report_skin(p_skin uuid, p_client text, p_reason text)
returns json language plpgsql security definer set search_path = public as $$
declare
  report_limit constant int := 3;   -- how many different players must report a skin before it hides
  v_ip     text := skin_request_ip();
  v_count  int;
  v_hidden boolean;
begin
  if p_client is null or p_client !~ '^[a-z0-9-]{8,64}$' then raise exception 'BAD_CLIENT'; end if;
  if not exists (select 1 from skins where id = p_skin) then raise exception 'NOT_FOUND'; end if;
  if (select count(*) from skin_reports where client = p_client and created_at > now() - interval '1 hour') >= 20
     or (v_ip is not null and (select count(*) from skin_reports where ip = v_ip and created_at > now() - interval '1 hour') >= 30) then
    raise exception 'REPORT_LIMIT';
  end if;
  insert into skin_reports (skin_id, client, ip, reason) values (p_skin, p_client, v_ip, left(coalesce(p_reason, ''), 40))
    on conflict do nothing;
  select count(*) into v_count from skin_reports where skin_id = p_skin;
  update skins set reports = v_count, hidden = hidden or (v_count >= report_limit and not protected)
    where id = p_skin returning hidden into v_hidden;
  return json_build_object('hidden', v_hidden);
end $$;

create or replace function public.wear_skin(p_skin uuid, p_client text)
returns void language plpgsql security definer set search_path = public as $$
declare v_n int;
begin
  if p_client is null or p_client !~ '^[a-z0-9-]{8,64}$' then return; end if;
  if not exists (select 1 from skins where id = p_skin and not hidden) then return; end if;
  insert into skin_wears (skin_id, client) values (p_skin, p_client) on conflict do nothing;
  get diagnostics v_n = row_count;
  if v_n > 0 then update skins set wears = wears + 1 where id = p_skin; end if;
end $$;

-- only the device that uploaded a skin has its token, so only it can take the skin down
create or replace function public.delete_skin(p_skin uuid, p_token text)
returns boolean language plpgsql security definer set search_path = public as $$
declare v_n int;
begin
  delete from skins where id = p_skin and token_hash = md5(coalesce(p_token, ''));
  get diagnostics v_n = row_count;
  return v_n > 0;
end $$;

revoke all on function public.skin_request_ip() from public, anon, authenticated;
revoke all on function public.upload_skin(text, text, text, text) from public;
revoke all on function public.report_skin(uuid, text, text) from public;
revoke all on function public.wear_skin(uuid, text) from public;
revoke all on function public.delete_skin(uuid, text) from public;
grant execute on function public.upload_skin(text, text, text, text) to anon, authenticated;
grant execute on function public.report_skin(uuid, text, text) to anon, authenticated;
grant execute on function public.wear_skin(uuid, text) to anon, authenticated;
grant execute on function public.delete_skin(uuid, text) to anon, authenticated;
