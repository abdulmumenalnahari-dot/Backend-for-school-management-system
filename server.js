// server.js
const express = require("express");
const { Pool } = require("pg"); // استخدام PostgreSQL
const cors = require("cors");
const bodyParser = require("body-parser");
const dotenv = require("dotenv");

// تحميل المتغيرات البيئية
dotenv.config();

const app = express();
const PORT = process.env.PORT || 10000;

// --- دالة تهيئة هيكل قاعدة البيانات ---
const initializeDatabaseSchema = async () => {
  try {
    // تحقق من وجود الجدول students
    const checkTable = await executeQuery(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'students'
      );
    `);

    if (!checkTable[0].exists) {
      console.log('🔄 جاري إنشاء الجداول...');

      // هنا نضع محتوى ملف db.sql كسلسلة نصية
      const schemaSQL = `
        CREATE TYPE school_level AS ENUM ('ابتدائي', 'متوسط');
        CREATE TYPE gender_type AS ENUM ('ذكر', 'أنثى');
        CREATE TYPE student_status AS ENUM ('نشط', 'منفصل', 'متخرج', 'منقول');
        CREATE TYPE teacher_status AS ENUM ('نشط', 'موقف', 'مستقيل');
        CREATE TYPE payment_method AS ENUM ('نقدًا', 'تحويل بنكي', 'بطاقة ائتمان', 'شيك');

        CREATE TABLE IF NOT EXISTS classes (
          id SERIAL PRIMARY KEY,
          name VARCHAR(50) NOT NULL,
          level school_level NOT NULL,
          max_students INTEGER DEFAULT 30
        );

        CREATE TABLE IF NOT EXISTS sections (
          id SERIAL PRIMARY KEY,
          name VARCHAR(50) NOT NULL,
          class_id INTEGER REFERENCES classes(id) ON DELETE CASCADE,
          teacher_id VARCHAR(20),
          capacity INTEGER DEFAULT 30,
          UNIQUE(class_id, name)
        );

        CREATE TABLE IF NOT EXISTS students (
          id VARCHAR(20) PRIMARY KEY,
          first_name TEXT NOT NULL,
          middle_name TEXT NOT NULL,
          last_name TEXT NOT NULL,
          family_name TEXT NOT NULL,
          gender gender_type NOT NULL,
          birth_date DATE,
          phone VARCHAR(15) NOT NULL,
          email VARCHAR(100),
          address TEXT,
          enrollment_date DATE DEFAULT CURRENT_DATE,
          status student_status DEFAULT 'نشط',
          section_id INTEGER REFERENCES sections(id) ON DELETE SET NULL,
          photo_url TEXT,
          father_name TEXT,
          mother_name TEXT,
          emergency_contact TEXT
        );

        CREATE TABLE IF NOT EXISTS teachers (
          id VARCHAR(20) PRIMARY KEY,
          first_name TEXT NOT NULL,
          last_name TEXT NOT NULL,
          gender gender_type NOT NULL,
          birth_date DATE,
          phone VARCHAR(15) NOT NULL,
          email VARCHAR(100),
          hire_date DATE DEFAULT CURRENT_DATE,
          specialization TEXT,
          salary DECIMAL(10,2),
          status teacher_status DEFAULT 'نشط',
          photo_url TEXT,
          address TEXT
        );

        CREATE TABLE IF NOT EXISTS academic_years (
          id SERIAL PRIMARY KEY,
          name VARCHAR(20) NOT NULL,
          start_date DATE NOT NULL,
          end_date DATE NOT NULL,
          is_current BOOLEAN DEFAULT false,
          UNIQUE(name)
        );

        CREATE TABLE IF NOT EXISTS fee_types (
          id SERIAL PRIMARY KEY,
          name VARCHAR(100) NOT NULL,
          amount DECIMAL(10,2) NOT NULL,
          due_date DATE,
          is_mandatory BOOLEAN DEFAULT true,
          description TEXT
        );

        CREATE TABLE IF NOT EXISTS payments (
          id SERIAL PRIMARY KEY,
          student_id VARCHAR(20) REFERENCES students(id) ON DELETE CASCADE,
          fee_type_id INTEGER REFERENCES fee_types(id),
          amount DECIMAL(10,2) NOT NULL,
          payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          method payment_method NOT NULL,
          receipt_number VARCHAR(50),
          notes TEXT,
          created_by VARCHAR(20)
        );

        CREATE TABLE IF NOT EXISTS attendance (
          id SERIAL PRIMARY KEY,
          student_id VARCHAR(20) REFERENCES students(id) ON DELETE CASCADE,
          date DATE NOT NULL DEFAULT CURRENT_DATE,
          status VARCHAR(10) NOT NULL CHECK (status IN ('حاضر', 'غائب', 'متأخر')),
          time_in TIME,
          time_out TIME,
          notes TEXT,
          UNIQUE(student_id, date)
        );

        CREATE TABLE IF NOT EXISTS courses (
          id SERIAL PRIMARY KEY,
          name VARCHAR(100) NOT NULL,
          class_level school_level NOT NULL,
          teacher_id VARCHAR(20) REFERENCES teachers(id)
        );

        CREATE TABLE IF NOT EXISTS academic_results (
          id SERIAL PRIMARY KEY,
          student_id VARCHAR(20) REFERENCES students(id) ON DELETE CASCADE,
          course_id INTEGER REFERENCES courses(id),
          academic_year_id INTEGER REFERENCES academic_years(id),
          semester VARCHAR(10) NOT NULL CHECK (semester IN ('الأول', 'الثاني')),
          marks_obtained DECIMAL(5,2),
          total_marks DECIMAL(5,2) DEFAULT 100,
          grade VARCHAR(5),
          comments TEXT,
          exam_date DATE,
          UNIQUE(student_id, course_id, academic_year_id, semester)
        );

        CREATE TABLE IF NOT EXISTS users (
          id VARCHAR(20) PRIMARY KEY,
          username VARCHAR(50) UNIQUE NOT NULL,
          password_hash TEXT NOT NULL,
          role VARCHAR(20) NOT NULL CHECK (role IN ('admin', 'teacher', 'accountant', 'parent')),
          full_name TEXT NOT NULL,
          email VARCHAR(100),
          phone VARCHAR(15),
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          last_login TIMESTAMP,
          is_active BOOLEAN DEFAULT true
        );

        CREATE TABLE IF NOT EXISTS user_student_relations (
          user_id VARCHAR(20) REFERENCES users(id) ON DELETE CASCADE,
          student_id VARCHAR(20) REFERENCES students(id) ON DELETE CASCADE,
          relation_type VARCHAR(20) NOT NULL,
          PRIMARY KEY (user_id, student_id)
        );

        CREATE TABLE IF NOT EXISTS notes (
          id SERIAL PRIMARY KEY,
          student_id VARCHAR(20) REFERENCES students(id) ON DELETE CASCADE,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          created_by VARCHAR(20) NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          category VARCHAR(20) DEFAULT 'عام'
        );

        CREATE INDEX IF NOT EXISTS idx_students_section ON students(section_id);
        CREATE INDEX IF NOT EXISTS idx_payments_student ON payments(student_id);
        CREATE INDEX IF NOT EXISTS idx_attendance_student_date ON attendance(student_id, date);
        CREATE INDEX IF NOT EXISTS idx_academic_results_student ON academic_results(student_id);
        CREATE INDEX IF NOT EXISTS idx_payments_fee_type ON payments(fee_type_id);
        CREATE INDEX IF NOT EXISTS idx_results_year_semester ON academic_results(academic_year_id, semester);
      `;

      // تقسيم التعليمات حسب الفاصلة المنقوطة
      const statements = schemaSQL
        .split(';')
        .map(s => s.trim())
        .filter(s => s.length > 0);

      for (const stmt of statements) {
        await executeQuery(stmt + ';');
      }

      console.log('✅ تم إنشاء الجداول بنجاح');

      // --- إدخال البيانات الأولية فقط إذا كانت الجداول فارغة ---
      const studentCount = await executeQuery('SELECT COUNT(*) FROM students;');
      if (parseInt(studentCount[0].count) === 0) {
        console.log('🔄 جاري إدخال البيانات الأولية...');

        const seedSQL = `
          INSERT INTO classes (name, level, max_students) VALUES 
          ('الصف الأول الإبتدائي', 'ابتدائي', 30),
          ('الصف الثاني الإبتدائي', 'ابتدائي', 30),
          ('الصف الثالث الإبتدائي', 'ابتدائي', 30),
          ('الصف الرابع الإبتدائي', 'ابتدائي', 30),
          ('الصف الخامس الإبتدائي', 'ابتدائي', 30),
          ('الصف السادس الإبتدائي', 'ابتدائي', 30),
          ('الصف السابع', 'متوسط', 35),
          ('الصف الثامن', 'متوسط', 35),
          ('الصف التاسع', 'متوسط', 35);

          INSERT INTO sections (name, class_id, capacity) VALUES
          ('A', 1, 30), ('B', 1, 30),
          ('A', 2, 30), ('B', 2, 30),
          ('A', 3, 30), ('B', 3, 30),
          ('A', 4, 30), ('B', 4, 30),
          ('A', 5, 30), ('B', 5, 30),
          ('A', 6, 30), ('B', 6, 30),
          ('A', 7, 35), ('B', 7, 35),
          ('A', 8, 35), ('B', 8, 35),
          ('A', 9, 35), ('B', 9, 35);

          INSERT INTO teachers (id, first_name, last_name, gender, birth_date, phone, email, hire_date, specialization, salary, status)
          VALUES 
          ('T001', 'أحمد', 'الفلاحي', 'ذكر', '1985-03-15', '770112233', 'ahmed@school.ye', '2015-08-01', 'اللغة العربية', 145000, 'نشط'),
          ('T002', 'فاطمة', 'السقاف', 'أنثى', '1990-11-20', '770223344', 'fatima@school.ye', '2016-08-01', 'العلوم', 148000, 'نشط'),
          ('T003', 'محمد', 'القرشي', 'ذكر', '1988-06-10', '770334455', 'mohammed@school.ye', '2018-08-01', 'الرياضيات', 150000, 'نشط'),
          ('T004', 'آمنة', 'الحمادي', 'أنثى', '1992-02-28', '770445566', 'amna@school.ye', '2017-08-01', 'اللغة الإنجليزية', 142000, 'نشط'),
          ('T005', 'سامي', 'الحميدي', 'ذكر', '1987-07-14', '770445566', 'sami@school.ye', 'بكالوريوس دراسات اجتماعية', 'الدراسات الاجتماعية', '2017-08-01', 138000, 'نشط'),
          ('T006', 'إيمان', 'الشامي', 'أنثى', '1991-09-22', '770556677', 'iman@school.ye', 'ماجستير تربية إسلامية', 'التربية الإسلامية', '2020-08-01', 142000, 'نشط'),
          ('T007', 'خالد', 'المرتضى', 'ذكر', '1989-12-30', '770667788', 'khaled@school.ye', 'دبلوم لغة إنجليزية', 'اللغة الإنجليزية', '2019-08-01', 137000, 'نشط');

          DO $$DECLARE
            current_year_id INT;
          BEGIN
            INSERT INTO academic_years (name, start_date, end_date, is_current)
            VALUES ('2024-2025', '2024-09-01', '2025-06-30', true)
            ON CONFLICT (name) DO NOTHING;

            SELECT id INTO current_year_id FROM academic_years WHERE is_current = TRUE LIMIT 1;

            IF current_year_id IS NOT NULL THEN
              INSERT INTO fee_types (name, amount, due_date, is_mandatory, description)
              VALUES 
                ('الرسوم الدراسية', 500000, '2024-09-15', true, 'الرسوم الشهرية الأساسية'),
                ('الأنشطة', 100000, '2024-09-10', true, 'رسوم الأنشطة المدرسية'),
                ('الكتب', 75000, '2024-09-05', true, 'تكلفة الكتب والملازم'),
                ('الحافلة', 200000, '2024-09-10', false, 'رسوم النقل بالحافلة');
            END IF;
          END$$;
        `;

        const seedStatements = seedSQL
          .split(';')
          .map(s => s.trim())
          .filter(s => s.length > 0);

        for (const stmt of seedStatements) {
          try {
            await executeQuery(stmt + ';');
          } catch (err) {
            console.warn('تحذير في تنفيذ أمر إدخال البيانات:', err.message);
          }
        }

        console.log('✅ تم إدخال البيانات الأولية');
      }
    } else {
      console.log('🟢 الجداول موجودة مسبقًا. لا حاجة لإعادة الإنشاء.');
    }
  } catch (error) {
    console.error('❌ خطأ في تهيئة هيكل قاعدة البيانات:', error.message);
    throw error;
  }
};

// Middleware: CORS - دعم الواجهة الأمامية
app.use(
  cors({
    origin: [
      "http://localhost:3000",
      "https://abdulmumenal-nahari.netlify.app",
    ],
    credentials: true,
  })
);

// Middleware: تحويل البيانات الواردة
app.use(bodyParser.json({ limit: "10mb" }));
app.use(bodyParser.urlencoded({ extended: true, limit: "10mb" }));

// --- إدارة اتصال قاعدة البيانات باستخدام Pool واحد ---
let pool;

const initializeDatabase = async () => {
  try {
    pool = new Pool({
      host: process.env.DB_HOST,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME,
      port: process.env.DB_PORT || 5432,
      ssl: {
        rejectUnauthorized: false, // ضروري لـ Neon.tech
      },
      max: 20, // عدد أقصى من الاتصالات
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 2000,
    });

    // اختبار الاتصال
    await pool.query("SELECT NOW()");
    console.log("✅ اتصال ناجح بقاعدة البيانات");
  } catch (error) {
    console.error("❌ فشل الاتصال بقاعدة البيانات:", error.message);
    // حاول إعادة الاتصال بعد 5 ثوانٍ
    setTimeout(initializeDatabase, 5000);
  }
};

// دالة تنفيذ الاستعلامات (تستخدم التجمع الموحد)
const executeQuery = async (query, params = []) => {
  if (!pool) {
    throw new Error(
      "قاعدة البيانات غير متاحة. جاري المحاولة لإعادة الاتصال..."
    );
  }

  let client;
  try {
    client = await pool.connect();
    const result = await client.query(query, params);
    return result.rows;
  } catch (error) {
    console.error("❌ خطأ في تنفيذ الاستعلام:", error.message);
    throw error;
  } finally {
    if (client) client.release();
  }
};

// نقطة النهاية الأساسية
app.get("/api", (req, res) => {
  res.json({
    message: "API يعمل بشكل صحيح",
    endpoints: {
      dashboard: "/api/dashboard/stats",
      latestStudents: "/api/dashboard/latest-students",
      students: "/api/students",
      studentsForForms: {
        fees: "/api/students/for-fees",
        attendance: "/api/students/for-attendance",
        reports: "/api/students/for-report",
      },
      classes: "/api/classes",
      sections: "/api/sections",
      feeTypes: "/api/fee-types",
      fees: "/api/fees",
      attendance: "/api/attendance",
      reports: "/api/reports/student/:id",
      discounts: "/api/discounts",
      academicYears: "/api/academic-years",
      users: "/api/users",
    },
  });
});

// 1. لوحة التحكم - الإحصائيات
app.get("/api/dashboard/stats", async (req, res) => {
  try {
    const [totalStudents, attendanceToday, absentToday, feesDue] =
      await Promise.all([
        executeQuery(
          `SELECT COUNT(*) AS count FROM students WHERE status = 'نشط'`
        ),
        executeQuery(
          `SELECT COUNT(*) AS count FROM attendance WHERE date = CURRENT_DATE AND status = 'حاضر'`
        ),
        executeQuery(
          `SELECT COUNT(*) AS count FROM attendance WHERE date = CURRENT_DATE AND status = 'غائب'`
        ),
        executeQuery(`
        SELECT 
          COALESCE(SUM(ft.amount), 0) - COALESCE(SUM(p.amount), 0) AS pending
        FROM fee_types ft
        LEFT JOIN payments p ON ft.id = p.fee_type_id
        WHERE ft.is_mandatory = true
      `),
      ]);

    res.json({
      totalStudents: parseInt(totalStudents[0]?.count || 0),
      attendanceToday: parseInt(attendanceToday[0]?.count || 0),
      absentToday: parseInt(absentToday[0]?.count || 0),
      feesDue: parseFloat(feesDue[0]?.pending || 0),
    });
  } catch (error) {
    console.error("خطأ في جلب إحصائيات لوحة التحكم:", error.message);
    res.status(500).json({
      error: "فشل جلب الإحصائيات",
      details: "حدث خطأ أثناء استرجاع البيانات",
    });
  }
});

// 2. أحدث الطلاب
app.get("/api/dashboard/latest-students", async (req, res) => {
  try {
    const students = await executeQuery(`
      SELECT 
        s.id,
        s.first_name || ' ' || s.last_name AS name,
        c.name AS grade,
        sec.name AS section,
        s.parent_phone AS phone
      FROM students s
      JOIN sections sec ON s.section_id = sec.id
      JOIN classes c ON sec.class_id = c.id
      ORDER BY s.created_at DESC
      LIMIT 5
    `);
    res.json(students);
  } catch (error) {
    console.error("خطأ في جلب أحدث الطلاب:", error.message);
    res.status(500).json({
      error: "فشل جلب أحدث الطلاب",
      details: "تأكد من وجود بيانات في الجدول",
    });
  }
});

// 3. الصفوف
app.get("/api/classes", async (req, res) => {
  try {
    const classes = await executeQuery(`
      SELECT id, name, level, order_number
      FROM classes
      ORDER BY order_number
    `);
    res.json(classes);
  } catch (error) {
    console.error("خطأ في جلب الصفوف:", error.message);
    res.status(500).json({
      error: "فشل جلب الصفوف",
      details: "تحقق من اتصال قاعدة البيانات",
    });
  }
});

// 4. الشُعب
app.get("/api/sections", async (req, res) => {
  const { class_id } = req.query;
  try {
    let query = `
      SELECT 
        sec.id, 
        sec.name, 
        c.id AS class_id,
        c.name AS class_name
      FROM sections sec
      JOIN classes c ON sec.class_id = c.id
    `;
    const params = [];
    if (class_id) {
      query += ` WHERE c.id = $1`;
      params.push(class_id);
    }
    query += ` ORDER BY c.order_number, sec.name`;

    const sections = await executeQuery(query, params);
    res.json(sections);
  } catch (error) {
    console.error("خطأ في جلب الشُعب:", error.message);
    res.status(500).json({
      error: "فشل جلب الشُعب",
      details: "تحقق من صحة المعلمات",
    });
  }
});

// 5. أنواع الرسوم
app.get("/api/fee-types", async (req, res) => {
  try {
    const feeTypes = await executeQuery(`
      SELECT id, name, amount, is_mandatory, description
      FROM fee_types
      ORDER BY name
    `);
    res.json(feeTypes);
  } catch (error) {
    console.error("خطأ في جلب أنواع الرسوم:", error.message);
    res.status(500).json({
      error: "فشل جلب أنواع الرسوم",
      details: "تحقق من جدول fee_types",
    });
  }
});

// 6. الطلاب
app.get("/api/students", async (req, res) => {
  try {
    const students = await executeQuery(`
      SELECT 
        s.id,
        s.first_name || ' ' || s.last_name AS name,
        s.id AS idNumber,
        c.name AS grade,
        sec.name AS section,
        s.parent_phone AS phone,
        s.parent_email AS email,
        s.address,
        s.birth_date AS dob,
        s.admission_date AS createdAt
      FROM students s
      JOIN sections sec ON s.section_id = sec.id
      JOIN classes c ON sec.class_id = c.id
      ORDER BY s.created_at DESC
    `);
    res.json(students);
  } catch (error) {
    console.error("خطأ في جلب قائمة الطلاب:", error.message);
    res.status(500).json({
      error: "فشل جلب قائمة الطلاب",
      details: "تحقق من جداول students وsections وclasses",
    });
  }
});

// 7. إضافة طالب جديد
app.post("/api/students", async (req, res) => {
  try {
    const {
      first_name,
      last_name,
      gender,
      birth_date,
      nationality,
      religion,
      address,
      emergency_contact,
      medical_conditions,
      blood_type,
      parent_guardian_name,
      parent_guardian_relation,
      parent_phone,
      parent_email,
      parent_occupation,
      parent_work_address,
      admission_date,
      section_id,
      academic_year_id,
    } = req.body;

    if (!first_name || !last_name || !section_id) {
      return res.status(400).json({
        error: "الحقول المطلوبة غير مكتملة",
        fields: [
          !first_name && "first_name",
          !last_name && "last_name",
          !section_id && "section_id",
        ].filter(Boolean),
      });
    }

    // نتحقق من أن الاسم الكامل (الأول، الثاني، الثالث) ليس موجودًا بالفعل
    const existingStudent = await executeQuery(
      `
  SELECT id FROM students 
  WHERE first_name = $1 
    AND middle_name = $2 
    AND last_name = $3 
    AND section_id = $4
`,
      [first_name, middle_name, last_name, section_id]
    );

    const studentId = `STD${Date.now()}`;
    await executeQuery(
      `INSERT INTO students (
        id, first_name, last_name, gender, birth_date, nationality, religion, 
        address, emergency_contact, medical_conditions, blood_type,
        parent_guardian_name, parent_guardian_relation, parent_phone, 
        parent_email, parent_occupation, parent_work_address, 
        admission_date, section_id, academic_year_id
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20)`,
      [
        studentId,
        first_name,
        last_name,
        gender || null,
        birth_date || null,
        nationality || "يمني",
        religion || "إسلام",
        address || null,
        emergency_contact || null,
        medical_conditions || null,
        blood_type || null,
        parent_guardian_name || null,
        parent_guardian_relation || null,
        parent_phone || null,
        parent_email || null,
        parent_occupation || null,
        parent_work_address || null,
        admission_date || new Date().toISOString().split("T")[0],
        section_id,
        academic_year_id || null,
      ]
    );

    res.status(201).json({
      id: studentId,
      message: "تم إضافة الطالب بنجاح",
      success: true,
    });
  } catch (error) {
    console.error("خطأ في إضافة الطالب:", error.message);
    res.status(500).json({
      error: "فشل إضافة الطالب",
      details: "تحقق من صحة البيانات",
    });
  }
});

// 8. حذف طالب
app.delete("/api/students/:id", async (req, res) => {
  try {
    const studentId = req.params.id;
    await executeQuery("DELETE FROM attendance WHERE student_id = $1", [
      studentId,
    ]);
    await executeQuery("DELETE FROM payments WHERE student_id = $1", [
      studentId,
    ]);
    await executeQuery("DELETE FROM academic_results WHERE student_id = $1", [
      studentId,
    ]);
    await executeQuery("DELETE FROM notes WHERE student_id = $1", [studentId]);
    await executeQuery(
      "DELETE FROM user_student_relations WHERE student_id = $1",
      [studentId]
    );
    await executeQuery("DELETE FROM students WHERE id = $1", [studentId]);

    res.json({ message: "تم حذف الطالب بنجاح", success: true });
  } catch (error) {
    console.error("خطأ في حذف الطالب:", error.message);
    res.status(500).json({
      error: "فشل حذف الطالب",
      details: "قد تكون هناك سجلات مرتبطة",
    });
  }
});

// 9. الطلاب للنماذج
app.get("/api/students/for-fees", async (req, res) => {
  try {
    const students = await executeQuery(`
      SELECT s.id, s.first_name || ' ' || s.last_name AS name
      FROM students s WHERE s.status = 'نشط'
      ORDER BY s.created_at DESC
    `);
    res.json(students);
  } catch (error) {
    res
      .status(500)
      .json({ error: "فشل جلب الطلاب للرسوم", details: error.message });
  }
});

app.get("/api/students/for-attendance", async (req, res) => {
  try {
    const students = await executeQuery(`
      SELECT s.id, s.first_name || ' ' || s.last_name AS name, c.name AS grade, sec.name AS section
      FROM students s
      JOIN sections sec ON s.section_id = sec.id
      JOIN classes c ON sec.class_id = c.id
      WHERE s.status = 'نشط'
      ORDER BY c.order_number, sec.name, s.first_name
    `);
    res.json(students);
  } catch (error) {
    res
      .status(500)
      .json({ error: "فشل جلب الطلاب للحضور", details: error.message });
  }
});

app.get("/api/students/for-report", async (req, res) => {
  try {
    const students = await executeQuery(`
      SELECT s.id, s.first_name || ' ' || s.last_name AS name
      FROM students s WHERE s.status = 'نشط'
      ORDER BY s.created_at DESC
    `);
    res.json(students);
  } catch (error) {
    res
      .status(500)
      .json({ error: "فشل جلب الطلاب للتقارير", details: error.message });
  }
});

// 10. تسجيل الدفعات
app.get("/api/fees", async (req, res) => {
  try {
    const fees = await executeQuery(`
      SELECT p.id, s.first_name || ' ' || s.last_name AS studentName, ft.name AS type,
             p.amount, p.payment_date AS date, p.payment_method AS method
      FROM payments p
      JOIN students s ON p.student_id = s.id
      JOIN fee_types ft ON p.fee_type_id = ft.id
      ORDER BY p.payment_date DESC
    `);
    res.json(fees);
  } catch (error) {
    res.status(500).json({ error: "فشل جلب الدفعات", details: error.message });
  }
});

app.post("/api/fees", async (req, res) => {
  try {
    const {
      student_id,
      fee_type_id,
      amount,
      payment_date,
      payment_method,
      receipt_number,
      notes,
    } = req.body;
    if (!student_id || !fee_type_id || !amount) {
      return res.status(400).json({ error: "الحقول المطلوبة غير مكتملة" });
    }

    await executeQuery(
      `INSERT INTO payments (student_id, fee_type_id, amount, payment_date, payment_method, receipt_number, notes)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [
        student_id,
        fee_type_id,
        amount,
        payment_date || new Date().toISOString().split("T")[0],
        payment_method || "نقدًا",
        receipt_number || null,
        notes || null,
      ]
    );

    res.status(201).json({ message: "تم تسجيل الدفعة بنجاح", success: true });
  } catch (error) {
    res.status(500).json({ error: "فشل تسجيل الدفعة", details: error.message });
  }
});

