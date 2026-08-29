-- Migration 004: Seed sample data for testing Kalo. Wrapped (Monthly Recap)
-- Run this in Supabase SQL Editor to populate sample logs for August 2026

-- 1. Ensure sample foods exist
INSERT INTO foods (name, calories, protein, carbs, fats, serving_size, serving_unit)
VALUES 
  ('Nasi Goreng Spesial', 485, 18, 62, 16, 100, 'gram'),
  ('Ayam Bakar Dada', 280, 31, 0, 8, 100, 'gram'),
  ('Telur Rebus', 155, 13, 1, 11, 100, 'gram'),
  ('Oatmeal Banana', 320, 10, 55, 5, 100, 'gram'),
  ('Gado-Gado', 350, 14, 40, 15, 100, 'gram')
ON CONFLICT DO NOTHING;

-- 2. Insert sample logs for August 2026 for profiles
DO $$
DECLARE
  v_user_id UUID;
  v_food_1 INT;
  v_food_2 INT;
  v_food_3 INT;
  v_food_4 INT;
  v_date DATE;
  v_i INT;
BEGIN
  -- Loop through all existing user profiles
  FOR v_user_id IN SELECT id FROM profiles LOOP
    -- Get food IDs
    SELECT id INTO v_food_1 FROM foods WHERE name = 'Nasi Goreng Spesial' LIMIT 1;
    SELECT id INTO v_food_2 FROM foods WHERE name = 'Ayam Bakar Dada' LIMIT 1;
    SELECT id INTO v_food_3 FROM foods WHERE name = 'Telur Rebus' LIMIT 1;
    SELECT id INTO v_food_4 FROM foods WHERE name = 'Oatmeal Banana' LIMIT 1;

    -- Update profile streak and target
    UPDATE profiles 
    SET current_streak = 14, 
        daily_calorie_target = 2000, 
        water_target_ml = 2000,
        last_log_date = CURRENT_DATE
    WHERE id = v_user_id;

    -- Insert food & water logs for 22 days in August 2026
    FOR v_i IN 1..22 LOOP
      v_date := ('2026-08-' || LPAD(v_i::text, 2, '0'))::DATE;

      -- Breakfast
      INSERT INTO food_logs (user_id, food_id, log_date, meal_type, portion, total_calories, created_at)
      VALUES (v_user_id, v_food_4, v_date, 'Breakfast', 1.0, 320, v_date + TIME '08:00:00')
      ON CONFLICT DO NOTHING;

      -- Lunch
      INSERT INTO food_logs (user_id, food_id, log_date, meal_type, portion, total_calories, created_at)
      VALUES (v_user_id, v_food_1, v_date, 'Lunch', 1.0, 485, v_date + TIME '12:30:00')
      ON CONFLICT DO NOTHING;

      -- Dinner
      INSERT INTO food_logs (user_id, food_id, log_date, meal_type, portion, total_calories, created_at)
      VALUES (v_user_id, v_food_2, v_date, 'Dinner', 1.2, 336, v_date + TIME '19:00:00')
      ON CONFLICT DO NOTHING;

      -- Water log (2000ml)
      INSERT INTO water_logs (user_id, log_date, amount_ml, created_at)
      VALUES (v_user_id, v_date, 2000, v_date + TIME '20:00:00')
      ON CONFLICT DO NOTHING;
    END LOOP;

  END LOOP;
END $$;
