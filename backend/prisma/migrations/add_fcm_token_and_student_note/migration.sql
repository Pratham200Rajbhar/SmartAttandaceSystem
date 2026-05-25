-- Add fcm_token column to students table
ALTER TABLE "students" ADD COLUMN "fcm_token" TEXT;

-- Add student_note column to attendance table
ALTER TABLE "attendance" ADD COLUMN "student_note" TEXT;
