-- Stamped by the scheduled job that emails new camp inquiries to Coach Ken.
-- Anon keeps insert-only access on the form columns; no grant on notified_at.
alter table public.camp_inquiries add column if not exists notified_at timestamptz;
create index if not exists camp_inquiries_unnotified_idx
  on public.camp_inquiries (created_at) where notified_at is null;
