-- Crawlmates: accounts and the skin marketplace. Database setup for Supabase.
-- In your Supabase project open SQL Editor, choose New query, paste this whole file in and press Run.
-- Running it again is safe: it only adds what is missing and refreshes the functions.
--
-- How it stays safe with a public key in the game:
--   * players can only READ visible skins, and only the public columns
--   * everything else (accounts, uploading, reporting, wear counts, removing your own upload) goes through
--     the functions below, which check every value and limit how often each player can act
--   * passwords are stored only as bcrypt hashes; sign-in tokens only as SHA-256 hashes
--
-- Moderation, in short (details in README.md):
--   * the first report on a skin puts it under review and pauses its uploader's publishing
--   * a skin with any report never appears as a shopkeeper until it is approved (protected)
--   * 3 reports from different players also hide it from the marketplace until it is reviewed
--   * review it with   select approve_skin('<skin id>');   or   select reject_skin('<skin id>');
--     (or set the review column to approved / rejected in the Table Editor)
--   * rejecting bans the uploader and every IP their account used from publishing skins, and warns
--     everyone who wore that skin in a public lobby

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

/* ---------- accounts ---------- */
create table if not exists public.accounts (
  id          uuid primary key default gen_random_uuid(),
  name        text not null unique check (name ~ '^[A-Z0-9_]{3,12}$'),
  pass_hash   text,                                                    -- bcrypt; empty = can't sign in yet
  role        text not null default 'player' check (role in ('player', 'creator', 'admin')),
  skin_status text not null default 'ok' check (skin_status in ('ok', 'paused', 'banned')),
  created_at  timestamptz not null default now(),
  last_seen   timestamptz
);
-- every address an account has signed in or uploaded from
create table if not exists public.account_ips (
  account_id uuid not null references public.accounts(id) on delete cascade,
  ip         text not null,
  first_seen timestamptz not null default now(),
  last_seen  timestamptz not null default now(),
  primary key (account_id, ip)
);
create index if not exists account_ips_ip_idx on public.account_ips (ip);
create table if not exists public.sessions (
  token_hash text primary key,
  account_id uuid not null references public.accounts(id) on delete cascade,
  ip         text,
  created_at timestamptz not null default now(),
  last_used  timestamptz not null default now()
);
create table if not exists public.login_fails (ip text, name text, at timestamptz not null default now());
create index if not exists login_fails_at_idx on public.login_fails (at);
-- short-lived proof that a player in a lobby really is signed in to an account (used for name tags)
create table if not exists public.badge_tickets (
  ticket_hash text primary key,
  account_id  uuid not null references public.accounts(id) on delete cascade,
  expires     timestamptz not null
);
-- addresses that may no longer publish skins
create table if not exists public.skin_ip_bans (ip text primary key, reason text, created_at timestamptz not null default now());

-- the creator's account. Set its password privately in the SQL Editor (don't save that query):
--   select public.acct_set_password('HOLDEN', 'your password here');
insert into public.accounts (name, role) values ('HOLDEN', 'creator')
  on conflict (name) do update set role = 'creator';

