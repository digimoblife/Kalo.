-- Migration 003: Add last_log_date to profiles table for streak calculation
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS last_log_date DATE;
