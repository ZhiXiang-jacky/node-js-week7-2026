-- ============================================================
-- 🚑 你的處方箋（工單 1~5 的解法寫在這裡）
--
-- 寫法：對症下索引，例如
--   CREATE INDEX idx_xxx ON 表名 (欄位);
--
-- 提醒：
-- 1. 跑 npm run optimize 會執行這個檔案（重複執行可在 CREATE INDEX 後加上 IF NOT EXISTS）
-- 2. 如果更換新索引，原先沒有使用的索引記得 DROP（索引並非越多越好）
-- 3. 工單 6 的撰寫可到：queries/06-rewrite.sql
-- ============================================================

-- 工單 1：客服查會員
-- WHERE email = ?  →  對 email 建索引，把「掃 30 萬筆」變成「直接定位一筆」
CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);


-- 工單 2：企業會員的課表
-- WHERE user_id = ? AND cancelled_at IS NULL
-- 只在 user_id 建單欄索引 → 會撈回該會員全部報名，再逐筆過濾掉已取消（黃燈、Rows Removed 很大）
-- 改用複合索引，讓「未取消」這個條件也走索引 → 綠燈
CREATE INDEX IF NOT EXISTS idx_bookings_user_cancelled
  ON course_bookings (user_id, cancelled_at);


-- 工單 3：最新購買紀錄牆
-- ORDER BY purchase_at DESC LIMIT 100 → 對 purchase_at 建索引，直接照順序抓前 100 筆，免整表排序
CREATE INDEX IF NOT EXISTS idx_purchases_purchase_at
  ON credit_purchases (purchase_at DESC);


-- 工單 4：首頁「進行中課程」
-- WHERE start_at <= now AND end_at > now
-- 前人加在 start_at 沒效：幾乎所有課的 start_at 都 <= now（篩不掉東西）。
-- 真正能篩掉大量資料的是 end_at > now（歷史課早就結束了），索引要下在 end_at。
CREATE INDEX IF NOT EXISTS idx_courses_end_at ON courses (end_at);


-- 工單 5：上週開課課程的教練報名統計（思考方向：需新增兩個索引）
-- 病灶一：courses 依 start_at 範圍過濾「上週」→ 對 start_at 建索引
-- 病灶二：course_bookings 用 course_id JOIN，但沒有索引 → 100 多萬筆被全表掃
CREATE INDEX IF NOT EXISTS idx_courses_start_at ON courses (start_at);
CREATE INDEX IF NOT EXISTS idx_bookings_course_id ON course_bookings (course_id);


-- 加分題（選做）：使用部分索引（partial index）讓工單 2 的索引更小、更有效率
-- 概念：課表查詢永遠只看「未取消」的報名，那已取消的資料根本不需要進索引。
-- 部分索引只收錄 cancelled_at IS NULL 的列 → 體積更小、維護更省。
-- 採用它就可以把上面工單 2 的複合索引 DROP 掉（避免重複索引）。
-- DROP INDEX IF EXISTS idx_bookings_user_cancelled;
-- CREATE INDEX IF NOT EXISTS idx_bookings_user_active
--   ON course_bookings (user_id) WHERE cancelled_at IS NULL;
