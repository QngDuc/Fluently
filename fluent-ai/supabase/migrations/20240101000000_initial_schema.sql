-- ═══════════════════════════════════════════════════════════════════
-- FLUENT AI — Initial Database Schema
-- Supabase / PostgreSQL 15
-- Migration: 20240101000000_initial_schema
-- Tables: 18 | Enums: 9 | Indexes: 12 | RLS Policies: 15
-- ═══════════════════════════════════════════════════════════════════

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- full-text search trên vocabulary

-- ─────────────────────────────────────────────
-- ENUMS
-- ─────────────────────────────────────────────

CREATE TYPE user_role AS ENUM ('USER', 'PREMIUM', 'ADMIN');
CREATE TYPE cefr_level AS ENUM ('A1', 'A2', 'B1', 'B2', 'C1', 'C2');
CREATE TYPE theme_mode AS ENUM ('LIGHT', 'DARK', 'SYSTEM');
CREATE TYPE lesson_type AS ENUM ('VOCABULARY', 'PRONUNCIATION', 'CONVERSATION', 'GRAMMAR', 'LISTENING');
CREATE TYPE lesson_status AS ENUM ('NOT_STARTED', 'IN_PROGRESS', 'COMPLETED');
CREATE TYPE conversation_mode AS ENUM ('FREE', 'ROLEPLAY', 'IELTS_MOCK');
CREATE TYPE subscription_plan AS ENUM ('FREE', 'PREMIUM_MONTHLY', 'PREMIUM_ANNUAL', 'LIFETIME');
CREATE TYPE subscription_status AS ENUM ('ACTIVE', 'CANCELLED', 'EXPIRED', 'TRIAL');
CREATE TYPE payment_status AS ENUM ('PENDING', 'SUCCESS', 'FAILED', 'REFUNDED');

-- ─────────────────────────────────────────────
-- TABLE 1: users
-- Kết hợp với Supabase Auth (auth.users)
-- ─────────────────────────────────────────────
CREATE TABLE public.users (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email           TEXT UNIQUE NOT NULL,
  password_hash   TEXT,
  full_name       TEXT NOT NULL,
  avatar_url      TEXT,
  native_language TEXT NOT NULL DEFAULT 'vi',
  auth_provider   TEXT NOT NULL DEFAULT 'email',
  provider_id     TEXT,
  role            user_role NOT NULL DEFAULT 'USER',
  is_verified     BOOLEAN NOT NULL DEFAULT false,
  is_active       BOOLEAN NOT NULL DEFAULT true,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_login_at   TIMESTAMPTZ
);

COMMENT ON TABLE public.users IS 'Bảng người dùng chính — liên kết với Supabase Auth';
COMMENT ON COLUMN public.users.auth_provider IS 'email | google | apple';
COMMENT ON COLUMN public.users.role IS 'USER = free, PREMIUM = trả phí, ADMIN = quản trị';

-- ─────────────────────────────────────────────
-- TABLE 2: user_profiles
-- Dữ liệu học tập: XP, streak, level
-- ─────────────────────────────────────────────
CREATE TABLE public.user_profiles (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID UNIQUE NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  current_level    cefr_level NOT NULL DEFAULT 'A1',
  xp_total         INTEGER NOT NULL DEFAULT 0,
  current_streak   INTEGER NOT NULL DEFAULT 0,
  longest_streak   INTEGER NOT NULL DEFAULT 0,
  last_active_date DATE,
  total_study_mins INTEGER NOT NULL DEFAULT 0,
  timezone         TEXT NOT NULL DEFAULT 'Asia/Ho_Chi_Minh',
  CONSTRAINT xp_non_negative CHECK (xp_total >= 0),
  CONSTRAINT streak_non_negative CHECK (current_streak >= 0)
);

COMMENT ON TABLE public.user_profiles IS 'Dữ liệu tiến trình học: XP, streak, level CEFR';

