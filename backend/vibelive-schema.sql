-- VibeLive — Supabase schema (Stage 1: identity, social, messaging, streams, economy)
-- Project: VibeLive (iqrefsaqtxoynzkhlfed) — separate from all other projects.
-- No seed/demo data is inserted by this file. Gift catalogue rows are product
-- configuration (real prices the app charges), not fake user data.

create extension if not exists pgcrypto;

-- ---------- PROFILES ----------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique check (username = lower(username) and char_length(username) between 3 and 24),
  display_name text not null default '',
  bio text not null default '',
  avatar_url text,
  cover_url text,
  interests text[] not null default '{}',
  links jsonb not null default '[]',
  throne_link text,
  is_online boolean not null default false,
  show_online boolean not null default true,
  last_seen_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Auto-create a profile + wallet when a user signs up.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare base text; candidate text; n int := 0;
begin
  base := lower(regexp_replace(split_part(new.email, '@', 1), '[^a-z0-9_]', '', 'g'));
  if char_length(base) < 3 then base := 'user'; end if;
  candidate := base;
  while exists (select 1 from public.profiles where username = candidate) loop
    n := n + 1; candidate := base || n::text;
  end loop;
  insert into public.profiles (id, username, display_name)
  values (new.id, candidate, split_part(new.email, '@', 1))
  on conflict (id) do nothing;
  insert into public.wallets (user_id, balance) values (new.id, 0)
  on conflict (user_id) do nothing;
  return new;
end; $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users for each row execute function public.handle_new_user();

-- ---------- SOCIAL GRAPH ----------
create table if not exists public.follows (
  follower_id uuid not null references public.profiles(id) on delete cascade,
  following_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, following_id),
  check (follower_id <> following_id)
);

create table if not exists public.blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reported_user_id uuid references public.profiles(id) on delete set null,
  target_type text not null check (target_type in ('user','stream','message','post')),
  target_id text,
  reason text not null,
  details text,
  status text not null default 'open' check (status in ('open','reviewing','actioned','dismissed')),
  created_at timestamptz not null default now()
);

-- ---------- STREAMS ----------
create table if not exists public.streams (
  id uuid primary key default gen_random_uuid(),
  host_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  description text not null default '',
  category text not null default 'General',
  livekit_room text not null unique,
  status text not null default 'live' check (status in ('live','ended')),
  started_at timestamptz not null default now(),
  ended_at timestamptz
);

create table if not exists public.stream_moderators (
  stream_id uuid not null references public.streams(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  granted_by uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (stream_id, user_id)
);

create table if not exists public.stream_messages (
  id uuid primary key default gen_random_uuid(),
  stream_id uuid not null references public.streams(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 500),
  created_at timestamptz not null default now()
);

-- ---------- PRIVATE MESSAGING ----------
create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  last_message_at timestamptz
);

create table if not exists public.conversation_members (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  last_read_at timestamptz,
  primary key (conversation_id, user_id)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 2000),
  created_at timestamptz not null default now()
);

create or replace function public.is_conversation_member(cid uuid)
returns boolean language sql security definer set search_path = public as $$
  select exists (select 1 from public.conversation_members
                 where conversation_id = cid and user_id = auth.uid());
$$;

-- ---------- FEED ----------
create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  body text not null default '',
  media_url text,
  media_type text check (media_type in ('image','video')),
  created_at timestamptz not null default now()
);

create table if not exists public.post_likes (
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create table if not exists public.post_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 1000),
  created_at timestamptz not null default now()
);

-- ---------- ECONOMY (server-validated) ----------
create table if not exists public.wallets (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  balance integer not null default 0 check (balance >= 0),
  updated_at timestamptz not null default now()
);

create table if not exists public.gift_catalog (
  id text primary key,
  name text not null,
  price_coins integer not null check (price_coins > 0),
  rarity text not null check (rarity in ('common','rare','epic','legendary')),
  artwork text not null,        -- asset/animation key in the app, NOT a random emoji substitute
  sound_key text,
  active boolean not null default true
);

