-- Kids Boxing Camp (Nov 15, 2026) "Contact Ken" inquiries from the homepage.
-- Project: https://zkyhhoxcrjkhywblzehr.supabase.co
-- Anonymous visitors may insert a row. They cannot select, update, or delete.
-- Read saved rows in the Supabase table editor (dashboard role), not from the site.

create table if not exists public.camp_inquiries (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  parent_name text not null,
  email text not null,
  phone text not null,
  child_name text not null,
  child_age smallint not null,
  message text,
  source_page text,
  constraint camp_inquiries_parent_name_valid check (char_length(btrim(parent_name)) between 2 and 80),
  constraint camp_inquiries_child_name_valid check (char_length(btrim(child_name)) between 1 and 80),
  constraint camp_inquiries_child_age_valid check (child_age between 5 and 14),
  constraint camp_inquiries_email_valid check (
    char_length(email) between 6 and 320
    and email = lower(email)
    and email ~* '^[^\s@]+@[^\s@]+\.[^\s@]+$'
  ),
  constraint camp_inquiries_phone_valid check (
    char_length(phone) between 7 and 40
    and char_length(regexp_replace(phone, '\D', '', 'g')) between 10 and 15
  ),
  constraint camp_inquiries_message_valid check (message is null or char_length(message) <= 1000),
  constraint camp_inquiries_source_page_valid check (source_page is null or char_length(source_page) <= 500)
);

create index if not exists camp_inquiries_created_at_idx
  on public.camp_inquiries (created_at desc);

alter table public.camp_inquiries enable row level security;

revoke all on table public.camp_inquiries from public;
revoke all on table public.camp_inquiries from anon;
revoke all on table public.camp_inquiries from authenticated;

grant insert (parent_name, email, phone, child_name, child_age, message, source_page)
  on table public.camp_inquiries to anon;

create policy camp_inquiries_anon_insert
  on public.camp_inquiries
  for insert
  to anon
  with check (
    char_length(btrim(parent_name)) between 2 and 80
    and char_length(btrim(child_name)) between 1 and 80
    and child_age between 5 and 14
    and char_length(email) between 6 and 320
    and email = lower(email)
    and char_length(phone) between 7 and 40
    and (message is null or char_length(message) <= 1000)
    and (source_page is null or char_length(source_page) <= 500)
  );