-- ─────────────────────────────────────────────
-- TABLE 3: user_preferences
-- Cài đặt giao diện UI/UX
-- ─────────────────────────────────────────────
CREATE TABLE public.user_preferences (
  id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id              UUID UNIQUE NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  theme                theme_mode NOT NULL DEFAULT 'SYSTEM',
  accent_color         TEXT NOT NULL DEFAULT '#D8E221',
  layout_config        JSONB NOT NULL DEFAULT '{}',
  onboarding_completed BOOLEAN NOT NULL DEFAULT false,
  onboarding_step      SMALLINT NOT NULL DEFAULT 0,
  font_size            TEXT NOT NULL DEFAULT 'MEDIUM',
  ui_language          TEXT NOT NULL DEFAULT 'vi',
  haptic_enabled       BOOLEAN NOT NULL DEFAULT true,
  sound_enabled        BOOLEAN NOT NULL DEFAULT true,
  widget_order         JSONB NOT NULL DEFAULT '[]',
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.user_preferences IS 'Cấu hình giao diện: theme, layout, onboarding state';
COMMENT ON COLUMN public.user_preferences.layout_config IS 'JSON: widget order, hidden sections trên Home screen';
COMMENT ON COLUMN public.user_preferences.widget_order IS 'JSON array: thứ tự widgets kéo thả trên Home';

-- ─────────────────────────────────────────────
-- TABLE 4: ui_events
-- Analytics tracking hành vi UX
-- ─────────────────────────────────────────────
CREATE TABLE public.ui_events (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  event_name       TEXT NOT NULL,
  screen_name      TEXT,
  event_properties JSONB NOT NULL DEFAULT '{}',
  session_id       TEXT,
  device_type      TEXT,
  app_version      TEXT,
  occurred_at      TIMESTAMPTZ NOT NULL DEFAULT now()
) PARTITION BY RANGE (occurred_at);

COMMENT ON TABLE public.ui_events IS 'Analytics: track mọi interaction người dùng — partitioned by month';

-- Tạo partitions cho 6 tháng đầu
CREATE TABLE public.ui_events_2024_q1 PARTITION OF public.ui_events
  FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');
CREATE TABLE public.ui_events_2024_q2 PARTITION OF public.ui_events
  FOR VALUES FROM ('2024-04-01') TO ('2024-07-01');
CREATE TABLE public.ui_events_2024_q3 PARTITION OF public.ui_events
  FOR VALUES FROM ('2024-07-01') TO ('2024-10-01');
CREATE TABLE public.ui_events_2024_q4 PARTITION OF public.ui_events
  FOR VALUES FROM ('2024-10-01') TO ('2025-01-01');
CREATE TABLE public.ui_events_2025_q1 PARTITION OF public.ui_events
  FOR VALUES FROM ('2025-01-01') TO ('2025-04-01');
CREATE TABLE public.ui_events_default PARTITION OF public.ui_events DEFAULT;

-- ─────────────────────────────────────────────
-- TABLE 5: learning_goals
-- Mục tiêu học của user
-- ─────────────────────────────────────────────
CREATE TABLE public.learning_goals (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  target_language  TEXT NOT NULL,
  goal_type        TEXT NOT NULL, -- 'ielts' | 'business' | 'travel' | 'daily' | 'exam' | 'academic'
  daily_min_target SMALLINT NOT NULL DEFAULT 10,
  target_date      DATE,
  is_active        BOOLEAN NOT NULL DEFAULT true,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT daily_min_valid CHECK (daily_min_target BETWEEN 5 AND 120)
);

COMMENT ON TABLE public.learning_goals IS 'Mục tiêu học của user: IELTS, business, travel...';

-- ─────────────────────────────────────────────
-- TABLE 6: languages
-- Ngôn ngữ được hỗ trợ
-- ─────────────────────────────────────────────
CREATE TABLE public.languages (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code        TEXT UNIQUE NOT NULL, -- 'en', 'ja', 'ko', 'zh', 'fr'
  name        TEXT NOT NULL,
  native_name TEXT NOT NULL,
  flag_emoji  TEXT NOT NULL,
  is_active   BOOLEAN NOT NULL DEFAULT true,
  sort_order  SMALLINT NOT NULL DEFAULT 0
);

COMMENT ON TABLE public.languages IS 'Ngôn ngữ hỗ trợ: EN, JA, KO, ZH, FR';

-- ─────────────────────────────────────────────
-- TABLE 7: courses
-- Khóa học theo ngôn ngữ & level
-- ─────────────────────────────────────────────
CREATE TABLE public.courses (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  language_id  UUID NOT NULL REFERENCES public.languages(id),
  title        TEXT NOT NULL,
  description  TEXT,
  level        cefr_level NOT NULL,
  thumbnail_url TEXT,
  sort_order   SMALLINT NOT NULL DEFAULT 0,
  is_active    BOOLEAN NOT NULL DEFAULT true,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.courses IS 'Khóa học: grouping lessons theo ngôn ngữ và CEFR level';

-- ─────────────────────────────────────────────
-- TABLE 8: lessons
-- Bài học đơn lẻ trong khóa học
-- ─────────────────────────────────────────────
CREATE TABLE public.lessons (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  course_id     UUID NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
  title         TEXT NOT NULL,
  description   TEXT,
  type          lesson_type NOT NULL,
  duration_mins SMALLINT NOT NULL DEFAULT 5,
  xp_reward     SMALLINT NOT NULL DEFAULT 20,
  content_json  JSONB NOT NULL DEFAULT '{}',
  sort_order    SMALLINT NOT NULL DEFAULT 0,
  is_premium    BOOLEAN NOT NULL DEFAULT false,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT duration_valid CHECK (duration_mins BETWEEN 1 AND 60),
  CONSTRAINT xp_valid CHECK (xp_reward BETWEEN 0 AND 500)
);

COMMENT ON TABLE public.lessons IS 'Bài học: vocabulary, pronunciation, conversation, grammar, listening';
COMMENT ON COLUMN public.lessons.content_json IS 'JSON: nội dung bài học theo từng lesson_type';

-- ─────────────────────────────────────────────
-- TABLE 9: user_lesson_progress
-- Tiến trình học từng bài của user
-- ─────────────────────────────────────────────
CREATE TABLE public.user_lesson_progress (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  lesson_id        UUID NOT NULL REFERENCES public.lessons(id) ON DELETE CASCADE,
  attempts         SMALLINT NOT NULL DEFAULT 0,
  best_score       REAL NOT NULL DEFAULT 0,
  last_score       REAL NOT NULL DEFAULT 0,
  status           lesson_status NOT NULL DEFAULT 'NOT_STARTED',
  time_spent_secs  INTEGER NOT NULL DEFAULT 0,
  first_attempt_at TIMESTAMPTZ,
  completed_at     TIMESTAMPTZ,
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, lesson_id),
  CONSTRAINT score_range CHECK (best_score BETWEEN 0 AND 100)
);

COMMENT ON TABLE public.user_lesson_progress IS 'Tiến trình từng bài học của user: attempts, score, status';

-- ─────────────────────────────────────────────
-- TABLE 10: pronunciation_sessions
-- Kết quả luyện phát âm từng lần
-- ─────────────────────────────────────────────
CREATE TABLE public.pronunciation_sessions (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  lesson_id       UUID REFERENCES public.lessons(id) ON DELETE SET NULL,
  audio_url       TEXT NOT NULL,
  text_reference  TEXT NOT NULL,
  overall_score   REAL NOT NULL DEFAULT 0,
  phoneme_details JSONB NOT NULL DEFAULT '[]',
  word_scores     JSONB NOT NULL DEFAULT '[]',
  intonation_score REAL NOT NULL DEFAULT 0,
  fluency_score   REAL NOT NULL DEFAULT 0,
  duration_ms     INTEGER NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT overall_score_range CHECK (overall_score BETWEEN 0 AND 100)
);

COMMENT ON TABLE public.pronunciation_sessions IS 'Kết quả phân tích phát âm: phoneme scores, waveform data';
COMMENT ON COLUMN public.pronunciation_sessions.phoneme_details IS 'JSON array: [{phoneme, score, start_ms, end_ms}]';
COMMENT ON COLUMN public.pronunciation_sessions.word_scores IS 'JSON array: [{word, score, phonemes[]}]';

-- ─────────────────────────────────────────────
-- TABLE 11: ai_conversations
-- Phiên hội thoại AI
-- ─────────────────────────────────────────────
CREATE TABLE public.ai_conversations (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id        UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  language_code  TEXT NOT NULL DEFAULT 'en',
  mode           conversation_mode NOT NULL DEFAULT 'FREE',
  scenario_id    TEXT,
  ai_persona     TEXT NOT NULL DEFAULT 'friendly_buddy',
  turns_count    SMALLINT NOT NULL DEFAULT 0,
  duration_secs  INTEGER NOT NULL DEFAULT 0,
  fluency_score  REAL NOT NULL DEFAULT 0,
  grammar_errors JSONB NOT NULL DEFAULT '[]',
  new_vocabulary JSONB NOT NULL DEFAULT '[]',
  xp_earned      SMALLINT NOT NULL DEFAULT 0,
  started_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  ended_at       TIMESTAMPTZ
);

COMMENT ON TABLE public.ai_conversations IS 'Phiên hội thoại AI: FREE, ROLEPLAY, IELTS_MOCK';
COMMENT ON COLUMN public.ai_conversations.grammar_errors IS 'JSON array: [{original, correction, explanation}]';
COMMENT ON COLUMN public.ai_conversations.new_vocabulary IS 'JSON array: [{word, definition, example}]';

-- ─────────────────────────────────────────────
-- TABLE 12: conversation_messages
-- Tin nhắn trong phiên hội thoại
-- ─────────────────────────────────────────────
CREATE TABLE public.conversation_messages (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id     UUID NOT NULL REFERENCES public.ai_conversations(id) ON DELETE CASCADE,
  role                TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  content_text        TEXT NOT NULL,
  audio_url           TEXT,
  grammar_corrections JSONB NOT NULL DEFAULT '[]',
  response_time_ms    INTEGER NOT NULL DEFAULT 0,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.conversation_messages IS 'Tin nhắn trong phiên AI conversation — role: user | assistant';

-- ─────────────────────────────────────────────
-- TABLE 13: vocabulary_items
-- Từ vựng của user + SRS data
-- ─────────────────────────────────────────────
CREATE TABLE public.vocabulary_items (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  language_id     UUID NOT NULL REFERENCES public.languages(id),
  word            TEXT NOT NULL,
  translation     TEXT NOT NULL,
  phonetic        TEXT,
  example_sentence TEXT,
  srs_level       SMALLINT NOT NULL DEFAULT 0 CHECK (srs_level BETWEEN 0 AND 5),
  ease_factor     REAL NOT NULL DEFAULT 2.5,
  interval_days   SMALLINT NOT NULL DEFAULT 1,
  next_review_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  correct_count   SMALLINT NOT NULL DEFAULT 0,
  incorrect_count SMALLINT NOT NULL DEFAULT 0,
  added_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.vocabulary_items IS 'Từ vựng của user với SM-2 SRS: ease_factor, interval_days, next_review_at';

-- ─────────────────────────────────────────────
-- TABLE 14: achievements
-- Danh sách thành tích (master data)
-- ─────────────────────────────────────────────
CREATE TABLE public.achievements (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code            TEXT UNIQUE NOT NULL,
  name            TEXT NOT NULL,
  description     TEXT NOT NULL,
  icon_url        TEXT,
  category        TEXT NOT NULL, -- 'STREAK' | 'PRONUNCIATION' | 'CONVERSATION' | 'MILESTONE' | 'SOCIAL'
  unlock_criteria JSONB NOT NULL DEFAULT '{}',
  xp_reward       SMALLINT NOT NULL DEFAULT 0
);

COMMENT ON TABLE public.achievements IS 'Master data: danh sách badges/achievements (50+ items)';
COMMENT ON COLUMN public.achievements.unlock_criteria IS 'JSON: {"streak_days": 7} hoặc {"lessons_completed": 10}';

-- ─────────────────────────────────────────────
-- TABLE 15: user_achievements
-- Thành tích đã đạt của user
-- ─────────────────────────────────────────────
CREATE TABLE public.user_achievements (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id        UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  achievement_id UUID NOT NULL REFERENCES public.achievements(id),
  earned_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, achievement_id)
);

COMMENT ON TABLE public.user_achievements IS 'Thành tích đã unlock của từng user';

-- ─────────────────────────────────────────────
-- TABLE 16: subscriptions
-- Gói subscription của user
-- ─────────────────────────────────────────────
CREATE TABLE public.subscriptions (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  plan              subscription_plan NOT NULL DEFAULT 'FREE',
  status            subscription_status NOT NULL DEFAULT 'ACTIVE',
  started_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  ends_at           TIMESTAMPTZ,
  payment_provider  TEXT,           -- 'stripe' | 'momo' | 'zalopay'
  external_sub_id   TEXT,           -- Stripe subscription ID
  amount_paid       NUMERIC(10,2),
  currency          TEXT NOT NULL DEFAULT 'USD',
  cancelled_at      TIMESTAMPTZ,
  cancel_reason     TEXT
);

COMMENT ON TABLE public.subscriptions IS 'Subscription plans: FREE → PREMIUM_MONTHLY → PREMIUM_ANNUAL → LIFETIME';

-- ─────────────────────────────────────────────
-- TABLE 17: payment_transactions
-- Lịch sử giao dịch thanh toán
-- ─────────────────────────────────────────────
CREATE TABLE public.payment_transactions (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  subscription_id  UUID REFERENCES public.subscriptions(id),
  external_tx_id   TEXT,
  amount           NUMERIC(10,2) NOT NULL,
  currency         TEXT NOT NULL DEFAULT 'USD',
  payment_method   TEXT,           -- 'card' | 'paypal' | 'momo' | 'zalopay'
  status           payment_status NOT NULL DEFAULT 'PENDING',
  provider_response JSONB NOT NULL DEFAULT '{}',
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.payment_transactions IS 'Lịch sử giao dịch: Stripe, MoMo, ZaloPay';

-- ─────────────────────────────────────────────
-- TABLE 18: roadmap_nodes  (THÊM MỚI — từ Figma)
-- Node trong skill-tree học tập
-- ─────────────────────────────────────────────
CREATE TABLE public.roadmap_nodes (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  course_id     UUID NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
  lesson_id     UUID REFERENCES public.lessons(id) ON DELETE SET NULL,
  label         TEXT NOT NULL,
  description   TEXT,
  node_type     TEXT NOT NULL DEFAULT 'lesson', -- 'lesson' | 'checkpoint' | 'boss'
  position_x    REAL NOT NULL DEFAULT 0,
  position_y    REAL NOT NULL DEFAULT 0,
  parent_ids    UUID[] NOT NULL DEFAULT '{}',  -- IDs of prerequisite nodes
  sort_order    SMALLINT NOT NULL DEFAULT 0
);

COMMENT ON TABLE public.roadmap_nodes IS 'Node trong skill-tree/roadmap: vị trí, prerequisite, loại node';
COMMENT ON COLUMN public.roadmap_nodes.parent_ids IS 'Array: UUID[] của các node phải hoàn thành trước';
COMMENT ON COLUMN public.roadmap_nodes.node_type IS 'lesson | checkpoint | boss (difficulty gates)';

-- ═══════════════════════════════════════════════════════════════════
-- INDEXES
-- ═══════════════════════════════════════════════════════════════════

-- users
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_users_role ON public.users(role) WHERE is_active = true;

-- user_profiles
CREATE INDEX idx_profiles_level ON public.user_profiles(current_level);
CREATE INDEX idx_profiles_xp ON public.user_profiles(xp_total DESC);
CREATE INDEX idx_profiles_streak ON public.user_profiles(current_streak DESC);

-- ui_events (partitioned)
CREATE INDEX idx_ui_events_user_event ON public.ui_events(user_id, event_name);
CREATE INDEX idx_ui_events_time ON public.ui_events(occurred_at DESC);

-- pronunciation_sessions
CREATE INDEX idx_pron_user_time ON public.pronunciation_sessions(user_id, created_at DESC);
CREATE INDEX idx_pron_score ON public.pronunciation_sessions(overall_score);

-- ai_conversations
CREATE INDEX idx_conv_user_time ON public.ai_conversations(user_id, started_at DESC);

-- vocabulary_items (SRS queue)
CREATE INDEX idx_vocab_review ON public.vocabulary_items(user_id, next_review_at)
  WHERE next_review_at <= now() + INTERVAL '1 day';

-- Full-text search trên vocabulary
CREATE INDEX idx_vocab_word_trgm ON public.vocabulary_items
  USING GIN (word gin_trgm_ops);

-- ═══════════════════════════════════════════════════════════════════
-- TRIGGERS — auto-update updated_at
-- ═══════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_preferences_updated_at
  BEFORE UPDATE ON public.user_preferences
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_progress_updated_at
  BEFORE UPDATE ON public.user_lesson_progress
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ═══════════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY (RLS)
-- ═══════════════════════════════════════════════════════════════════

-- Enable RLS on all user-data tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ui_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_lesson_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pronunciation_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vocabulary_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_transactions ENABLE ROW LEVEL SECURITY;

-- Public read tables (no RLS needed for non-sensitive)
ALTER TABLE public.languages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roadmap_nodes ENABLE ROW LEVEL SECURITY;

-- ── users policies ──
CREATE POLICY "Users: self read"
  ON public.users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users: self update"
  ON public.users FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Admins: read all users"
  ON public.users FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM public.users u WHERE u.id = auth.uid() AND u.role = 'ADMIN')
  );

-- ── user_profiles policies ──
CREATE POLICY "Profiles: self CRUD"
  ON public.user_profiles FOR ALL
  USING (auth.uid() = user_id);

-- ── user_preferences policies ──
CREATE POLICY "Preferences: self CRUD"
  ON public.user_preferences FOR ALL
  USING (auth.uid() = user_id);

-- ── ui_events policies ──
CREATE POLICY "Events: self insert"
  ON public.ui_events FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Events: self read"
  ON public.ui_events FOR SELECT
  USING (auth.uid() = user_id);

-- ── learning_goals policies ──
CREATE POLICY "Goals: self CRUD"
  ON public.learning_goals FOR ALL
  USING (auth.uid() = user_id);

-- ── user_lesson_progress policies ──
CREATE POLICY "Progress: self CRUD"
  ON public.user_lesson_progress FOR ALL
  USING (auth.uid() = user_id);

-- ── pronunciation_sessions policies ──
CREATE POLICY "PronSessions: self CRUD"
  ON public.pronunciation_sessions FOR ALL
  USING (auth.uid() = user_id);

-- ── ai_conversations policies ──
CREATE POLICY "Conversations: self CRUD"
  ON public.ai_conversations FOR ALL
  USING (auth.uid() = user_id);

-- ── conversation_messages policies ──
CREATE POLICY "Messages: self via conversation"
  ON public.conversation_messages FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.ai_conversations c
      WHERE c.id = conversation_id AND c.user_id = auth.uid()
    )
  );