// 11. الحضور
app.get("/api/attendance", async (req, res) => {
  const { date } = req.query;
  try {
    const attendance = await executeQuery(
      `
      SELECT a.id, a.student_id, s.first_name || ' ' || s.last_name AS name, c.name AS grade, sec.name AS section,
             a.status, a.time_in, a.time_out, a.notes
      FROM attendance a
      JOIN students s ON a.student_id = s.id
      JOIN sections sec ON s.section_id = sec.id
      JOIN classes c ON sec.class_id = c.id
      WHERE a.date = $1
      ORDER BY c.order_number, sec.name, s.first_name
    `,
      [date || new Date().toISOString().split("T")[0]]
    );
    res.json(attendance);
  } catch (error) {
    res.status(500).json({ error: "فشل جلب الحضور", details: error.message });
  }
});

app.post("/api/attendance", async (req, res) => {
  try {
    const { student_id, date, status, time_in, time_out, notes } = req.body;
    if (!student_id || !date || !status) {
      return res.status(400).json({ error: "الحقول المطلوبة غير مكتملة" });
    }

    const existing = await executeQuery(
      `SELECT id FROM attendance WHERE student_id = $1 AND date = $2`,
      [student_id, date]
    );

    if (existing.length > 0) {
      await executeQuery(
        `UPDATE attendance SET status = $1, time_in = $2, time_out = $3, notes = $4 WHERE student_id = $5 AND date = $6`,
        [status, time_in, time_out, notes, student_id, date]
      );
    } else {
      await executeQuery(
        `INSERT INTO attendance (student_id, date, status, time_in, time_out, notes) VALUES ($1, $2, $3, $4, $5, $6)`,
        [student_id, date, status, time_in, time_out, notes]
      );
    }

    res
      .status(201)
      .json({ message: "تم تحديث بيانات الحضور بنجاح", success: true });
  } catch (error) {
    res.status(500).json({ error: "فشل تسجيل الحضور", details: error.message });
  }
});