/* ---------- skins ---------- */
create table if not exists public.skins (
  id          uuid primary key default gen_random_uuid(),
  name        text not null check (name ~ '^[A-Z0-9 .!?''-]{1,16}$'),
  author      text not null check (author ~ '^[A-Z0-9 .!?''_-]{1,12}$'),
  data        text not null,
  data_hash   text not null unique,
  client      text not null,
  ip          text,
  token_hash  text not null,
  wears       integer not null default 0,
  reports     integer not null default 0,
  hidden      boolean not null default false,   -- set true to take a skin down by hand
  protected   boolean not null default false,   -- approved: reports can no longer hide it, and shops may use it
  created_at  timestamptz not null default now()
);
alter table public.skins add column if not exists account_id uuid references public.accounts(id) on delete set null;
alter table public.skins add column if not exists review text not null default 'none';
alter table public.skins drop constraint if exists skins_review_check;
alter table public.skins add constraint skins_review_check check (review in ('none', 'pending', 'approved', 'rejected'));
alter table public.skins drop constraint if exists skins_author_check;
alter table public.skins add constraint skins_author_check check (author ~ '^[A-Z0-9 .!?''_-]{1,12}$');
-- shopkeepers only wear skins nobody has reported, or ones you approved
alter table public.skins add column if not exists shop_ok boolean generated always as (protected or reports = 0) stored;
-- skins reported before reviews existed go on the review list
update public.skins set review = 'pending' where review = 'none' and reports > 0 and not protected;
-- skins are 12 x 14 (format 1) or 24 x 28 up to 120 x 140 a frame (format 2, compressed)
alter table public.skins drop constraint if exists skins_data_check;
alter table public.skins add constraint skins_data_check check (char_length(data) <= 24000 and data ~ '^(1\.([0-9a-f]{6}){1,15}\.[0-9a-f]{168}[0-9a-f]{168}|2\.(10|[2-68])\.([0-9a-f]{6}){1,15}\.[A-Za-z0-9+/]+={0,2})$');
create index if not exists skins_new_idx on public.skins (created_at desc) where not hidden;
create index if not exists skins_popular_idx on public.skins (wears desc, created_at desc) where not hidden;
create index if not exists skins_client_idx on public.skins (client, created_at);
create index if not exists skins_account_idx on public.skins (account_id);

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
-- who wore which marketplace skin in a public lobby, so they can be warned if it's banned
create table if not exists public.skin_uses (
  skin_id    uuid not null references public.skins(id) on delete cascade,
  client     text not null,
  account_id uuid references public.accounts(id) on delete set null,
  ip         text,
  first_used timestamptz not null default now(),
  warned     boolean not null default false,
  primary key (skin_id, client)
);
-- names containing any of these (ignoring spaces and symbols) are refused.
-- Add your own: insert into public.blocked_words(word) values ('WORD');
create table if not exists public.blocked_words (word text primary key check (word ~ '^[A-Z0-9]+$'));
insert into public.blocked_words(word) values ('FUCK'),('SHIT'),('CUNT'),('BITCH'),('WHORE'),('PORN'),('NAZI'),('HITLER'),('RAPE'),('PENIS'),('VAGINA')
  on conflict do nothing;

-- skins waiting for you to look at them (only you can see this, in the Table Editor or SQL Editor)
create or replace view public.skins_to_review with (security_invoker = true) as
  select s.id, s.name, s.author, s.reports, s.hidden, s.created_at,
         (select string_agg(distinct r.reason, ', ') from public.skin_reports r where r.skin_id = s.id) as reasons
  from public.skins s where s.review = 'pending' order by s.created_at;

/* ---------- lock everything down, then open only what the game needs ---------- */
alter table public.accounts      enable row level security;
alter table public.account_ips   enable row level security;
alter table public.sessions      enable row level security;
alter table public.login_fails   enable row level security;
alter table public.badge_tickets enable row level security;
alter table public.skin_ip_bans  enable row level security;
alter table public.skins         enable row level security;
alter table public.skin_reports  enable row level security;
alter table public.skin_wears    enable row level security;
alter table public.skin_uses     enable row level security;
alter table public.blocked_words enable row level security;
revoke all on public.accounts, public.account_ips, public.sessions, public.login_fails, public.badge_tickets, public.skin_ip_bans,
  public.skins, public.skin_reports, public.skin_wears, public.skin_uses, public.blocked_words, public.skins_to_review
  from anon, authenticated;
grant select (id, name, author, data, wears, created_at, shop_ok) on public.skins to anon, authenticated;
drop policy if exists "anyone can read visible skins" on public.skins;
create policy "anyone can read visible skins" on public.skins for select to anon, authenticated using (not hidden);

/* ---------- helpers (not callable from the game) ---------- */
-- the player's address as Supabase's gateway passes it on
create or replace function public.skin_request_ip() returns text
language sql stable set search_path = public as $$
  select nullif(btrim(split_part(coalesce(nullif(current_setting('request.headers', true), '')::json->>'x-forwarded-for', ''), ',', 1)), '')
