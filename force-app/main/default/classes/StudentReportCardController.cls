// File: StudentReportCardController.cls

public with sharing class StudentReportCardController {

    public Student__c student           { get; set; }
    public List<CourseGrade> grades     { get; set; }
    public List<AttendanceSummary> attendance { get; set; }
    public Decimal overallCGPA          { get; set; }
    public Decimal overallAttendance    { get; set; }
    public String generatedDate         { get; set; }

    // Constructor — called when the page loads
    // Gets the student Id from the URL parameter
    public StudentReportCardController() {
        Id studentId = ApexPages.currentPage()
                        .getParameters().get('id');
        generatedDate = Date.today().format();

        if (studentId == null) {
            student = new Student__c();
            grades  = new List<CourseGrade>();
            attendance = new List<AttendanceSummary>();
            return;
        }

        // Query student details
        student = [
            SELECT Id, Name, Student_ID__c,
                   Student_Email__c, Phone_No__c,
                   Program__c, CGPA__c,
                   Date_of_Birth__c, Enrollment_Date__c
            FROM Student__c
            WHERE Id = :studentId
            LIMIT 1
        ];

        overallCGPA = student.CGPA__c != null
                        ? student.CGPA__c : 0;

        // Query all assessment scores
        List<Assessment_Score__c> scores = [
            SELECT Id,
                   Marks_Obtained__c,
                   Percentage__c,
                   Assessment__r.Name,
                   Assessment__r.Assessment_Type__c,
                   Assessment__r.Maximum_Marks__c,
                   Assessment__r.Weightage__c,
                   Assessment__r.Course_Enrollment__r.Section_Code__c,
                   Assessment__r.Course_Enrollment__r.Courses_Offering__r.Courses__r.Name,
                   Assessment__r.Course_Enrollment__r.Courses_Offering__r.Semester__c
            FROM Assessment_Score__c
            WHERE Section_Student_Junction__r.Student__c = :studentId
              AND Marks_Obtained__c != null
            ORDER BY Assessment__r.Course_Enrollment__r.Courses_Offering__r.Courses__r.Name ASC
        ];

        // Group scores by course
        Map<String, CourseGrade> gradeMap = new Map<String, CourseGrade>();
        for (Assessment_Score__c score : scores) {
            String courseName = score.Assessment__r.Course_Enrollment__r
                                    .Courses_Offering__r.Courses__r.Name;
            if (!gradeMap.containsKey(courseName)) {
                CourseGrade cg      = new CourseGrade();
                cg.courseName       = courseName;
                cg.sectionCode      = score.Assessment__r
                                        .Course_Enrollment__r.Section_Code__c;
                cg.semester         = score.Assessment__r.Course_Enrollment__r
                                        .Courses_Offering__r.Semester__c;
                cg.assessments      = new List<AssessmentRow>();
                cg.totalWeighted    = 0;
                cg.totalWeight      = 0;
                gradeMap.put(courseName, cg);
            }

            CourseGrade cg          = gradeMap.get(courseName);
            AssessmentRow ar        = new AssessmentRow();
            ar.assessmentName       = score.Assessment__r.Name;
            ar.assessmentType       = score.Assessment__r
                                        .Assessment_Type__c != null
                                        ? score.Assessment__r.Assessment_Type__c
                                        : '—';
            ar.marksObtained        = score.Marks_Obtained__c;
            ar.maximumMarks         = score.Assessment__r.Maximum_Marks__c;
            ar.percentage           = score.Percentage__c != null
                                        ? score.Percentage__c.setScale(1) : 0;
            ar.weightage            = score.Assessment__r.Weightage__c != null
                                        ? score.Assessment__r.Weightage__c : 0;
            ar.grade                = getGrade(ar.percentage);

            if (ar.maximumMarks != null && ar.maximumMarks > 0) {
                cg.totalWeighted   += (ar.marksObtained / ar.maximumMarks)
                                        * ar.weightage;
                cg.totalWeight     += ar.weightage;
            }
            cg.assessments.add(ar);
        }

        grades = new List<CourseGrade>();
        for (CourseGrade cg : gradeMap.values()) {
            cg.courseAverage = cg.totalWeight > 0
                ? ((cg.totalWeighted / cg.totalWeight) * 100).setScale(1) : 0;
            cg.courseGrade   = getGrade(cg.courseAverage);
            grades.add(cg);
        }

        // Query attendance summary per course
        List<Section_Student_Junction__c> junctions = [
            SELECT Id,
                   Attendance_Percentage__c,
                   Course_Section_Enrollment__r.Section_Code__c,
                   Course_Section_Enrollment__r.Courses_Offering__r.Courses__r.Name,
                   Course_Section_Enrollment__r.Courses_Offering__r.Semester__c
            FROM Section_Student_Junction__c
            WHERE Student__c = :studentId
        ];

        attendance              = new List<AttendanceSummary>();
        Decimal totalPct        = 0;
        Integer junctionCount   = 0;

        for (Section_Student_Junction__c j : junctions) {
            AttendanceSummary attSummary   = new AttendanceSummary();
            attSummary.courseName           = j.Course_Section_Enrollment__r.Courses_Offering__r.Courses__r.Name;
            attSummary.sectionCode          = j.Course_Section_Enrollment__r.Section_Code__c;
            attSummary.semester             = j.Course_Section_Enrollment__r.Courses_Offering__r.Semester__c;
            attSummary.attendancePct        = j.Attendance_Percentage__c != null? j.Attendance_Percentage__c.setScale(1): 0;
            attSummary.status               = attSummary.attendancePct >= 75? 'Satisfactory' : 'Low';
            attendance.add(attSummary);
            totalPct               += attSummary.attendancePct;
            junctionCount++;
        }

        overallAttendance = junctionCount > 0
            ? (totalPct / junctionCount).setScale(1) : 0;
    }

    private static String getGrade(Decimal pct) {
        if (pct >= 90) return 'O';
        if (pct >= 80) return 'A+';
        if (pct >= 70) return 'A';
        if (pct >= 60) return 'B+';
        if (pct >= 50) return 'B';
        if (pct >= 40) return 'C';
        return 'F';
    }

    // ── Inner Classes ─────────────────────────────────────────────────────
    public class CourseGrade {
        public String courseName        { get; set; }
        public String sectionCode       { get; set; }
        public String semester          { get; set; }
        public Decimal courseAverage    { get; set; }
        public String courseGrade       { get; set; }
        public Decimal totalWeighted    { get; set; }
        public Decimal totalWeight      { get; set; }
        public List<AssessmentRow> assessments { get; set; }
    }

    public class AssessmentRow {
        public String  assessmentName  { get; set; }
        public String  assessmentType  { get; set; }
        public Decimal marksObtained   { get; set; }
        public Decimal maximumMarks    { get; set; }
        public Decimal percentage      { get; set; }
        public Decimal weightage       { get; set; }
        public String  grade           { get; set; }
    }

    public class AttendanceSummary {
        public String  courseName      { get; set; }
        public String  sectionCode     { get; set; }
        public String  semester        { get; set; }
        public Decimal attendancePct   { get; set; }
        public String  status          { get; set; }
    }
}