// 12. التقارير
app.get("/api/reports/student/:id", async (req, res) => {
  try {
    const studentId = req.params.id;
    const studentResult = await executeQuery(
      `
      SELECT s.id, s.first_name || ' ' || s.last_name AS name, c.name AS grade, sec.name AS section
      FROM students s
      JOIN sections sec ON s.section_id = sec.id
      JOIN classes c ON sec.class_id = c.id
      WHERE s.id = $1
    `,
      [studentId]
    );

    if (studentResult.length === 0) {
      return res.status(404).json({ error: "الطالب غير موجود" });
    }

    const student = studentResult[0];
    const attendance = await executeQuery(
      `SELECT date, status FROM attendance WHERE student_id = $1 AND EXTRACT(MONTH FROM date) = EXTRACT(MONTH FROM CURRENT_DATE)`,
      [studentId]
    );

    const feesBreakdown = await executeQuery(
      `
      SELECT ft.name, ft.amount AS required, COALESCE(SUM(p.amount), 0) AS paid
      FROM fee_types ft
      LEFT JOIN payments p ON ft.id = p.fee_type_id AND p.student_id = $1
      GROUP BY ft.id, ft.name
    `,
      [studentId]
    );

    res.json({
      student,
      attendance,
      feesBreakdown,
      financialStatus: "متأخر",
    });
  } catch (error) {
    res.status(500).json({ error: "فشل جلب التقرير", details: error.message });
  }
});