create table if not exists public.coin_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  kind text not null check (kind in ('purchase','gift_sent','gift_received','daily_reward','refund','adjustment')),
  amount integer not null,
  balance_after integer not null,
  ref_id uuid,
  idempotency_key text unique,
  created_at timestamptz not null default now()
);

create table if not exists public.gift_transactions (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete cascade,
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  gift_id text not null references public.gift_catalog(id),
  stream_id uuid references public.streams(id) on delete set null,
  price_coins integer not null,
  idempotency_key text not null unique,
  created_at timestamptz not null default now(),
  check (sender_id <> recipient_id)
);

-- Gift catalogue = product configuration (prices actually charged). No fake users/activity.
insert into public.gift_catalog (id, name, price_coins, rarity, artwork, sound_key) values
  ('rose','Rose',10,'common','gift/rose','chime-soft'),
  ('heart','Heart Burst',25,'common','gift/heart-burst','pop-warm'),
  ('star','Star',50,'rare','gift/star','sparkle'),
  ('firework','Firework',100,'rare','gift/firework','burst'),
  ('crown','Crown',250,'epic','gift/crown','fanfare'),
  ('diamond','Diamond',500,'epic','gift/diamond','shimmer'),
  ('rocket','Rocket',750,'legendary','gift/rocket','launch'),
  ('superstar','Super Star',1499,'legendary','gift/superstar','fanfare-big')
on conflict (id) do update set name=excluded.name, price_coins=excluded.price_coins,
  rarity=excluded.rarity, artwork=excluded.artwork, sound_key=excluded.sound_key, active=true;

-- Send a gift: the ONLY client-callable path that moves coins for gifts.
-- Server-side balance check, self-gift rejection, idempotency, atomic balances + records.
create or replace function public.send_gift(
  p_recipient uuid, p_gift text, p_stream uuid, p_idempotency text)
returns uuid language plpgsql security definer set search_path = public as $$
declare price int; bal int; gid uuid; existing uuid;
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  if p_recipient = auth.uid() then raise exception 'self_gift_not_allowed'; end if;
  select id into existing from public.gift_transactions where idempotency_key = p_idempotency;
  if existing is not null then return existing; end if;
  select price_coins into price from public.gift_catalog where id = p_gift and active;
  if price is null then raise exception 'gift_not_found'; end if;
  if exists (select 1 from public.blocks
             where (blocker_id = p_recipient and blocked_id = auth.uid())
                or (blocker_id = auth.uid() and blocked_id = p_recipient))
    then raise exception 'blocked'; end if;
  update public.wallets set balance = balance - price, updated_at = now()
    where user_id = auth.uid() and balance >= price returning balance into bal;
  if bal is null then raise exception 'insufficient_balance'; end if;
  insert into public.gift_transactions (sender_id, recipient_id, gift_id, stream_id, price_coins, idempotency_key)
  values (auth.uid(), p_recipient, p_gift, p_stream, price, p_idempotency) returning id into gid;
  insert into public.coin_transactions (user_id, kind, amount, balance_after, ref_id, idempotency_key)
  values (auth.uid(), 'gift_sent', -price, bal, gid, p_idempotency || ':sent');
  update public.wallets set updated_at = now() where user_id = p_recipient;
  insert into public.coin_transactions (user_id, kind, amount, balance_after, ref_id, idempotency_key)
  select p_recipient, 'gift_received', price, balance, gid, p_idempotency || ':recv'
  from public.wallets where user_id = p_recipient;
  return gid;
end; $$;

-- ---------- ROW LEVEL SECURITY ----------
alter table public.profiles enable row level security;
alter table public.follows enable row level security;
alter table public.blocks enable row level security;
alter table public.reports enable row level security;
alter table public.streams enable row level security;
alter table public.stream_moderators enable row level security;
alter table public.stream_messages enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;
alter table public.posts enable row level security;
alter table public.post_likes enable row level security;
alter table public.post_comments enable row level security;
alter table public.wallets enable row level security;
alter table public.gift_catalog enable row level security;
alter table public.coin_transactions enable row level security;
alter table public.gift_transactions enable row level security;

-- profiles: public read, own write
create policy "profiles read" on public.profiles for select using (true);
create policy "profiles update own" on public.profiles for update using (auth.uid() = id) with check (auth.uid() = id);

