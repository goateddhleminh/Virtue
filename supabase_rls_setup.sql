-- ==============================================================================
-- VIRTUE APP: SUPABASE ROW LEVEL SECURITY (RLS) & ACCESS CONTROL SETUP
-- ==============================================================================
-- Run this script in the Supabase Dashboard -> SQL Editor (https://supabase.com/dashboard)
-- Project: szsxenpcyadgfpmwivqb
-- Target Table: public.studyflow_state
-- ==============================================================================

-- 1. TẠO BẢNG studyflow_state NẾU CHƯA CÓ
CREATE TABLE IF NOT EXISTS public.studyflow_state (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  data JSONB NOT NULL DEFAULT '{}'::jsonb,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Index tối ưu truy vấn theo user_id
CREATE INDEX IF NOT EXISTS idx_studyflow_state_user_id ON public.studyflow_state(user_id);

-- 2. BẬT HỆ THỐNG ROW LEVEL SECURITY (RLS)
-- Khi bật RLS, mặc định không ai (kể cả người dùng có anon key) có thể đọc hoặc ghi dữ liệu
-- trừ khi có policy cho phép rõ ràng.
ALTER TABLE public.studyflow_state ENABLE ROW LEVEL SECURITY;

-- Bắt buộc RLS áp dụng cho tất cả các truy vấn
ALTER TABLE public.studyflow_state FORCE ROW LEVEL SECURITY;

-- 3. XÓA CÁC POLICY CŨ HOẶC KHÔNG AN TOÀN (NẾU CÓ)
DROP POLICY IF EXISTS "Users can read own studyflow_state" ON public.studyflow_state;
DROP POLICY IF EXISTS "Users can insert own studyflow_state" ON public.studyflow_state;
DROP POLICY IF EXISTS "Users can update own studyflow_state" ON public.studyflow_state;
DROP POLICY IF EXISTS "Users can delete own studyflow_state" ON public.studyflow_state;
DROP POLICY IF EXISTS "Users can access own studyflow_state" ON public.studyflow_state;
DROP POLICY IF EXISTS "Allow all access" ON public.studyflow_state;
DROP POLICY IF EXISTS "Public access" ON public.studyflow_state;

-- 4. THIẾT LẬP CÁC POLICY BẢO MẬT CHẶT CHẼ
-- Chỉ cho phép user đã đăng nhập (authenticated) và CHỈ truy cập đúng dữ liệu của chính họ (auth.uid() = user_id)

-- Policy 1: ĐỌC DỮ LIỆU (SELECT)
CREATE POLICY "Users can read own studyflow_state"
ON public.studyflow_state
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Policy 2: TẠO DỮ LIỆU MỚI (INSERT)
CREATE POLICY "Users can insert own studyflow_state"
ON public.studyflow_state
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Policy 3: CẬP NHẬT DỮ LIỆU (UPDATE)
CREATE POLICY "Users can update own studyflow_state"
ON public.studyflow_state
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy 4: XÓA DỮ LIỆU (DELETE)
CREATE POLICY "Users can delete own studyflow_state"
ON public.studyflow_state
FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- 5. PHÂN QUYỀN VAI TRÒ (ROLES PERMISSIONS)
-- Chặn hoàn toàn vai trò 'anon' (khách chưa đăng nhập không thể đọc/ghi bảng này)
REVOKE ALL ON public.studyflow_state FROM anon;

-- Cấp quyền cho vai trò 'authenticated' (chỉ được thực thi qua các RLS policy ở trên)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.studyflow_state TO authenticated;

-- ==============================================================================
-- 6. KIỂM TRA TRẠNG THÁI RLS (VERIFICATION QUERIES)
-- ==============================================================================
-- Chạy truy vấn này để xác nhận RLS đã được kích hoạt thành công:
SELECT 
  tablename, 
  rowsecurity AS is_rls_enabled 
FROM pg_tables 
WHERE schemaname = 'public' AND tablename = 'studyflow_state';

-- Xem danh sách policy đang bảo vệ bảng:
SELECT 
  policyname, 
  permissive, 
  roles, 
  cmd, 
  qual, 
  with_check 
FROM pg_policies 
WHERE tablename = 'studyflow_state';