-- ── vocabulary_items policies ──
CREATE POLICY "Vocabulary: self CRUD"
  ON public.vocabulary_items FOR ALL
  USING (auth.uid() = user_id);

-- ── user_achievements policies ──
CREATE POLICY "Achievements: self read"
  ON public.user_achievements FOR SELECT
  USING (auth.uid() = user_id);

-- ── subscriptions policies ──
CREATE POLICY "Subscriptions: self read"
  ON public.subscriptions FOR SELECT
  USING (auth.uid() = user_id);

-- ── payment_transactions policies ──
CREATE POLICY "Payments: self read"
  ON public.payment_transactions FOR SELECT
  USING (auth.uid() = user_id);

-- ── Public read policies (master data) ──
CREATE POLICY "Languages: public read"
  ON public.languages FOR SELECT USING (true);

CREATE POLICY "Courses: public read active"
  ON public.courses FOR SELECT USING (is_active = true);

CREATE POLICY "Lessons: read by subscription"
  ON public.lessons FOR SELECT
  USING (
    is_premium = false
    OR EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid()
        AND s.status = 'ACTIVE'
        AND s.plan != 'FREE'
    )
  );

CREATE POLICY "Achievements: public read"
  ON public.achievements FOR SELECT USING (true);

CREATE POLICY "Roadmap: public read"
  ON public.roadmap_nodes FOR SELECT USING (true);
