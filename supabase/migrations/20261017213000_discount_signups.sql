-- Discount code signups for the homepage offer (code 10410, "ten for ten").
-- Project: https://zkyhhoxcrjkhywblzehr.supabase.co
--
-- Apply in the Supabase SQL editor, or with the Supabase CLI from this repo:
--   supabase db push
--
-- Anonymous visitors may insert a row. They cannot select, update, or delete.
-- Read saved rows in the Supabase table editor (dashboard role), not from the site.

create table if not exists public.discount_signups (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  name text not null,
  email text not null,
  phone text not null,
  source_page text,
  code_given text not null default '10410',
  constraint discount_signups_name_valid check (char_length(btrim(name)) between 2 and 80),
  constraint discount_signups_email_valid check (
    char_length(email) between 6 and 320
    and email = lower(email)
    and email ~* '^[^\s@]+@[^\s@]+\.[^\s@]+$'
  ),
  constraint discount_signups_phone_valid check (
    char_length(phone) between 7 and 40
    and char_length(regexp_replace(phone, '\D', '', 'g')) between 10 and 15
  ),
  constraint discount_signups_source_page_valid check (source_page is null or char_length(source_page) <= 500),
  constraint discount_signups_code_given_valid check (code_given = '10410')
);

create unique index if not exists discount_signups_email_lower_key
  on public.discount_signups (lower(email));

create index if not exists discount_signups_created_at_idx
  on public.discount_signups (created_at desc);

alter table public.discount_signups enable row level security;

revoke all on table public.discount_signups from public;
revoke all on table public.discount_signups from anon;
revoke all on table public.discount_signups from authenticated;

grant insert (name, email, phone, source_page) on table public.discount_signups to anon;

create policy discount_signups_anon_insert
  on public.discount_signups
  for insert
  to anon
  with check (
    code_given = '10410'
    and char_length(btrim(name)) between 2 and 80
    and char_length(email) between 6 and 320
    and email = lower(email)
    and email ~* '^[^\s@]+@[^\s@]+\.[^\s@]+$'
    and char_length(phone) between 7 and 40
    and char_length(regexp_replace(phone, '\D', '', 'g')) between 10 and 15
    and (source_page is null or char_length(source_page) <= 500)
  );

comment on table public.discount_signups is
  'Homepage ten-for-ten discount signups. Anon may insert only. code_given is always 10410.';
