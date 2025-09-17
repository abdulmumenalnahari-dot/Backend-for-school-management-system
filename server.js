// server.js
const express = require("express");
const { Pool } = require("pg"); // استخدام PostgreSQL بدل MySQL
const cors = require("cors");
const bodyParser = require("body-parser");
const dotenv = require("dotenv");

// تحميل المتغيرات البيئية
dotenv.config();

const app = express();
const PORT = process.env.PORT || 10000;

// Middleware: CORS
app.use(
  cors({
    origin: [
      "http://localhost:3000",
      "https://abdulmumenal-nahari.netlify.app"
    ],
    credentials: true,
  })
);

// Middleware: تحويل البيانات الواردة
app.use(bodyParser.json({ limit: "10mb" }));
app.use(bodyParser.urlencoded({ extended: true, limit: "10mb" }));

// دالة لإنشاء اتصال قاعدة البيانات (مع SSL لـ Neon)
const createConnection = async () => {
  try {
    const pool = new Pool({
      host: process.env.DB_HOST,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME,
      port: process.env.DB_PORT || 5432,
      ssl: {
        rejectUnauthorized: false, // ضروري للعمل مع Neon.tech
      },
    });
    console.log("✅ اتصال ناجح بقاعدة البيانات");
    return pool;
  } catch (error) {
    console.error("❌ فشل الاتصال بقاعدة البيانات:", error.message);
    throw error;
  }
};

// دالة تنفيذ الاستعلامات مع إدارة الاتصال
const executeQuery = async (query, params = []) => {
  let client;
  try {
    const pool = await createConnection();
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
      users: "/api/users"
    }
  });
});

