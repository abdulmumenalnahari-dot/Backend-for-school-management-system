CREATE TYPE school_level AS ENUM ('ابتدائي', 'متوسط');
CREATE TYPE gender_type AS ENUM ('ذكر', 'أنثى');
CREATE TYPE student_status AS ENUM ('نشط', 'منفصل', 'متخرج', 'منقول');
CREATE TYPE teacher_status AS ENUM ('نشط', 'موقف', 'مستقيل');
CREATE TYPE payment_method AS ENUM ('نقدًا', 'تحويل بنكي', 'بطاقة ائتمان', 'شيك');
CREATE TYPE attendance_status AS ENUM ('حاضر', 'غائب', 'متأخر', 'إجازة');
CREATE TYPE semester_type AS ENUM ('أول', 'ثاني');
CREATE TYPE term_type AS ENUM ('أول', 'ثاني', 'ثالث');
CREATE TYPE note_type AS ENUM ('أكاديمي', 'سلوكي', 'صحي', 'مالي');
CREATE TYPE notification_type AS ENUM ('مهم', 'عادي', 'تنبيه');
CREATE TYPE user_role AS ENUM ('مدير', 'معلم', 'موظف استقبال', 'ولي أمر');
CREATE TYPE day_of_week AS ENUM ('السبت', 'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة');

CREATE TABLE IF NOT EXISTS academic_years (
    id SERIAL PRIMARY KEY,
    name VARCHAR(20) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_current BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (name)
);

CREATE TABLE IF NOT EXISTS classes (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    level school_level NOT NULL,
    order_number SMALLINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sections (
    id SERIAL PRIMARY KEY,
    class_id INT NOT NULL,
    name VARCHAR(10) NOT NULL,
    capacity INT DEFAULT 40,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
    UNIQUE (class_id, name)
);

CREATE TABLE IF NOT EXISTS students (
  id VARCHAR(20) PRIMARY KEY,
  user_id INT,
  first_name VARCHAR(50) NOT NULL,
  middle_name VARCHAR(50) NOT NULL,
  third_name VARCHAR(50) NOT NULL,
  family_name VARCHAR(50) NOT NULL,
  full_name VARCHAR(200) GENERATED ALWAYS AS (first_name || ' ' || middle_name || ' ' || third_name || ' ' || family_name) STORED,
  gender gender_type NOT NULL,
  birth_date DATE NOT NULL,
  nationality VARCHAR(50) NOT NULL DEFAULT 'يمني',
  religion VARCHAR(30) DEFAULT 'إسلام',
  address TEXT,
  emergency_contact VARCHAR(15),
  medical_conditions TEXT,
  blood_type VARCHAR(10),
  parent_guardian_name VARCHAR(100),
  parent_guardian_relation VARCHAR(20),
  parent_phone VARCHAR(15),
  parent_email VARCHAR(100),
  parent_occupation VARCHAR(100),
  parent_work_address TEXT,
  admission_date DATE,
  section_id INT,
  academic_year_id INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (section_id) REFERENCES sections(id) ON DELETE SET NULL,
  FOREIGN KEY (academic_year_id) REFERENCES academic_years(id) ON DELETE SET NULL,
  UNIQUE (id)
);

CREATE TABLE IF NOT EXISTS teachers (
    id VARCHAR(20) PRIMARY KEY,
    user_id INT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    full_name VARCHAR(100) GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED,
    gender gender_type NOT NULL,
    birth_date DATE NOT NULL,
    nationality VARCHAR(50) NOT NULL DEFAULT 'يمني',
    religion VARCHAR(30) DEFAULT 'إسلام',
    address TEXT,
    phone VARCHAR(15) NOT NULL,
    email VARCHAR(100) NOT NULL,
    qualification VARCHAR(100) NOT NULL,
    specialization VARCHAR(100) NOT NULL,
    hire_date DATE NOT NULL,
    salary DECIMAL(10, 2) NOT NULL,
    status teacher_status DEFAULT 'نشط',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (email)
);

CREATE TABLE IF NOT EXISTS subjects (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) NOT NULL,
    description TEXT,
    class_level school_level NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (code)
);

CREATE TABLE IF NOT EXISTS courses (
    id SERIAL PRIMARY KEY,
    subject_id INT NOT NULL,
    class_id INT NOT NULL,
    teacher_id VARCHAR(20) NOT NULL,
    academic_year_id INT NOT NULL,
    semester semester_type NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
    FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id) ON DELETE CASCADE,
    UNIQUE (subject_id, class_id, academic_year_id, semester)
);