// 13. الأعوام الدراسية
app.get("/api/academic-years", async (req, res) => {
  try {
    const years = await executeQuery(
      "SELECT id, name, start_date, end_date, is_current FROM academic_years ORDER BY start_date DESC"
    );
    res.json(years);
  } catch (error) {
    res.status(500).json({ error: "فشل جلب الأعوام", details: error.message });
  }
});

// 14. إنشاء مستخدم
app.post("/api/users", async (req, res) => {
  try {
    const { username, email, password, role } = req.body;
    if (!username || !email || !password || !role) {
      return res.status(400).json({ error: "جميع الحقول مطلوبة" });
    }

    const existingUser = await executeQuery(
      `SELECT id FROM users WHERE username = $1 OR email = $2`,
      [username, email]
    );
    if (existingUser.length > 0) {
      return res.status(400).json({ error: "المستخدم موجود مسبقًا" });
    }

    await executeQuery(
      `INSERT INTO users (username, email, password, role, is_active) VALUES ($1, $2, $3, $4, true)`,
      [username, email, password, role]
    );

    res.status(201).json({ message: "تم إنشاء المستخدم بنجاح", success: true });
  } catch (error) {
    res
      .status(500)
      .json({ error: "فشل إنشاء المستخدم", details: error.message });
  }
});

// 15. التعامل مع المسارات غير المعرفة
app.use((req, res) => {
  res.status(404).json({
    error: "المسار غير موجود",
    path: req.path,
  });
});

// 16. معالجة الأخطاء العامة (لا توقف السيرفر)
app.use((err, req, res, next) => {
  console.error("❌ خطأ غير متوقع:", err.stack);
  res.status(500).json({
    error: "حدث خطأ داخلي في الخادم",
    details: "يرجى المحاولة لاحقًا",
  });
});

// 17. بدء السيرفر
app.listen(PORT, "0.0.0.0", async () => {
  console.log(`🚀 السيرفر يعمل على المنفذ ${PORT}`);
  await initializeDatabase(); // بدء اتصال قاعدة البيانات
});

// --- إدارة إعادة الاتصال التلقائي ---
// --- إدارة إعادة الاتصال التلقائي ---
process.on("unhandledRejection", (reason, promise) => {
  console.error("Unhandled Rejection at:", promise, "reason:", reason);
});

process.on("uncaughtException", (err) => {
  console.error("Uncaught Exception:", err);
  // لا تتوقف — استمر في العمل
  process.exitCode = 1;
});
