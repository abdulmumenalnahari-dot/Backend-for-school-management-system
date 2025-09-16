
CREATE TABLE IF NOT EXISTS classes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    level ENUM('ابتدائي', 'متوسط') NOT NULL,
    order_number TINYINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_class_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- جدول الشُعب
CREATE TABLE IF NOT EXISTS sections (
    id INT AUTO_INCREMENT PRIMARY KEY,
    class_id INT NOT NULL,
    name VARCHAR(10) NOT NULL,
    capacity INT DEFAULT 40,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
    UNIQUE KEY unique_section (class_id, name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- جدول الطلاب
CREATE TABLE IF NOT EXISTS students (
    id VARCHAR(20) PRIMARY KEY,
    user_id INT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    full_name VARCHAR(100) GENERATED ALWAYS AS (CONCAT(first_name, ' ', last_name)) VIRTUAL,
    gender ENUM('ذكر', 'أنثى') NOT NULL,
    birth_date DATE NOT NULL,
    nationality VARCHAR(50) NOT NULL DEFAULT 'يمني',
    religion VARCHAR(30) DEFAULT 'إسلام',
    address TEXT,
    emergency_contact VARCHAR(15),
    medical_conditions TEXT,
    blood_type VARCHAR(5) COMMENT 'فصيلة الدم',
    parent_guardian_name VARCHAR(100) NOT NULL,
    parent_guardian_relation VARCHAR(20) NOT NULL,
    parent_phone VARCHAR(15) NOT NULL,
    parent_email VARCHAR(100),
    parent_occupation VARCHAR(100),
    parent_work_address TEXT,
    admission_date DATE NOT NULL,
    status ENUM('نشط', 'منفصل', 'متخرج', 'منقول') DEFAULT 'نشط',
    section_id INT NOT NULL,
    academic_year_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (section_id) REFERENCES sections(id) ON DELETE RESTRICT,
    INDEX idx_student_name (first_name, last_name),
    INDEX idx_student_section (section_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- جدول المعلمين
CREATE TABLE IF NOT EXISTS teachers (
    id VARCHAR(20) PRIMARY KEY,
    user_id INT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    full_name VARCHAR(100) GENERATED ALWAYS AS (CONCAT(first_name, ' ', last_name)) VIRTUAL,
    gender ENUM('ذكر', 'أنثى') NOT NULL,
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
    status ENUM('نشط', 'موقف', 'مستقيل') DEFAULT 'نشط',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_teacher_email (email),
    INDEX idx_teacher_name (first_name, last_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- جدول المواد الدراسية
CREATE TABLE IF NOT EXISTS subjects (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) NOT NULL,
    description TEXT,
    class_level ENUM('ابتدائي', 'متوسط') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_subject_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- جدول الأعوام الدراسية
CREATE TABLE IF NOT EXISTS academic_years (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(20) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_current BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_academic_year (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- جدول المقررات الدراسية
CREATE TABLE IF NOT EXISTS courses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    subject_id INT NOT NULL,
    class_id INT NOT NULL,
    teacher_id VARCHAR(20) NOT NULL,
    academic_year_id INT NOT NULL,
    semester ENUM('أول', 'ثاني') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
    FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id) ON DELETE CASCADE,
    UNIQUE KEY unique_course (subject_id, class_id, academic_year_id, semester)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- جدول الحضور والغياب
CREATE TABLE IF NOT EXISTS attendance (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id VARCHAR(20) NOT NULL,
    date DATE NOT NULL,
    status ENUM('حاضر', 'غائب', 'متأخر', 'إجازة') NOT NULL,
    time_in TIME,
    time_out TIME,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    UNIQUE KEY unique_attendance (student_id, date),
    INDEX idx_attendance_date (date),
    INDEX idx_attendance_student (student_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- جدول الرسوم الدراسية
CREATE TABLE IF NOT EXISTS fee_types (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    amount DECIMAL(10, 2) NOT NULL,
    class_id INT,
    is_mandatory BOOLEAN DEFAULT TRUE,
    due_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
    UNIQUE KEY unique_fee_type (name, class_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- جدول الدفعات
CREATE TABLE IF NOT EXISTS payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id VARCHAR(20) NOT NULL,
    fee_type_id INT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    payment_date DATE NOT NULL,
    payment_method ENUM('نقدًا', 'تحويل بنكي', 'بطاقة ائتمان', 'شيك') NOT NULL,
    receipt_number VARCHAR(50),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (fee_type_id) REFERENCES fee_types(id) ON DELETE CASCADE,
    INDEX idx_payment_student (student_id),
    INDEX idx_payment_date (payment_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- جدول الخصومات
CREATE TABLE IF NOT EXISTS discounts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id VARCHAR(20) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    percentage DECIMAL(5, 2),
    reason VARCHAR(255) NOT NULL,
    academic_year_id INT NOT NULL,
    approved_by VARCHAR(20) NOT NULL,
    approval_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- جدول الجدول الدراسي
CREATE TABLE IF NOT EXISTS schedules (
    id INT AUTO_INCREMENT PRIMARY KEY,
    section_id INT NOT NULL,
    course_id INT NOT NULL,
    day_of_week ENUM('السبت', 'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة') NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    room_number VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (section_id) REFERENCES sections(id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE,
    UNIQUE KEY unique_schedule (section_id, day_of_week, start_time, end_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- جدول النتائج الأكاديمية
CREATE TABLE IF NOT EXISTS academic_results (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id VARCHAR(20) NOT NULL,
    course_id INT NOT NULL,
    academic_year_id INT NOT NULL,
    semester ENUM('أول', 'ثاني') NOT NULL,
    term ENUM('أول', 'ثاني', 'ثالث') NOT NULL,
    total_marks DECIMAL(5, 2) NOT NULL,
    obtained_marks DECIMAL(5, 2) NOT NULL,
    grade_letter VARCHAR(5),
    comments TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE,
    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id) ON DELETE CASCADE,
    UNIQUE KEY unique_result (student_id, course_id, academic_year_id, semester, term)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- جدول الملاحظات
CREATE TABLE IF NOT EXISTS notes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id VARCHAR(20) NOT NULL,
    teacher_id VARCHAR(20) NOT NULL,
    note_type ENUM('أكاديمي', 'سلوكي', 'صحي', 'مالي') NOT NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    INDEX idx_note_student (student_id),
    INDEX idx_note_type (note_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- جدول المستخدمين
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('مدير', 'معلم', 'موظف استقبال', 'ولي أمر') NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_username (username),
    UNIQUE KEY unique_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- جدول وصلات المستخدمين مع الطلاب
CREATE TABLE IF NOT EXISTS user_student_relations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    student_id VARCHAR(20) NOT NULL,
    relation VARCHAR(20) NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    UNIQUE KEY unique_relation (user_id, student_id, relation)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- جدول الإشعارات
CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type ENUM('مهم', 'عادي', 'تنبيه') DEFAULT 'عادي',
    is_read BOOLEAN DEFAULT FALSE,
    target_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_notification_user (user_id),
    INDEX idx_notification_read (is_read)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- جدول الإعدادات
CREATE TABLE IF NOT EXISTS settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    setting_key VARCHAR(100) NOT NULL,
    setting_value TEXT NOT NULL,
    description VARCHAR(255),
    group_name VARCHAR(50) DEFAULT 'عام',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_setting (setting_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- ===================================================================
--                    تعبئة البيانات الأولية
-- ===================================================================
-- إدخال الصفوف من الأول إلى التاسع فقط
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
-- إدخال الشُعب (أ، ب، ج) لكل صف
INSERT INTO sections (class_id, name)
SELECT id, 'أ' FROM classes;
INSERT INTO sections (class_id, name)
SELECT id, 'ب' FROM classes;
INSERT INTO sections (class_id, name)
SELECT id, 'ج' FROM classes;
-- إدخال المواد الدراسية حسب المرحلة
INSERT INTO subjects (name, code, description, class_level) VALUES
-- مواد مشتركة في الابتدائي
('القرآن الكريم', 'QURAN', 'حفظ وتلاوة وتجويد وفهم معاني الآيات', 'ابتدائي'),
('اللغة العربية', 'ARAB', 'قراءة، كتابة، نحو، بلاغة، أدب', 'ابتدائي'),
('الرياضيات', 'MATH', 'الأعداد، العمليات، الكسور، الهندسة', 'ابتدائي'),
('العلوم', 'SCI', 'العالم الطبيعي، البيئة، الفيزياء الأساسية', 'ابتدائي'),
('الدراسات الاجتماعية', 'SST', 'التاريخ المحلي، الجغرافيا، المواطنة', 'ابتدائي'),
('التربية الإسلامية', 'ISLAMIC', 'العقيدة، العبادات، الأخلاق، السيرة', 'ابتدائي'),
('اللغة الإنجليزية', 'ENGL', 'مهارات الاستماع والتحدث والقراءة والكتابة', 'متوسط');
-- إدخال العام الدراسي الحالي
INSERT INTO academic_years (name, start_date, end_date, is_current) VALUES
('2024-2025', '2024-09-01', '2025-06-30', TRUE),
('2023-2024', '2023-09-01', '2024-06-30', FALSE);
-- إدخال الرسوم الدراسية لكل صف (بالريال اليمني)
INSERT INTO fee_types (name, description, amount, class_id, is_mandatory, due_date)
SELECT 'الرسوم الدراسية', 'الرسوم الأساسية للعام الدراسي', 120000, id, TRUE, '2024-09-15' FROM classes;
INSERT INTO fee_types (name, description, amount, class_id, is_mandatory, due_date)
SELECT 'الكتب والمستلزمات', 'تكلفة الكتب والكراسات والأدوات', 35000, id, TRUE, '2024-09-15' FROM classes;
INSERT INTO fee_types (name, description, amount, class_id, is_mandatory, due_date)
SELECT 'الأنشطة المدرسية', 'أنشطة ثقافية، رياضية، مسرحية', 20000, id, TRUE, '2024-09-15' FROM classes;
-- إعدادات المدرسة (صنعاء - اليمن)
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
-- ===================================================================
--            ربط المواد بالصفوف عبر جدول المقررات (courses)
-- ===================================================================
-- تحديد المعلم الافتراضي (للتوضيح، يمكن تغييره لاحقًا)
INSERT INTO teachers (id, first_name, last_name, gender, birth_date, phone, email, qualification, specialization, hire_date, salary, status)
VALUES
('T001', 'أحمد', 'المحمدي', 'ذكر', '1985-03-15', '770123456', 'ahmed@school.ye', 'ماجستير تربية', 'اللغة العربية', '2020-08-01', 150000, 'نشط'),
('T002', 'فاطمة', 'السعيدي', 'أنثى', '1990-06-20', '770987654', 'fatima@school.ye', 'بكالوريوس تربية', 'القرآن الكريم', '2019-08-01', 130000, 'نشط'),
('T003', 'محمد', 'الرضوان', 'ذكر', '1988-11-10', '770223344', 'mohammed@school.ye', 'بكالوريوس رياضيات', 'الرياضيات', '2018-08-01', 140000, 'نشط'),
('T004', 'نادية', 'الوهبي', 'أنثى', '1992-01-05', '770334455', 'nadia@school.ye', 'بكالوريوس علوم', 'العلوم', '2021-08-01', 135000, 'نشط'),
('T005', 'سامي', 'الحميدي', 'ذكر', '1987-07-14', '770445566', 'sami@school.ye', 'بكالوريوس دراسات اجتماعية', 'الدراسات الاجتماعية', '2017-08-01', 138000, 'نشط'),
('T006', 'إيمان', 'الشامي', 'أنثى', '1991-09-22', '770556677', 'iman@school.ye', 'ماجستير تربية إسلامية', 'التربية الإسلامية', '2020-08-01', 142000, 'نشط'),
('T007', 'خالد', 'المرتضى', 'ذكر', '1989-12-30', '770667788', 'khaled@school.ye', 'دبلوم لغة إنجليزية', 'اللغة الإنجليزية', '2019-08-01', 137000, 'نشط');
-- الحصول على معرف العام الدراسي الحالي
SET @current_year_id = (SELECT id FROM academic_years WHERE is_current = TRUE LIMIT 1);
-- ربط المواد بالصفوف حسب المرحلة
-- الصفوف 1-2: القرآن، عربي، رياضيات، علوم
INSERT INTO courses (subject_id, class_id, teacher_id, academic_year_id, semester)
SELECT s.id, c.id,
       CASE s.code
         WHEN 'QURAN' THEN 'T002'
         WHEN 'ARAB' THEN 'T001'
         WHEN 'MATH' THEN 'T003'
         WHEN 'SCI' THEN 'T004'
       END,
       @current_year_id, 'أول'
FROM subjects s
CROSS JOIN classes c
WHERE c.order_number IN (1,2)
  AND s.code IN ('QURAN', 'ARAB', 'MATH', 'SCI');
-- الصفوف 3-4: + دراسات اجتماعية
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
       @current_year_id, 'أول'
FROM subjects s
CROSS JOIN classes c
WHERE c.order_number IN (3,4)
  AND s.code IN ('QURAN', 'ARAB', 'MATH', 'SCI', 'SST');
-- الصفوف 5-6: + تربية إسلامية
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
       @current_year_id, 'أول'
FROM subjects s
CROSS JOIN classes c
WHERE c.order_number IN (5,6)
  AND s.code IN ('QURAN', 'ARAB', 'MATH', 'SCI', 'SST', 'ISLAMIC');
-- الصفوف 7-9: + لغة إنجليزية
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
       @current_year_id, 'أول'
FROM subjects s
CROSS JOIN classes c
WHERE c.order_number IN (7,8,9)
  AND s.code IN ('QURAN', 'ARAB', 'MATH', 'SCI', 'SST', 'ISLAMIC', 'ENGL');
-- إعادة نفس المقررات للفصل الثاني
INSERT INTO courses (subject_id, class_id, teacher_id, academic_year_id, semester)
SELECT subject_id, class_id, teacher_id, academic_year_id, 'ثاني'
FROM courses
WHERE semester = 'أول';
-- ===================================================================
--                    العروض، الإجراءات، الدوال، المؤثرات
-- ===================================================================
-- عرض ملخص الطالب
CREATE VIEW student_summary AS
SELECT
    s.id AS student_id,
    CONCAT(s.first_name, ' ', s.last_name) AS full_name,
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
LEFT JOIN attendance a ON s.id = a.student_id AND a.date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
LEFT JOIN fee_types f ON f.class_id = c.id
LEFT JOIN payments p ON s.id = p.student_id
GROUP BY s.id, c.name, sec.name;
-- إجراء حساب الرسوم
DELIMITER //
CREATE PROCEDURE CalculateStudentFees(IN student_id VARCHAR(20))
BEGIN
    SELECT
        s.id AS student_id,
        CONCAT(s.first_name, ' ', s.last_name) AS full_name,
        c.name AS class_name,
        SUM(ft.amount) AS total_fees,
        COALESCE(SUM(p.amount), 0) AS paid_amount,
        (SUM(ft.amount) - COALESCE(SUM(p.amount), 0)) AS pending_amount
    FROM students s
    JOIN sections sec ON s.section_id = sec.id
    JOIN classes c ON sec.class_id = c.id
    LEFT JOIN fee_types ft ON ft.class_id = c.id
    LEFT JOIN payments p ON s.id = p.student_id
    WHERE s.id = student_id
    GROUP BY s.id, c.name;
END //
DELIMITER ;
-- دالة حساب نسبة الحضور
DELIMITER //
CREATE FUNCTION GetAttendanceRate(student_id VARCHAR(20), days INT) RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
    DECLARE total_days INT;
    DECLARE present_days INT;
    DECLARE rate DECIMAL(5,2);
    SELECT COUNT(*) INTO total_days
    FROM attendance
    WHERE student_id = student_id AND date >= DATE_SUB(CURDATE(), INTERVAL days DAY);
    SELECT COUNT(*) INTO present_days
    FROM attendance
    WHERE student_id = student_id AND status = 'حاضر' AND date >= DATE_SUB(CURDATE(), INTERVAL days DAY);
    IF total_days = 0 THEN
        RETURN 100.00;
    ELSE
        SET rate = (present_days * 100.0) / total_days;
        RETURN ROUND(rate, 2);
    END IF;
END //
DELIMITER ;
-- مؤثر: فصل الطالب عند تجاوز الغياب
DELIMITER //
CREATE TRIGGER check_absence_limit
AFTER INSERT ON attendance
FOR EACH ROW
BEGIN
    DECLARE absences INT;
    DECLARE max_absences INT;
    SELECT CAST(setting_value AS UNSIGNED) INTO max_absences
    FROM settings
    WHERE setting_key = 'max_absences';
    SELECT COUNT(*) INTO absences
    FROM attendance
    WHERE student_id = NEW.student_id
      AND status = 'غائب'
      AND date >= DATE_SUB(NEW.date, INTERVAL 30 DAY);
    IF absences >= max_absences THEN
        UPDATE students
        SET status = 'منفصل'
        WHERE id = NEW.student_id;
        INSERT INTO notes (student_id, teacher_id, note_type, title, content)
        VALUES (NEW.student_id, 'ADMIN', 'سلوكي', 'تحذير غياب',
                CONCAT('تم فصل الطالب بسبب تجاوز الحد الأقصى للغياب (', max_absences, ' يوم)'));
    END IF;
END //
DELIMITER ;
-- مؤثر: إشعار بالدفعات المستحقة
DELIMITER //
CREATE TRIGGER check_due_payments
AFTER INSERT ON fee_types
FOR EACH ROW
BEGIN
    DECLARE due_date DATE;
    SET due_date = NEW.due_date;
    IF due_date IS NOT NULL AND due_date <= CURDATE() + INTERVAL 7 DAY THEN
        INSERT INTO notifications (user_id, title, message, type, target_url)
        SELECT
            u.id,
            'تنبيه: دفعة مستحقة',
            CONCAT('تذكير: هناك دفعة مستحقة بقيمة ', NEW.amount, ' ر.ي بتاريخ ', DATE_FORMAT(NEW.due_date, '%Y-%m-%d')),
            'مهم',
            '/payments'
        FROM users u
        JOIN user_student_relations usr ON u.id = usr.user_id
        WHERE usr.is_primary = TRUE;
    END IF;
END //
DELIMITER ;
-- فهارس للأداء
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