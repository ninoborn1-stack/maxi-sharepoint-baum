-- =====================================================================
-- Maxi SharePoint Baum — Supabase Setup
-- Einmal im Supabase SQL Editor ausfuehren (Project: mwwkdegdjjncamznyofq)
-- =====================================================================

-- 1) TABELLEN -----------------------------------------------------------

create table if not exists public.folder_status (
  path        text primary key,
  status      text,
  bearbeiter  text,
  loeschen    text,
  note        text,
  updated_at  timestamptz not null default now(),
  updated_by  text
);

create table if not exists public.folder_comments (
  id          uuid primary key default gen_random_uuid(),
  path        text not null,
  user_name   text not null,
  text        text not null,
  created_at  timestamptz not null default now()
);
create index if not exists folder_comments_path_idx
  on public.folder_comments (path, created_at);

create table if not exists public.chat_messages (
  id          uuid primary key default gen_random_uuid(),
  user_name   text not null,
  text        text not null,
  created_at  timestamptz not null default now()
);
create index if not exists chat_messages_created_idx
  on public.chat_messages (created_at);

-- 2) ROW LEVEL SECURITY -------------------------------------------------

alter table public.folder_status   enable row level security;
alter table public.folder_comments enable row level security;
alter table public.chat_messages   enable row level security;

drop policy if exists "auth read status"   on public.folder_status;
drop policy if exists "auth write status"  on public.folder_status;
drop policy if exists "auth update status" on public.folder_status;
drop policy if exists "auth delete status" on public.folder_status;
drop policy if exists "auth read comments"  on public.folder_comments;
drop policy if exists "auth write comments" on public.folder_comments;
drop policy if exists "auth read chat"  on public.chat_messages;
drop policy if exists "auth write chat" on public.chat_messages;

create policy "auth read status"   on public.folder_status for select using (auth.role() = 'authenticated');
create policy "auth write status"  on public.folder_status for insert with check (auth.role() = 'authenticated');
create policy "auth update status" on public.folder_status for update using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "auth delete status" on public.folder_status for delete using (auth.role() = 'authenticated');

create policy "auth read comments"  on public.folder_comments for select using (auth.role() = 'authenticated');
create policy "auth write comments" on public.folder_comments for insert with check (auth.role() = 'authenticated');

create policy "auth read chat"  on public.chat_messages for select using (auth.role() = 'authenticated');
create policy "auth write chat" on public.chat_messages for insert with check (auth.role() = 'authenticated');

-- 3) REALTIME PUBLICATION -----------------------------------------------

do $$ begin
  perform 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'folder_status';
  if not found then execute 'alter publication supabase_realtime add table public.folder_status'; end if;
  perform 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'folder_comments';
  if not found then execute 'alter publication supabase_realtime add table public.folder_comments'; end if;
  perform 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'chat_messages';
  if not found then execute 'alter publication supabase_realtime add table public.chat_messages'; end if;
end $$;

-- 4) USER-ACCOUNTS ------------------------------------------------------
-- Login: Name eingeben -> App mappt intern zu <slug>+maxibaum@gmail.com
-- (Supabase verlangt eine echte Domain; die Adressen empfangen keine Mails.)
-- Passwort fuer alle: maxi2026 (kann spaeter via Supabase geaendert werden)

-- Aufraeumen alter Versuche (idempotent):
delete from auth.identities where provider_id in (
  'christian-bund@maxi.local','hamster@maxi.local',
  'stefan-thoelking@maxi.local','maxi-wever@maxi.local','nino@maxi.local',
  'maxibaum.christian@gmail.com','maxibaum.hamster@gmail.com',
  'maxibaum.stefan@gmail.com','maxibaum.wever@gmail.com','maxibaum.nino@gmail.com',
  'probe-user-zzy@gmail.com'
);
delete from auth.users where email in (
  'christian-bund@maxi.local','hamster@maxi.local',
  'stefan-thoelking@maxi.local','maxi-wever@maxi.local','nino@maxi.local',
  'probe-user-zzy@gmail.com'
);

do $$
declare
  users constant text[][] := array[
    ['maxibaum.christian@gmail.com', 'Christian Bund'],
    ['maxibaum.hamster@gmail.com',   'Hamster'],
    ['maxibaum.stefan@gmail.com',    'Stefan Thoelking'],
    ['maxibaum.wever@gmail.com',     'Maxi Wever'],
    ['maxibaum.nino@gmail.com',      'Nino']
  ];
  u text[];
  uid uuid;
begin
  foreach u slice 1 in array users loop
    if not exists (select 1 from auth.users where email = u[1]) then
      uid := gen_random_uuid();
      insert into auth.users (
        instance_id, id, aud, role, email, encrypted_password,
        email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
        created_at, updated_at, confirmation_token, email_change,
        email_change_token_new, recovery_token
      ) values (
        '00000000-0000-0000-0000-000000000000',
        uid, 'authenticated', 'authenticated', u[1],
        crypt('maxi2026', gen_salt('bf')),
        now(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        jsonb_build_object('display_name', u[2]),
        now(), now(), '', '', '', ''
      );
      insert into auth.identities (
        id, user_id, identity_data, provider, provider_id,
        last_sign_in_at, created_at, updated_at
      ) values (
        gen_random_uuid(), uid,
        jsonb_build_object('sub', uid::text, 'email', u[1]),
        'email', u[1],
        now(), now(), now()
      );
    end if;
  end loop;
end $$;

-- =====================================================================
-- FERTIG. Testen:
--   select email from auth.users order by created_at;
--   select * from public.folder_status;
-- =====================================================================
