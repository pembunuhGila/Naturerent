alter table public.notifications
add column if not exists is_read boolean default false,
add column if not exists read_at timestamp with time zone;

create index if not exists notifications_user_unread_idx
on public.notifications (user_id, is_read, created_at desc);
