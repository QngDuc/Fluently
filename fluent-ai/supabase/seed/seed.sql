-- ═══════════════════════════════════════════════════════════════════
-- FLUENT AI — Seed Data
-- ═══════════════════════════════════════════════════════════════════

-- ── Languages ──
INSERT INTO public.languages (code, name, native_name, flag_emoji, sort_order) VALUES
  ('en', 'English',  'English',  '🇺🇸', 1),
  ('ja', 'Japanese', '日本語',    '🇯🇵', 2),
  ('ko', 'Korean',   '한국어',    '🇰🇷', 3),
  ('zh', 'Chinese',  '中文',      '🇨🇳', 4),
  ('fr', 'French',   'Français',  '🇫🇷', 5)
ON CONFLICT (code) DO NOTHING;

-- ── Courses (English) ──
WITH en AS (SELECT id FROM public.languages WHERE code = 'en')
INSERT INTO public.courses (language_id, title, description, level, sort_order) VALUES
  ((SELECT id FROM en), 'Daily Conversations', 'Hội thoại hàng ngày cho người mới bắt đầu', 'A1', 1),
  ((SELECT id FROM en), 'Travel English',      'Tiếng Anh cho du lịch: sân bay, khách sạn, nhà hàng', 'A2', 2),
  ((SELECT id FROM en), 'Business English',    'Tiếng Anh thương mại: meeting, email, presentation', 'B1', 3),
  ((SELECT id FROM en), 'IELTS Preparation',   'Luyện thi IELTS 6.0–7.0: 4 kỹ năng', 'B2', 4),
  ((SELECT id FROM en), 'Academic English',    'Tiếng Anh học thuật: essays, research, debate', 'C1', 5)
ON CONFLICT DO NOTHING;

-- ── Achievements ──
INSERT INTO public.achievements (code, name, description, category, xp_reward, unlock_criteria) VALUES
  ('first_lesson',   'First Step',       'Hoàn thành bài học đầu tiên',          'MILESTONE',     50,   '{"lessons_completed": 1}'),
  ('streak_3',       '3-Day Streak',     'Học liên tục 3 ngày',                  'STREAK',         30,  '{"streak_days": 3}'),
  ('streak_7',       '7-Day Streak',     'Học liên tục 7 ngày',                  'STREAK',        100,  '{"streak_days": 7}'),
  ('streak_30',      '30-Day Streak',    'Học liên tục 30 ngày',                 'STREAK',        500,  '{"streak_days": 30}'),
  ('streak_100',     '100-Day Streak',   'Học liên tục 100 ngày',                'STREAK',       2000,  '{"streak_days": 100}'),
  ('perfect_score',  'Perfect!',         'Đạt điểm 100/100 phát âm',             'PRONUNCIATION', 150,  '{"pron_score": 100}'),
  ('pron_50',        'Pronunciation Pro','Hoàn thành 50 bài luyện phát âm',      'PRONUNCIATION', 300,  '{"pron_sessions": 50}'),
  ('conv_10',        'Chatterbox',       'Hoàn thành 10 buổi AI conversation',   'CONVERSATION',  200,  '{"conversations": 10}'),
  ('conv_50',        'Fluent Talker',    'Hoàn thành 50 buổi AI conversation',   'CONVERSATION', 1000,  '{"conversations": 50}'),
  ('level_a2',       'A2 Achiever',      'Đạt trình độ A2',                      'MILESTONE',     100,  '{"level": "A2"}'),
  ('level_b1',       'B1 Achiever',      'Đạt trình độ B1',                      'MILESTONE',     300,  '{"level": "B1"}'),
  ('level_b2',       'B2 Achiever',      'Đạt trình độ B2',                      'MILESTONE',     700,  '{"level": "B2"}'),
  ('level_c1',       'C1 Expert',        'Đạt trình độ C1',                      'MILESTONE',    1500,  '{"level": "C1"}'),
  ('xp_1000',        'XP Hunter',        'Tích lũy 1,000 XP',                    'MILESTONE',     100,  '{"xp_total": 1000}'),
  ('xp_10000',       'XP Master',        'Tích lũy 10,000 XP',                   'MILESTONE',     500,  '{"xp_total": 10000}'),
  ('vocab_50',       'Word Learner',     'Học 50 từ vựng',                       'MILESTONE',     100,  '{"vocabulary": 50}'),
  ('vocab_200',      'Word Collector',   'Học 200 từ vựng',                      'MILESTONE',     400,  '{"vocabulary": 200}'),
  ('early_bird',     'Early Bird',       'Học trước 8 giờ sáng 5 lần',           'MILESTONE',     150,  '{"early_sessions": 5}'),
  ('night_owl',      'Night Owl',        'Học sau 22 giờ 5 lần',                 'MILESTONE',     150,  '{"night_sessions": 5}'),
  ('first_premium',  'Premium Member',   'Nâng cấp lên Premium',                  'MILESTONE',     200,  '{"plan": "PREMIUM"}')
ON CONFLICT (code) DO NOTHING;