CREATE TABLE IF NOT EXISTS attendance (
    id SERIAL PRIMARY KEY,
    student_id VARCHAR(20) NOT NULL,
    date DATE NOT NULL,
    status attendance_status NOT NULL,
    time_in TIME,
    time_out TIME,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    UNIQUE (student_id, date)
);

CREATE TABLE IF NOT EXISTS fee_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    amount DECIMAL(10, 2) NOT NULL,
    class_id INT,
    is_mandatory BOOLEAN DEFAULT TRUE,
    due_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
    UNIQUE (name, class_id)
);

CREATE TABLE IF NOT EXISTS payments (
    id SERIAL PRIMARY KEY,
    student_id VARCHAR(20) NOT NULL,
    fee_type_id INT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    payment_date DATE NOT NULL,
    payment_method payment_method NOT NULL,
    receipt_number VARCHAR(50),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (fee_type_id) REFERENCES fee_types(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS discounts (
    id SERIAL PRIMARY KEY,
    student_id VARCHAR(20) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    percentage DECIMAL(5, 2),
    reason VARCHAR(255) NOT NULL,
    academic_year_id INT NOT NULL,
    approved_by VARCHAR(20) NOT NULL,
    approval_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS schedules (
    id SERIAL PRIMARY KEY,
    section_id INT NOT NULL,
    course_id INT NOT NULL,
    day_of_week day_of_week NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    room_number VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (section_id) REFERENCES sections(id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE,
    UNIQUE (section_id, day_of_week, start_time, end_time)
);

CREATE TABLE IF NOT EXISTS academic_results (
    id SERIAL PRIMARY KEY,
    student_id VARCHAR(20) NOT NULL,
    course_id INT NOT NULL,
    academic_year_id INT NOT NULL,
    semester semester_type NOT NULL,
    term term_type NOT NULL,
    total_marks DECIMAL(5, 2) NOT NULL,
    obtained_marks DECIMAL(5, 2) NOT NULL,
    grade_letter VARCHAR(5),
    comments TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE,
    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id) ON DELETE CASCADE,
    UNIQUE (student_id, course_id, academic_year_id, semester, term)
);

CREATE TABLE IF NOT EXISTS notes (
    id SERIAL PRIMARY KEY,
    student_id VARCHAR(20) NOT NULL,
    teacher_id VARCHAR(20) NOT NULL,
    note_type note_type NOT NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    password VARCHAR(255) NOT NULL,
    role user_role NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (username),
    UNIQUE (email)
);

CREATE TABLE IF NOT EXISTS user_student_relations (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    student_id VARCHAR(20) NOT NULL,
    relation VARCHAR(20) NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    UNIQUE (user_id, student_id, relation)
);

CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type notification_type DEFAULT 'عادي',
    is_read BOOLEAN DEFAULT FALSE,
    target_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS settings (
    id SERIAL PRIMARY KEY,
    setting_key VARCHAR(100) NOT NULL,
    setting_value TEXT NOT NULL,
    description VARCHAR(255),
    group_name VARCHAR(50) DEFAULT 'عام',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (setting_key)
);

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_classes_updated_at BEFORE UPDATE ON classes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_sections_updated_at BEFORE UPDATE ON sections FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_students_updated_at BEFORE UPDATE ON students FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_teachers_updated_at BEFORE UPDATE ON teachers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_subjects_updated_at BEFORE UPDATE ON subjects FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_academic_years_updated_at BEFORE UPDATE ON academic_years FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_courses_updated_at BEFORE UPDATE ON courses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_attendance_updated_at BEFORE UPDATE ON attendance FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_fee_types_updated_at BEFORE UPDATE ON fee_types FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_discounts_updated_at BEFORE UPDATE ON discounts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_schedules_updated_at BEFORE UPDATE ON schedules FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_academic_results_updated_at BEFORE UPDATE ON academic_results FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_notes_updated_at BEFORE UPDATE ON notes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_student_relations_updated_at BEFORE UPDATE ON user_student_relations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_notifications_updated_at BEFORE UPDATE ON notifications FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_settings_updated_at BEFORE UPDATE ON settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

INSERT INTO academic_years (name, start_date, end_date, is_current) VALUES
('2024-2025', '2024-09-01', '2025-06-30', TRUE),
('2023-2024', '2023-09-01', '2024-06-30', FALSE);

INSERT INTO classes (name, level, order_number) VALUES
('الصف الأول الابتدائي', 'ابتدائي', 1),
('الصف الثاني الابتدائي', 'ابتدائي', 2),
('الصف الثالث الابتدائي', 'ابتدائي', 3),
('الصف الرابع الابتدائي', 'ابتدائي', 4),
('الصف الخامس الابتدائي', 'ابتدائي', 5),
('الصف السادس الابتدائي', 'ابتدائي', 6),
('الصف الأول المتوسط', 'متوسط', 7),
('الصف الثاني المتوسط', 'متوسط', 8),
('الصف الثالث المتوسط', 'متوسط', 9);

INSERT INTO sections (class_id, name)
SELECT id, 'أ' FROM classes;
INSERT INTO sections (class_id, name)
SELECT id, 'ب' FROM classes;
INSERT INTO sections (class_id, name)
SELECT id, 'ج' FROM classes;

INSERT INTO subjects (name, code, description, class_level) VALUES
('القرآن الكريم', 'QURAN', 'حفظ وتلاوة وتجويد وفهم معاني الآيات', 'ابتدائي'),
('اللغة العربية', 'ARAB', 'قراءة، كتابة، نحو، بلاغة، أدب', 'ابتدائي'),
('الرياضيات', 'MATH', 'الأعداد، العمليات، الكسور، الهندسة', 'ابتدائي'),
('العلوم', 'SCI', 'العالم الطبيعي، البيئة، الفيزياء الأساسية', 'ابتدائي'),
('الدراسات الاجتماعية', 'SST', 'التاريخ المحلي، الجغرافيا، المواطنة', 'ابتدائي'),
('التربية الإسلامية', 'ISLAMIC', 'العقيدة، العبادات، الأخلاق، السيرة', 'ابتدائي'),
('اللغة الإنجليزية', 'ENGL', 'مهارات الاستماع والتحدث والقراءة والكتابة', 'متوسط');

INSERT INTO fee_types (name, description, amount, class_id, is_mandatory, due_date)
SELECT 'الرسوم الدراسية', 'الرسوم الأساسية للعام الدراسي', 120000, id, TRUE, '2024-09-15' FROM classes;
INSERT INTO fee_types (name, description, amount, class_id, is_mandatory, due_date)
SELECT 'الكتب والمستلزمات', 'تكلفة الكتب والكراسات والأدوات', 35000, id, TRUE, '2024-09-15' FROM classes;
INSERT INTO fee_types (name, description, amount, class_id, is_mandatory, due_date)
SELECT 'الأنشطة المدرسية', 'أنشطة ثقافية، رياضية، مسرحية', 20000, id, TRUE, '2024-09-15' FROM classes;

INSERT INTO settings (setting_key, setting_value, description, group_name) VALUES
('school_name', 'مدرسة الفجر النموذجية', 'اسم المدرسة', 'عام'),
('school_address', 'صنعاء، شارع الزبيري، الحي السياسي', 'عنوان المدرسة', 'عام'),
('school_phone', '+9671442233', 'رقم هاتف المدرسة', 'عام'),
('school_email', 'info@al-fajr.edu.ye', 'البريد الإلكتروني للمدرسة', 'عام'),
('currency', 'ر.ي', 'العملة المستخدمة', 'عام'),
('attendance_start_time', '07:30:00', 'وقت بداية الحضور', 'الحضور'),
('attendance_end_time', '13:30:00', 'وقت نهاية الدوام', 'الحضور'),
('late_threshold', '10', 'الحد الأقصى للتأخير بالدقائق', 'الحضور'),
('max_absences', '12', 'الحد الأقصى للغياب قبل الإنذار', 'الحضور');

INSERT INTO teachers (id, first_name, last_name, gender, birth_date, phone, email, qualification, specialization, hire_date, salary, status)
VALUES
('T001', 'أحمد', 'المحمدي', 'ذكر', '1985-03-15', '770123456', 'ahmed@school.ye', 'ماجستير تربية', 'اللغة العربية', '2020-08-01', 150000, 'نشط'),
('T002', 'فاطمة', 'السعيدي', 'أنثى', '1990-06-20', '770987654', 'fatima@school.ye', 'بكالوريوس تربية', 'القرآن الكريم', '2019-08-01', 130000, 'نشط'),
('T003', 'محمد', 'الرضوان', 'ذكر', '1988-11-10', '770223344', 'mohammed@school.ye', 'بكالوريوس رياضيات', 'الرياضيات', '2018-08-01', 140000, 'نشط'),
('T004', 'نادية', 'الوهبي', 'أنثى', '1992-01-05', '770334455', 'nadia@school.ye', 'بكالوريوس علوم', 'العلوم', '2021-08-01', 135000, 'نشط'),
('T005', 'سامي', 'الحميدي', 'ذكر', '1987-07-14', '770445566', 'sami@school.ye', 'بكالوريوس دراسات اجتماعية', 'الدراسات الاجتماعية', '2017-08-01', 138000, 'نشط'),
('T006', 'إيمان', 'الشامي', 'أنثى', '1991-09-22', '770556677', 'iman@school.ye', 'ماجستير تربية إسلامية', 'التربية الإسلامية', '2020-08-01', 142000, 'نشط'),
('T007', 'خالد', 'المرتضى', 'ذكر', '1989-12-30', '770667788', 'khaled@school.ye', 'دبلوم لغة إنجليزية', 'اللغة الإنجليزية', '2019-08-01', 137000, 'نشط');

DO $$
DECLARE
    current_year_id INT;
BEGIN
    SELECT id INTO current_year_id FROM academic_years WHERE is_current = TRUE LIMIT 1;

    INSERT INTO courses (subject_id, class_id, teacher_id, academic_year_id, semester)
    SELECT s.id, c.id,
           CASE s.code
             WHEN 'QURAN' THEN 'T002'
             WHEN 'ARAB' THEN 'T001'
             WHEN 'MATH' THEN 'T003'
             WHEN 'SCI' THEN 'T004'
           END,
           current_year_id, 'أول'
    FROM subjects s
    CROSS JOIN classes c
    WHERE c.order_number IN (1,2)
      AND s.code IN ('QURAN', 'ARAB', 'MATH', 'SCI');

    INSERT INTO courses (subject_id, class_id, teacher_id, academic_year_id, semester)
    SELECT s.id, c.id,
           CASE s.code
             WHEN 'SST' THEN 'T005'
             ELSE
               CASE s.code
                 WHEN 'QURAN' THEN 'T002'
                 WHEN 'ARAB' THEN 'T001'
                 WHEN 'MATH' THEN 'T003'
                 WHEN 'SCI' THEN 'T004'
               END
           END,
           current_year_id, 'أول'
    FROM subjects s
    CROSS JOIN classes c
    WHERE c.order_number IN (3,4)
      AND s.code IN ('QURAN', 'ARAB', 'MATH', 'SCI', 'SST');

    INSERT INTO courses (subject_id, class_id, teacher_id, academic_year_id, semester)
    SELECT s.id, c.id,
           CASE s.code
             WHEN 'ISLAMIC' THEN 'T006'
             WHEN 'SST' THEN 'T005'
             ELSE
               CASE s.code
                 WHEN 'QURAN' THEN 'T002'
                 WHEN 'ARAB' THEN 'T001'
                 WHEN 'MATH' THEN 'T003'
                 WHEN 'SCI' THEN 'T004'
               END
           END,
           current_year_id, 'أول'
    FROM subjects s
    CROSS JOIN classes c
    WHERE c.order_number IN (5,6)
      AND s.code IN ('QURAN', 'ARAB', 'MATH', 'SCI', 'SST', 'ISLAMIC');

    INSERT INTO courses (subject_id, class_id, teacher_id, academic_year_id, semester)
    SELECT s.id, c.id,
           CASE s.code
             WHEN 'ENGL' THEN 'T007'
             WHEN 'ISLAMIC' THEN 'T006'
             WHEN 'SST' THEN 'T005'
             ELSE
               CASE s.code
                 WHEN 'QURAN' THEN 'T002'
                 WHEN 'ARAB' THEN 'T001'
                 WHEN 'MATH' THEN 'T003'
                 WHEN 'SCI' THEN 'T004'
               END
           END,
           current_year_id, 'أول'
    FROM subjects s
    CROSS JOIN classes c
    WHERE c.order_number IN (7,8,9)
      AND s.code IN ('QURAN', 'ARAB', 'MATH', 'SCI', 'SST', 'ISLAMIC', 'ENGL');

    INSERT INTO courses (subject_id, class_id, teacher_id, academic_year_id, semester)
    SELECT subject_id, class_id, teacher_id, academic_year_id, 'ثاني'
    FROM courses
    WHERE semester = 'أول';
END $$;

CREATE OR REPLACE VIEW student_summary AS
SELECT
    s.id AS student_id,
    s.first_name || ' ' || s.last_name AS full_name,
    c.name AS class_name,
    sec.name AS section_name,
    COUNT(CASE WHEN a.status = 'حاضر' THEN 1 END) AS present_days,
    COUNT(CASE WHEN a.status = 'غائب' THEN 1 END) AS absent_days,
    COUNT(CASE WHEN a.status = 'متأخر' THEN 1 END) AS late_days,
    COUNT(a.id) AS total_days,
    ROUND((COUNT(CASE WHEN a.status = 'حاضر' THEN 1 END) * 100.0 / NULLIF(COUNT(a.id), 0)), 2) AS attendance_rate,
    SUM(f.amount) AS total_fees,
    COALESCE(SUM(p.amount), 0) AS paid_amount,
    (SUM(f.amount) - COALESCE(SUM(p.amount), 0)) AS pending_amount
FROM students s
JOIN sections sec ON s.section_id = sec.id
JOIN classes c ON sec.class_id = c.id
LEFT JOIN attendance a ON s.id = a.student_id AND a.date >= CURRENT_DATE - INTERVAL '30 days'
LEFT JOIN fee_types f ON f.class_id = c.id
LEFT JOIN payments p ON s.id = p.student_id
GROUP BY s.id, s.first_name, s.last_name, c.name, sec.name;

CREATE OR REPLACE FUNCTION GetAttendanceRate(student_id VARCHAR(20), days INT) RETURNS DECIMAL(5,2) AS $$
DECLARE
    total_days INT;
    present_days INT;
    rate DECIMAL(5,2);
BEGIN
    SELECT COUNT(*) INTO total_days
    FROM attendance
    WHERE student_id = student_id AND date >= CURRENT_DATE - (days || ' days')::INTERVAL;

    SELECT COUNT(*) INTO present_days
    FROM attendance
    WHERE student_id = student_id AND status = 'حاضر' AND date >= CURRENT_DATE - (days || ' days')::INTERVAL;

    IF total_days = 0 THEN
        RETURN 100.00;
    ELSE
        rate := (present_days * 100.0) / total_days;
        RETURN ROUND(rate, 2);
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION check_absence_limit_func() RETURNS TRIGGER AS $$
DECLARE
    absences INT;
    max_absences INT;
BEGIN
    SELECT setting_value::INT INTO max_absences FROM settings WHERE setting_key = 'max_absences';
    SELECT COUNT(*) INTO absences FROM attendance
    WHERE student_id = NEW.student_id AND status = 'غائب' AND date >= NEW.date - INTERVAL '30 days';

    IF absences >= max_absences THEN
        UPDATE students SET status = 'منفصل' WHERE id = NEW.student_id;
        INSERT INTO notes (student_id, teacher_id, note_type, title, content)
        VALUES (NEW.student_id, 'ADMIN', 'سلوكي', 'تحذير غياب',
                'تم فصل الطالب بسبب تجاوز الحد الأقصى للغياب (' || max_absences || ' يوم)');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_absence_limit AFTER INSERT ON attendance FOR EACH ROW EXECUTE FUNCTION check_absence_limit_func();

CREATE INDEX idx_students_class ON students(section_id);
CREATE INDEX idx_students_academic_year ON students(academic_year_id);
CREATE INDEX idx_students_status ON students(status);
CREATE INDEX idx_attendance_student_date ON attendance(student_id, date);
CREATE INDEX idx_attendance_date_status ON attendance(date, status);
CREATE INDEX idx_payments_student ON payments(student_id);
CREATE INDEX idx_payments_date ON payments(payment_date);
CREATE INDEX idx_payments_fee_type ON payments(fee_type_id);
CREATE INDEX idx_results_student ON academic_results(student_id);
CREATE INDEX idx_results_course ON academic_results(course_id);
CREATE INDEX idx_results_year_semester ON academic_results(academic_year_id, semester);