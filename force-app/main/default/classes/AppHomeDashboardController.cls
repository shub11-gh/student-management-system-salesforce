// File: AppHomeDashboardController.cls

public with sharing class AppHomeDashboardController {

    @AuraEnabled(cacheable=true)
    public static DashboardWrapper getDashboardData() {

        DashboardWrapper dw = new DashboardWrapper();

        // ── Institution Stats ─────────────────────────────────────────────
        dw.totalStudents  = [SELECT COUNT() FROM Student__c];
        dw.totalTeachers  = [SELECT COUNT() FROM Teacher__c];
        dw.totalCourses   = [SELECT COUNT() FROM Course__c];
        dw.totalSections  = [SELECT COUNT()
                             FROM Course_Section_Enrollment__c];

        // ── Recent Enrollments (last 10) ──────────────────────────────────
        List<Section_Student_Junction__c> recentEnrollments = [
            SELECT Id,
                   Student__r.Name,
                   Student__r.Student_ID__c,
                   Course_Section_Enrollment__r.Section_Code__c,
                   Course_Section_Enrollment__r.Courses_Offering__r.Courses__r.Name,
                   Course_Section_Enrollment__r.Courses_Offering__r.Semester__c,
                   CreatedDate
            FROM Section_Student_Junction__c
            ORDER BY CreatedDate DESC
            LIMIT 10
        ];

        dw.recentEnrollments = new List<EnrollmentWrapper>();
        for (Section_Student_Junction__c j : recentEnrollments) {
            EnrollmentWrapper ew    = new EnrollmentWrapper();
            ew.junctionId           = j.Id;
            ew.studentName          = j.Student__r.Name;
            ew.studentCode          = j.Student__r.Student_ID__c;
            ew.courseName           = j.Course_Section_Enrollment__r
                                        .Courses_Offering__r.Courses__r.Name;
            ew.sectionCode          = j.Course_Section_Enrollment__r
                                        .Section_Code__c;
            ew.semester             = j.Course_Section_Enrollment__r
                                        .Courses_Offering__r.Semester__c;
            ew.enrolledDate         = j.CreatedDate.format();
            dw.recentEnrollments.add(ew);
        }

        // ── Low Attendance Alerts ─────────────────────────────────────────
        List<Section_Student_Junction__c> lowAttendance = [
            SELECT Id,
                   Student__r.Name,
                   Student__r.Student_ID__c,
                   Attendance_Percentage__c,
                   Course_Section_Enrollment__r.Section_Code__c,
                   Course_Section_Enrollment__r.Courses_Offering__r.Courses__r.Name
            FROM Section_Student_Junction__c
            WHERE Attendance_Percentage__c != null
              AND Attendance_Percentage__c < 75
            ORDER BY Attendance_Percentage__c ASC
            LIMIT 10
        ];

        dw.lowAttendanceAlerts = new List<AttendanceAlertWrapper>();
        for (Section_Student_Junction__c j : lowAttendance) {
            AttendanceAlertWrapper aw   = new AttendanceAlertWrapper();
            aw.junctionId               = j.Id;
            aw.studentName              = j.Student__r.Name;
            aw.studentCode              = j.Student__r.Student_ID__c;
            aw.courseName               = j.Course_Section_Enrollment__r
                                            .Courses_Offering__r.Courses__r.Name;
            aw.sectionCode              = j.Course_Section_Enrollment__r
                                            .Section_Code__c;
            aw.attendancePct            = j.Attendance_Percentage__c
                                            .setScale(1);
            aw.attendanceStyle          = 'width:' + aw.attendancePct
                                            + '%;background:#B91C1C';
            dw.lowAttendanceAlerts.add(aw);
        }

        // ── Top Performing Students ───────────────────────────────────────
        List<Student__c> topStudents = [
            SELECT Id,
                   Name,
                   Student_ID__c,
                   CGPA__c,
                   Program__c
            FROM Student__c
            WHERE CGPA__c != null
              AND CGPA__c > 0
            ORDER BY CGPA__c DESC
            LIMIT 10
        ];

        dw.topStudents = new List<TopStudentWrapper>();
        Integer rank   = 1;
        for (Student__c s : topStudents) {
            TopStudentWrapper tw    = new TopStudentWrapper();
            tw.studentId            = s.Id;
            tw.studentName          = s.Name;
            tw.studentCode          = s.Student_ID__c;
            tw.cgpa                 = s.CGPA__c.setScale(2);
            tw.program              = s.Program__c != null
                                        ? s.Program__c : '—';
            tw.rank                 = rank++;
            tw.cgpaStyle            = 'width:' + (tw.cgpa * 10)
                                        + '%;background:#D4500A';
            dw.topStudents.add(tw);
        }

        dw.lowAttendanceCount = dw.lowAttendanceAlerts.size();

        return dw;
    }

    // ── Wrappers ──────────────────────────────────────────────────────────
    public class DashboardWrapper {
        @AuraEnabled public Integer totalStudents;
        @AuraEnabled public Integer totalTeachers;
        @AuraEnabled public Integer totalCourses;
        @AuraEnabled public Integer totalSections;
        @AuraEnabled public Integer lowAttendanceCount;
        @AuraEnabled public List<EnrollmentWrapper>     recentEnrollments;
        @AuraEnabled public List<AttendanceAlertWrapper> lowAttendanceAlerts;
        @AuraEnabled public List<TopStudentWrapper>     topStudents;
    }

    public class EnrollmentWrapper {
        @AuraEnabled public Id     junctionId;
        @AuraEnabled public String studentName;
        @AuraEnabled public String studentCode;
        @AuraEnabled public String courseName;
        @AuraEnabled public String sectionCode;
        @AuraEnabled public String semester;
        @AuraEnabled public String enrolledDate;
    }

    public class AttendanceAlertWrapper {
        @AuraEnabled public Id      junctionId;
        @AuraEnabled public String  studentName;
        @AuraEnabled public String  studentCode;
        @AuraEnabled public String  courseName;
        @AuraEnabled public String  sectionCode;
        @AuraEnabled public Decimal attendancePct;
        @AuraEnabled public String  attendanceStyle;
    }

    public class TopStudentWrapper {
        @AuraEnabled public Id      studentId;
        @AuraEnabled public String  studentName;
        @AuraEnabled public String  studentCode;
        @AuraEnabled public Decimal cgpa;
        @AuraEnabled public String  program;
        @AuraEnabled public Integer rank;
        @AuraEnabled public String  cgpaStyle;
    }
}