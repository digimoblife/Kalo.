-- Add index for the most frequent query pattern: user's food logs by date
create index if not exists idx_food_logs_user_date
  on food_logs(user_id, log_date);

-- Add index for food search via ILIKE (the app uses ilike '%query%')
create extension if not exists pg_trgm;
create index if not exists idx_foods_name_trgm
  on foods using gin (name gin_trgm_ops);