// 1. لوحة التحكم - الإحصائيات
app.get("/api/dashboard/stats", async (req, res) => {
  try {
    const [totalStudents, attendanceToday, absentToday, feesDue] = await Promise.all([
      executeQuery(`SELECT COUNT(*) AS count FROM students WHERE status = 'نشط'`),
      executeQuery(`SELECT COUNT(*) AS count FROM attendance WHERE date = CURRENT_DATE AND status = 'حاضر'`),
      executeQuery(`SELECT COUNT(*) AS count FROM attendance WHERE date = CURRENT_DATE AND status = 'غائب'`),
      executeQuery(`
        SELECT 
          COALESCE(SUM(ft.amount), 0) - COALESCE(SUM(p.amount), 0) AS pending
        FROM fee_types ft
        LEFT JOIN payments p ON ft.id = p.fee_type_id
        WHERE ft.is_mandatory = true
      `)
    ]);

    res.json({
      totalStudents: parseInt(totalStudents[0]?.count || 0),
      attendanceToday: parseInt(attendanceToday[0]?.count || 0),
      absentToday: parseInt(absentToday[0]?.count || 0),
      feesDue: parseFloat(feesDue[0]?.pending || 0)
    });
  } catch (error) {
    console.error("خطأ في جلب إحصائيات لوحة التحكم:", error);
    res.status(500).json({
      error: "فشل جلب الإحصائيات",
      details: error.message,
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
    console.error("خطأ في جلب أحدث الطلاب:", error);
    res.status(500).json({
      error: "فشل جلب أحدث الطلاب",
      details: error.message,
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
    console.error("خطأ في جلب الصفوف:", error);
    res.status(500).json({
      error: "فشل جلب الصفوف",
      details: error.message,
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
    console.error("خطأ في جلب الشُعب:", error);
    res.status(500).json({
      error: "فشل جلب الشُعب",
      details: error.message,
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
    console.error("خطأ في جلب أنواع الرسوم:", error);
    res.status(500).json({
      error: "فشل جلب أنواع الرسوم",
      details: error.message,
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
    console.error("خطأ في جلب قائمة الطلاب:", error);
    res.status(500).json({
      error: "فشل جلب قائمة الطلاب",
      details: error.message,
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

    const existingStudent = await executeQuery(
      `SELECT id FROM students WHERE first_name = $1 AND last_name = $2 AND section_id = $3`,
      [first_name, last_name, section_id]
    );
    if (existingStudent.length > 0) {
      return res.status(400).json({
        error: "الطالب موجود مسبقًا",
        details: "يوجد طالب بنفس الاسم والشعبة",
      });
    }

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
        studentId, first_name, last_name, gender || null, birth_date || null,
        nationality || "يمني", religion || "إسلام", address || null,
        emergency_contact || null, medical_conditions || null, blood_type || null,
        parent_guardian_name || null, parent_guardian_relation || null,
        parent_phone || null, parent_email || null, parent_occupation || null,
        parent_work_address || null, admission_date || new Date().toISOString().split("T")[0],
        section_id, academic_year_id || null
      ]
    );

    res.status(201).json({
      id: studentId,
      message: "تم إضافة الطالب بنجاح",
      success: true,
    });
  } catch (error) {
    console.error("خطأ في إضافة الطالب:", error);
    res.status(500).json({
      error: "فشل إضافة الطالب",
      details: error.message,
    });
  }
});

// 8. حذف طالب
app.delete("/api/students/:id", async (req, res) => {
  try {
    const studentId = req.params.id;
    await executeQuery("DELETE FROM attendance WHERE student_id = $1", [studentId]);
    await executeQuery("DELETE FROM payments WHERE student_id = $1", [studentId]);
    await executeQuery("DELETE FROM academic_results WHERE student_id = $1", [studentId]);
    await executeQuery("DELETE FROM notes WHERE student_id = $1", [studentId]);
    await executeQuery("DELETE FROM user_student_relations WHERE student_id = $1", [studentId]);
    await executeQuery("DELETE FROM students WHERE id = $1", [studentId]);

    res.json({ message: "تم حذف الطالب بنجاح", success: true });
  } catch (error) {
    console.error("خطأ في حذف الطالب:", error);
    res.status(500).json({
      error: "فشل حذف الطالب",
      details: error.message,
    });
  }
});

// 9. الطلاب للنماذج (الرسوم، الحضور، التقارير)
app.get("/api/students/for-fees", async (req, res) => {
  try {
    const students = await executeQuery(`
      SELECT s.id, s.first_name || ' ' || s.last_name AS name
      FROM students s WHERE s.status = 'نشط'
      ORDER BY s.created_at DESC
    `);
    res.json(students);
  } catch (error) {
    res.status(500).json({ error: "فشل جلب الطلاب للرسوم", details: error.message });
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
    res.status(500).json({ error: "فشل جلب الطلاب للحضور", details: error.message });
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
    res.status(500).json({ error: "فشل جلب الطلاب للتقارير", details: error.message });
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
    const { student_id, fee_type_id, amount, payment_date, payment_method, receipt_number, notes } = req.body;
    if (!student_id || !fee_type_id || !amount) {
      return res.status(400).json({ error: "الحقول المطلوبة غير مكتملة" });
    }

    await executeQuery(
      `INSERT INTO payments (student_id, fee_type_id, amount, payment_date, payment_method, receipt_number, notes)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [
        student_id, fee_type_id, amount,
        payment_date || new Date().toISOString().split("T")[0],
        payment_method || "نقدًا", receipt_number || null, notes || null
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
    const attendance = await executeQuery(`
      SELECT a.id, a.student_id, s.first_name || ' ' || s.last_name AS name, c.name AS grade, sec.name AS section,
             a.status, a.time_in, a.time_out, a.notes
      FROM attendance a
      JOIN students s ON a.student_id = s.id
      JOIN sections sec ON s.section_id = sec.id
      JOIN classes c ON sec.class_id = c.id
      WHERE a.date = $1
      ORDER BY c.order_number, sec.name, s.first_name
    `, [date || new Date().toISOString().split("T")[0]]);
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
      `SELECT id FROM attendance WHERE student_id = $1 AND date = $2`, [student_id, date]
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

    res.status(201).json({ message: "تم تحديث بيانات الحضور بنجاح", success: true });
  } catch (error) {
    res.status(500).json({ error: "فشل تسجيل الحضور", details: error.message });
  }
});

// 12. التقارير
app.get("/api/reports/student/:id", async (req, res) => {
  try {
    const studentId = req.params.id;
    const studentResult = await executeQuery(`
      SELECT s.id, s.first_name || ' ' || s.last_name AS name, c.name AS grade, sec.name AS section
      FROM students s
      JOIN sections sec ON s.section_id = sec.id
      JOIN classes c ON sec.class_id = c.id
      WHERE s.id = $1
    `, [studentId]);

    if (studentResult.length === 0) {
      return res.status(404).json({ error: "الطالب غير موجود" });
    }

    const student = studentResult[0];
    const attendance = await executeQuery(
      `SELECT date, status FROM attendance WHERE student_id = $1 AND EXTRACT(MONTH FROM date) = EXTRACT(MONTH FROM CURRENT_DATE)`,
      [studentId]
    );

    const feesBreakdown = await executeQuery(`
      SELECT ft.name, ft.amount AS required, COALESCE(SUM(p.amount), 0) AS paid
      FROM fee_types ft
      LEFT JOIN payments p ON ft.id = p.fee_type_id AND p.student_id = $1
      GROUP BY ft.id, ft.name
    `, [studentId]);

    res.json({
      student,
      attendance,
      feesBreakdown,
      financialStatus: "متأخر"
    });
  } catch (error) {
    res.status(500).json({ error: "فشل جلب التقرير", details: error.message });
  }
});

// 13. الأعوام الدراسية
app.get("/api/academic-years", async (req, res) => {
  try {
    const years = await executeQuery("SELECT id, name, start_date, end_date, is_current FROM academic_years ORDER BY start_date DESC");
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
    res.status(500).json({ error: "فشل إنشاء المستخدم", details: error.message });
  }
});

// 15. التعامل مع المسارات غير المعرفة
app.use((req, res) => {
  res.status(404).json({
    error: "المسار غير موجود",
    path: req.path,
  });
});

// 16. معالجة الأخطاء العامة
app.use((err, req, res, next) => {
  console.error("❌ خطأ غير متوقع:", err);
  res.status(500).json({
    error: "حدث خطأ داخلي في الخادم",
    details: err.message,
  });
});

// 17. بدء السيرفر
app.listen(PORT, "0.0.0.0", () => {
  console.log(`🚀 السيرفر يعمل على المنفذ ${PORT}`);
});