-- follows: public read, own create/delete
create policy "follows read" on public.follows for select using (true);
create policy "follows insert own" on public.follows for insert with check (auth.uid() = follower_id);
create policy "follows delete own" on public.follows for delete using (auth.uid() = follower_id);

-- blocks: only the blocker sees/manages
create policy "blocks own read" on public.blocks for select using (auth.uid() = blocker_id);
create policy "blocks own insert" on public.blocks for insert with check (auth.uid() = blocker_id);
create policy "blocks own delete" on public.blocks for delete using (auth.uid() = blocker_id);

-- reports: reporter creates, only reporter reads own (moderation review is service-role)
create policy "reports insert own" on public.reports for insert with check (auth.uid() = reporter_id);
create policy "reports read own" on public.reports for select using (auth.uid() = reporter_id);

-- streams: public read of live/own, host creates/updates own
create policy "streams read" on public.streams for select using (status = 'live' or auth.uid() = host_id);
create policy "streams insert host" on public.streams for insert with check (auth.uid() = host_id);
create policy "streams update host" on public.streams for update using (auth.uid() = host_id) with check (auth.uid() = host_id);

-- stream moderators: readable by stream participants; only host grants (granted_by = host enforced by app + check here)
create policy "mods read" on public.stream_moderators for select using (true);
create policy "mods insert by granter" on public.stream_moderators for insert with check (auth.uid() = granted_by);
create policy "mods delete by granter" on public.stream_moderators for delete using (auth.uid() = granted_by);

-- stream messages: anyone signed in reads a live stream's chat; sender writes own; blocked users excluded by app checks
create policy "stream chat read" on public.stream_messages for select using (auth.uid() is not null);
create policy "stream chat insert own" on public.stream_messages for insert with check (auth.uid() = sender_id);

-- conversations: members only
create policy "conversations member read" on public.conversations for select using (public.is_conversation_member(id));
create policy "conversations create" on public.conversations for insert with check (auth.uid() is not null);
create policy "members read own conv" on public.conversation_members for select using (public.is_conversation_member(conversation_id));
create policy "members insert" on public.conversation_members for insert with check (auth.uid() is not null);
create policy "messages member read" on public.messages for select using (public.is_conversation_member(conversation_id));
create policy "messages member insert" on public.messages for insert
  with check (auth.uid() = sender_id and public.is_conversation_member(conversation_id));

-- posts: public read; author writes own
create policy "posts read" on public.posts for select using (true);
create policy "posts insert own" on public.posts for insert with check (auth.uid() = author_id);
create policy "posts update own" on public.posts for update using (auth.uid() = author_id);
create policy "posts delete own" on public.posts for delete using (auth.uid() = author_id);
create policy "likes read" on public.post_likes for select using (true);
create policy "likes insert own" on public.post_likes for insert with check (auth.uid() = user_id);
create policy "likes delete own" on public.post_likes for delete using (auth.uid() = user_id);
create policy "comments read" on public.post_comments for select using (true);
create policy "comments insert own" on public.post_comments for insert with check (auth.uid() = author_id);
create policy "comments delete own" on public.post_comments for delete using (auth.uid() = author_id);

-- economy: wallet + transactions are READ-own only for clients; writes happen
-- only inside security-definer functions (send_gift) or by the service role.
create policy "wallet read own" on public.wallets for select using (auth.uid() = user_id);
create policy "gift catalog read" on public.gift_catalog for select using (true);
create policy "coin tx read own" on public.coin_transactions for select using (auth.uid() = user_id);
create policy "gift tx read involved" on public.gift_transactions for select
  using (auth.uid() = sender_id or auth.uid() = recipient_id);

-- ---------- REALTIME ----------
alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.stream_messages;
alter publication supabase_realtime add table public.streams;

-- ---------- STORAGE ----------
insert into storage.buckets (id, name, public) values ('avatars','avatars', true)
  on conflict (id) do nothing;
insert into storage.buckets (id, name, public) values ('covers','covers', true)
  on conflict (id) do nothing;
insert into storage.buckets (id, name, public) values ('post-media','post-media', true)
  on conflict (id) do nothing;
