-- Add macro targets to profiles (30/40/30 split based on existing calorie target)
alter table profiles 
  add column if not exists protein_target_gram int default 150,
  add column if not exists carbs_target_gram int default 200,
  add column if not exists fats_target_gram int default 67,
  add column if not exists water_target_ml int default 2000;

-- Backfill macro targets for existing users (only rows with defaults)
update profiles set
  protein_target_gram = round(daily_calorie_target * 0.30 / 4),
  carbs_target_gram = round(daily_calorie_target * 0.40 / 4),
  fats_target_gram = round(daily_calorie_target * 0.30 / 9)
where protein_target_gram = 150 
  and daily_calorie_target is not null;

-- Create water_logs table
create table if not exists water_logs (
  id bigserial primary key,
  user_id uuid references auth.users not null,
  log_date date not null,
  amount_ml int not null default 250,
  created_at timestamptz default now()
);

create index if not exists idx_water_logs_user_date on water_logs(user_id, log_date);

alter table water_logs enable row level security;

drop policy if exists "Users manage own water logs" on water_logs;

create policy "Users manage own water logs" on water_logs
  for all using (auth.uid() = user_id);

-- Verify
select column_name, data_type, column_default 
from information_schema.columns 
where table_name = 'profiles' 
  and column_name in ('protein_target_gram', 'carbs_target_gram', 'fats_target_gram', 'water_target_ml');

select * from water_logs limit 1;