$$;
create or replace function public.sha256_hex(t text) returns text
language sql immutable set search_path = public, extensions as $$ select encode(extensions.digest(t, 'sha256'), 'hex') $$;
create or replace function public.new_token() returns text
language sql volatile set search_path = public, extensions as $$ select encode(extensions.gen_random_bytes(32), 'hex') $$;
create or replace function public.acct_link_ip(p_account uuid, p_ip text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if p_ip is null then return; end if;
  insert into account_ips (account_id, ip) values (p_account, p_ip)
    on conflict (account_id, ip) do update set last_seen = now();
end $$;
-- the account a sign-in token belongs to (null if the token is unknown or older than 90 days)
create or replace function public.acct_from_token(p_token text) returns public.accounts
language plpgsql security definer set search_path = public as $$
declare v_acc accounts; v_id uuid; v_ip text := skin_request_ip();
begin
  if p_token is null or p_token !~ '^[0-9a-f]{64}$' then return null; end if;
  update sessions set last_used = now(), ip = coalesce(v_ip, ip)
    where token_hash = sha256_hex(p_token) and last_used > now() - interval '90 days'
    returning account_id into v_id;
  if v_id is null then return null; end if;
  select * into v_acc from accounts where id = v_id;
  perform acct_link_ip(v_acc.id, v_ip);
  update accounts set last_seen = now() where id = v_acc.id;
  return v_acc;
end $$;
create or replace function public.acct_session(p_acc public.accounts) returns json
language plpgsql security definer set search_path = public as $$
declare v_token text := new_token();
begin
  insert into sessions (token_hash, account_id, ip) values (sha256_hex(v_token), p_acc.id, skin_request_ip());
  perform acct_link_ip(p_acc.id, skin_request_ip());
  update accounts set last_seen = now() where id = p_acc.id;
  return json_build_object('token', v_token, 'name', p_acc.name, 'role', p_acc.role, 'skin_status', p_acc.skin_status);
end $$;
create or replace function public.name_ok(t text) returns boolean
language sql stable set search_path = public as $$
  select not exists (select 1 from blocked_words b where position(b.word in regexp_replace(upper(t), '[^A-Z0-9]', '', 'g')) > 0)
$$;

/* ---------- accounts: what the game can call ---------- */
create or replace function public.acct_register(p_name text, p_pass text, p_client text)
returns json language plpgsql security definer set search_path = public, extensions as $$
declare v_name text := upper(btrim(coalesce(p_name, ''))); v_ip text := skin_request_ip(); v_acc accounts;
begin
  if v_name !~ '^[A-Z0-9_]{3,12}$' or not name_ok(v_name) then raise exception 'BAD_NAME'; end if;
  if p_pass is null or char_length(p_pass) < 6 or char_length(p_pass) > 72 then raise exception 'BAD_PASSWORD'; end if;
  if exists (select 1 from accounts where name = v_name) then raise exception 'NAME_TAKEN'; end if;
  if v_ip is not null and (select count(*) from account_ips i join accounts a on a.id = i.account_id
                           where i.ip = v_ip and a.created_at > now() - interval '1 day') >= 3 then
    raise exception 'RATE_LIMIT';
  end if;
  insert into accounts (name, pass_hash, skin_status)
    values (v_name, extensions.crypt(p_pass, extensions.gen_salt('bf', 8)),
            case when v_ip is not null and exists (select 1 from skin_ip_bans where ip = v_ip) then 'banned' else 'ok' end)
    returning * into v_acc;
  return acct_session(v_acc);
end $$;

create or replace function public.acct_login(p_name text, p_pass text)
returns json language plpgsql security definer set search_path = public, extensions as $$
declare v_name text := upper(btrim(coalesce(p_name, ''))); v_ip text := skin_request_ip(); v_acc accounts;
begin
  delete from login_fails where at < now() - interval '1 day';
  if (v_ip is not null and (select count(*) from login_fails where ip = v_ip and at > now() - interval '15 minutes') >= 8)
     or (select count(*) from login_fails where name = v_name and at > now() - interval '1 hour') >= 20 then
    raise exception 'TOO_MANY_TRIES';
  end if;
  select * into v_acc from accounts where name = v_name;
  if v_acc.id is null or v_acc.pass_hash is null or v_acc.pass_hash <> extensions.crypt(coalesce(p_pass, ''), v_acc.pass_hash) then
    -- answer instead of raising an error, so the failed try is remembered
    insert into login_fails (ip, name) values (v_ip, v_name);
    return json_build_object('error', 'WRONG_LOGIN');
  end if;
  return acct_session(v_acc);
end $$;

create or replace function public.acct_me(p_token text)
returns json language plpgsql security definer set search_path = public as $$
declare v_acc accounts := acct_from_token(p_token);
begin
  if v_acc.id is null then return null; end if;
  return json_build_object('name', v_acc.name, 'role', v_acc.role, 'skin_status', v_acc.skin_status);
end $$;

create or replace function public.acct_logout(p_token text)
returns void language sql security definer set search_path = public as $$
  delete from sessions where token_hash = sha256_hex(coalesce(p_token, ''));
$$;

-- name tags in lobbies: a signed-in player gets a ticket, the other players check it
create or replace function public.badge_ticket(p_token text)
returns text language plpgsql security definer set search_path = public as $$
declare v_acc accounts := acct_from_token(p_token); v_t text := new_token();
begin
  if v_acc.id is null then return null; end if;
  delete from badge_tickets where expires < now();
  insert into badge_tickets (ticket_hash, account_id, expires) values (sha256_hex(v_t), v_acc.id, now() + interval '20 minutes');
  return v_t;
end $$;
create or replace function public.badge_check(p_name text, p_ticket text)
returns json language plpgsql security definer set search_path = public as $$
declare v_acc accounts;
begin
  if p_ticket is null or p_ticket !~ '^[0-9a-f]{64}$' then return null; end if;
  select a.* into v_acc from badge_tickets t join accounts a on a.id = t.account_id
    where t.ticket_hash = sha256_hex(p_ticket) and t.expires > now() and a.name = upper(coalesce(p_name, ''));
  if v_acc.id is null then return null; end if;
  return json_build_object('name', v_acc.name, 'role', v_acc.role);
end $$;

/* ---------- skins: what the game can call ---------- */
drop function if exists public.upload_skin(text, text, text, text);
create or replace function public.upload_skin(p_name text, p_data text, p_client text, p_token text)
returns json language plpgsql security definer set search_path = public as $$
declare
  v_acc   accounts := acct_from_token(p_token);
  v_name  text := upper(btrim(coalesce(p_name, '')));
  v_ip    text := skin_request_ip();
  v_token text := new_token();
  v_px    text;
  v_id    uuid;
begin
  if v_acc.id is null then raise exception 'SIGN_IN'; end if;
  if v_acc.skin_status = 'banned' then raise exception 'BANNED'; end if;
  if v_ip is not null and exists (select 1 from skin_ip_bans where ip = v_ip) and v_acc.role = 'player' then raise exception 'BANNED'; end if;
  if v_acc.skin_status = 'paused' then raise exception 'PAUSED'; end if;
  if p_client is null or p_client !~ '^[a-z0-9-]{8,64}$' then raise exception 'BAD_CLIENT'; end if;
  if v_name !~ '^[A-Z0-9 .!?''-]{1,16}$' or not name_ok(v_name) then raise exception 'BAD_NAME'; end if;
  if p_data is null or char_length(p_data) > 24000 or p_data !~ '^(1\.([0-9a-f]{6}){1,15}\.[0-9a-f]{168}[0-9a-f]{168}|2\.(10|[2-68])\.([0-9a-f]{6}){1,15}\.[A-Za-z0-9+/]+={0,2})$' then raise exception 'BAD_DATA'; end if;
  -- a classic-size skin must have something drawn on both frames (the game checks bigger ones itself)
  if left(p_data, 2) = '1.' then
    v_px := split_part(p_data, '.', 3);
    if char_length(replace(substr(v_px, 1, 168), '0', '')) < 4 or char_length(replace(substr(v_px, 169, 168), '0', '')) < 4 then
      raise exception 'EMPTY';
    end if;
  end if;
  if (select count(*) from skins where account_id = v_acc.id and created_at > now() - interval '1 hour') >= 5
     or (v_ip is not null and (select count(*) from skins where ip = v_ip and created_at > now() - interval '1 hour') >= 10)
     or (select count(*) from skins where created_at > now() - interval '1 minute') >= 30 then
    raise exception 'RATE_LIMIT';
  end if;
  if exists (select 1 from skins where data_hash = md5(p_data)) then raise exception 'DUPLICATE'; end if;
  insert into skins (name, author, data, data_hash, client, ip, token_hash, account_id)
    values (v_name, v_acc.name, p_data, md5(p_data), p_client, v_ip, md5(v_token), v_acc.id)
    returning id into v_id;
  return json_build_object('id', v_id, 'token', v_token, 'author', v_acc.name);
end $$;

create or replace function public.report_skin(p_skin uuid, p_client text, p_reason text)
returns json language plpgsql security definer set search_path = public as $$
declare
  report_limit constant int := 3;   -- how many different players must report a skin before it also leaves the marketplace
  v_ip    text := skin_request_ip();
  v_skin  skins;
  v_count int;
begin
  if p_client is null or p_client !~ '^[a-z0-9-]{8,64}$' then raise exception 'BAD_CLIENT'; end if;
  select * into v_skin from skins where id = p_skin;
  if v_skin.id is null then raise exception 'NOT_FOUND'; end if;
  if (select count(*) from skin_reports where client = p_client and created_at > now() - interval '1 hour') >= 20
     or (v_ip is not null and (select count(*) from skin_reports where ip = v_ip and created_at > now() - interval '1 hour') >= 30) then
    raise exception 'REPORT_LIMIT';
  end if;
  insert into skin_reports (skin_id, client, ip, reason) values (p_skin, p_client, v_ip, left(coalesce(p_reason, ''), 40))
    on conflict do nothing;
  select count(*) into v_count from skin_reports where skin_id = p_skin;
  if v_skin.protected then
    -- approved skins stay up; the report is only recorded
    update skins set reports = v_count where id = p_skin;
    return json_build_object('hidden', false);
  end if;
  update skins set reports = v_count,
                   review = case when review = 'none' then 'pending' else review end,
                   hidden = hidden or v_count >= report_limit
    where id = p_skin;
  -- the uploader can't publish again until you've looked at it
  update accounts set skin_status = 'paused' where id = v_skin.account_id and skin_status = 'ok' and role = 'player';
  return json_build_object('hidden', v_count >= report_limit);
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

-- the game calls this when a player is in a public lobby wearing a marketplace skin
create or replace function public.log_skin_use(p_skin uuid, p_client text, p_token text)
returns void language plpgsql security definer set search_path = public as $$
declare v_acc accounts := acct_from_token(p_token); v_ip text := skin_request_ip();
begin
  if p_client is null or p_client !~ '^[a-z0-9-]{8,64}$' then return; end if;
  if not exists (select 1 from skins where id = p_skin) then return; end if;
  if (select count(*) from skin_uses where client = p_client and first_used > now() - interval '1 hour') >= 60 then return; end if;
  insert into skin_uses (skin_id, client, account_id, ip) values (p_skin, p_client, v_acc.id, v_ip)
    on conflict (skin_id, client) do update set account_id = coalesce(excluded.account_id, skin_uses.account_id);
end $$;

-- banned skins this player wore in a public lobby that they haven't been told about yet
create or replace function public.skin_warnings(p_client text, p_token text)
returns json language plpgsql security definer set search_path = public as $$
declare v_acc accounts := acct_from_token(p_token);
begin
  if (p_client is null or p_client !~ '^[a-z0-9-]{8,64}$') and v_acc.id is null then return '[]'::json; end if;
  return coalesce((select json_agg(json_build_object('id', s.id, 'name', s.name, 'author', s.author))
    from skins s where s.review = 'rejected' and exists (
      select 1 from skin_uses u where u.skin_id = s.id and not u.warned
        and (u.client = p_client or (v_acc.id is not null and u.account_id = v_acc.id)))), '[]'::json);
end $$;
create or replace function public.ack_skin_warning(p_skin uuid, p_client text, p_token text)
returns void language plpgsql security definer set search_path = public as $$
declare v_acc accounts := acct_from_token(p_token);
begin
  update skin_uses set warned = true
    where skin_id = p_skin and (client = p_client or (v_acc.id is not null and account_id = v_acc.id));
end $$;

-- only the device that uploaded a skin has its token, so only it can take the skin down
-- (not while it's under review or after it was rejected)
create or replace function public.delete_skin(p_skin uuid, p_token text)
returns boolean language plpgsql security definer set search_path = public as $$
declare v_n int;
begin
  if exists (select 1 from skins where id = p_skin and review in ('pending', 'rejected')) then raise exception 'UNDER_REVIEW'; end if;
  delete from skins where id = p_skin and token_hash = md5(coalesce(p_token, ''));
  get diagnostics v_n = row_count;
  return v_n > 0;
end $$;

/* ---------- reviewing (run these yourself; the game can't) ---------- */
-- changing the review column, by hand in the Table Editor or with the functions below, does the rest
create or replace function public.skins_review_changed() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.review = old.review then return new; end if;
  if new.review = 'approved' then
    new.protected := true; new.hidden := false;
  elsif new.review = 'rejected' then
    new.protected := false; new.hidden := true;
  end if;
  return new;
end $$;
create or replace function public.skins_review_after() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.review = old.review or new.account_id is null then return null; end if;
  if new.review = 'approved' then
    -- publishing comes back once none of their skins are still waiting
    update accounts set skin_status = 'ok'
      where id = new.account_id and skin_status = 'paused'
        and not exists (select 1 from skins where account_id = new.account_id and review = 'pending');
  elsif new.review = 'rejected' then
    update accounts set skin_status = 'banned' where id = new.account_id and role = 'player';
    insert into skin_ip_bans (ip, reason)
      select ip, 'rejected skin ' || new.name from account_ips where account_id = new.account_id
      on conflict (ip) do nothing;
  end if;
  return null;
end $$;
drop trigger if exists skins_review_before on public.skins;
create trigger skins_review_before before update of review on public.skins for each row execute function public.skins_review_changed();
drop trigger if exists skins_review_after on public.skins;
create trigger skins_review_after after update of review on public.skins for each row execute function public.skins_review_after();

create or replace function public.approve_skin(p_skin uuid) returns text
language sql security definer set search_path = public as $$
  update skins set review = 'approved' where id = p_skin returning 'approved ' || name;
$$;
create or replace function public.reject_skin(p_skin uuid) returns text
language sql security definer set search_path = public as $$
  update skins set review = 'rejected' where id = p_skin returning 'rejected ' || name;
$$;
-- set or reset an account's password (this is how the HOLDEN account gets its password)
create or replace function public.acct_set_password(p_name text, p_pass text) returns text
language plpgsql security definer set search_path = public, extensions as $$
begin
  if p_pass is null or char_length(p_pass) < 6 then raise exception 'password must be at least 6 characters'; end if;
  update accounts set pass_hash = extensions.crypt(p_pass, extensions.gen_salt('bf', 8)) where name = upper(p_name);
  if not found then raise exception 'no account called %', upper(p_name); end if;
  delete from sessions where account_id = (select id from accounts where name = upper(p_name));
  return 'password set for ' || upper(p_name);
end $$;
-- lift a ban by hand: select unban_account('NAME');
create or replace function public.unban_account(p_name text) returns text
language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  update accounts set skin_status = 'ok' where name = upper(p_name) returning id into v_id;
  if v_id is null then raise exception 'no account called %', upper(p_name); end if;
  delete from skin_ip_bans where ip in (select ip from account_ips where account_id = v_id);
  return 'unbanned ' || upper(p_name);
end $$;

/* ---------- who may call what ---------- */
do $$
declare f text;
begin
  -- internal helpers and moderator tools: nobody outside the dashboard
  foreach f in array array['skin_request_ip()', 'sha256_hex(text)', 'new_token()', 'acct_link_ip(uuid, text)', 'acct_from_token(text)',
    'acct_session(public.accounts)', 'name_ok(text)', 'skins_review_changed()', 'skins_review_after()', 'approve_skin(uuid)', 'reject_skin(uuid)',
    'acct_set_password(text, text)', 'unban_account(text)'] loop
    execute format('revoke all on function public.%s from public, anon, authenticated', f);
  end loop;
  -- what the game uses
  foreach f in array array['acct_register(text, text, text)', 'acct_login(text, text)', 'acct_me(text)', 'acct_logout(text)',
    'badge_ticket(text)', 'badge_check(text, text)', 'upload_skin(text, text, text, text)', 'report_skin(uuid, text, text)',
    'wear_skin(uuid, text)', 'log_skin_use(uuid, text, text)', 'skin_warnings(text, text)', 'ack_skin_warning(uuid, text, text)',
    'delete_skin(uuid, text)'] loop
    execute format('revoke all on function public.%s from public', f);
    execute format('grant execute on function public.%s to anon, authenticated', f);
  end loop;
end $$;
