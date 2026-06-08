create table if not exists public.ten_for_ten_event_signups (
  id uuid primary key default gen_random_uuid(),
  event_name text not null,
  parent_guardian_name text not null,
  phone text not null,
  email text not null,
  child_name text not null,
  child_age integer not null,
  preferred_class text not null,
  notes text,
  source_page text,
  status text not null default 'new',
  raw_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint ten_for_ten_signup_email_valid check (email ~* '^[^\s@]+@[^\s@]+\.[^\s@]+$'),
  constraint ten_for_ten_signup_child_age_valid check (child_age between 6 and 14)
);

alter table public.ten_for_ten_event_signups enable row level security;

revoke all on table public.ten_for_ten_event_signups from anon;
revoke all on table public.ten_for_ten_event_signups from authenticated;

create index if not exists ten_for_ten_event_signups_created_at_idx
  on public.ten_for_ten_event_signups (created_at desc);
