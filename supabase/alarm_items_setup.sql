-- Creates a row-per-alarm table and migrates data from the legacy public.alarms JSON snapshot table.

create table if not exists public.alarm_items (
  device_id text not null,
  alarm_id bigint not null,
  name text not null,
  time text not null,
  days jsonb not null default '[]'::jsonb,
  meal_timing text,
  enabled boolean not null default true,
  confirmed boolean not null default false,
  missed boolean not null default false,
  confirmed_time text,
  confirmed_date text,
  missed_date text,
  updated_at timestamptz not null default now(),
  primary key (device_id, alarm_id)
);

create index if not exists alarm_items_device_idx
  on public.alarm_items(device_id);

alter table public.alarm_items
  add column if not exists confirmed_date text;

alter table public.alarm_items
  add column if not exists missed_date text;

alter table public.alarm_items enable row level security;

-- Development policies for anon key usage.
drop policy if exists "dev alarm_items read" on public.alarm_items;
create policy "dev alarm_items read"
on public.alarm_items
for select
to anon
using (true);

drop policy if exists "dev alarm_items insert" on public.alarm_items;
create policy "dev alarm_items insert"
on public.alarm_items
for insert
to anon
with check (true);

drop policy if exists "dev alarm_items update" on public.alarm_items;
create policy "dev alarm_items update"
on public.alarm_items
for update
to anon
using (true)
with check (true);

drop policy if exists "dev alarm_items delete" on public.alarm_items;
create policy "dev alarm_items delete"
on public.alarm_items
for delete
to anon
using (true);

-- One-time migration from legacy table public.alarms (jsonb snapshot per device).
do $$
begin
  if to_regclass('public.alarms') is not null then
    insert into public.alarm_items (
      device_id,
      alarm_id,
      name,
      time,
      days,
      meal_timing,
      enabled,
      confirmed,
      missed,
      confirmed_time,
      confirmed_date,
      missed_date,
      updated_at
    )
    select
      a.device_id,
      coalesce((item->>'id')::bigint, 0) as alarm_id,
      coalesce(item->>'name', '') as name,
      coalesce(item->>'time', '') as time,
      coalesce(item->'days', '[]'::jsonb) as days,
      item->>'mealTiming' as meal_timing,
      coalesce((item->>'enabled')::boolean, true) as enabled,
      coalesce((item->>'confirmed')::boolean, false) as confirmed,
      coalesce((item->>'missed')::boolean, false) as missed,
      item->>'confirmedTime' as confirmed_time,
      item->>'confirmedDate' as confirmed_date,
      item->>'missedDate' as missed_date,
      now() as updated_at
    from public.alarms a,
         lateral jsonb_array_elements(coalesce(a.alarms, '[]'::jsonb)) as item
    on conflict (device_id, alarm_id) do update
    set
      name = excluded.name,
      time = excluded.time,
      days = excluded.days,
      meal_timing = excluded.meal_timing,
      enabled = excluded.enabled,
      confirmed = excluded.confirmed,
      missed = excluded.missed,
      confirmed_time = excluded.confirmed_time,
      confirmed_date = excluded.confirmed_date,
      missed_date = excluded.missed_date,
      updated_at = excluded.updated_at;
  end if;
end
$$;

create table if not exists public.alarm_history (
  device_id text not null,
  alarm_id bigint not null,
  event_date text not null,
  name text not null,
  scheduled_time text not null,
  status text not null,
  confirmed_time text,
  updated_at timestamptz not null default now(),
  primary key (device_id, event_date, alarm_id)
);

create index if not exists alarm_history_device_idx
  on public.alarm_history(device_id);

alter table public.alarm_history enable row level security;

drop policy if exists "dev alarm_history read" on public.alarm_history;
create policy "dev alarm_history read"
on public.alarm_history
for select
to anon
using (true);

drop policy if exists "dev alarm_history insert" on public.alarm_history;
create policy "dev alarm_history insert"
on public.alarm_history
for insert
to anon
with check (true);

drop policy if exists "dev alarm_history update" on public.alarm_history;
create policy "dev alarm_history update"
on public.alarm_history
for update
to anon
using (true)
with check (true);
