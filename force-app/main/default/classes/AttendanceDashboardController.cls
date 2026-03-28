// File: AttendanceDashboardController.cls

public with sharing class AttendanceDashboardController {

    @AuraEnabled(cacheable=true)
    public static List<CourseAttendanceWrapper> getAttendanceData(Id studentId) {

        // Query all attendance records for this student
        // Traversing: Junction → Attendance → Classroom Session → CSE → Offering → Course
        List<Attendance__c> records = [
            SELECT Id,
                   Status__c,
                   Classroom_Session__r.Session_Date__c,
                   Classroom_Session__r.Topics_Covered__c,
                   Classroom_Session__r.Session_Status__c,
                   Classroom_Session__r.Courses_Enrollment__r.Section_Code__c,
                   Classroom_Session__r.Courses_Enrollment__r.Courses_Offering__r.Semester__c,
                   Classroom_Session__r.Courses_Enrollment__r.Courses_Offering__r.Courses__r.Name
            FROM Attendance__c
            WHERE Section_Student_Junction__r.Student__c = :studentId
              AND Classroom_Session__r.Session_Status__c = 'Completed'
            ORDER BY Classroom_Session__r.Courses_Enrollment__r.Courses_Offering__r.Courses__r.Name,
                     Classroom_Session__r.Session_Date__c ASC
        ];

        // Group by course name
        Map<String, CourseAttendanceWrapper> courseMap = new Map<String, CourseAttendanceWrapper>();

        for (Attendance__c a : records) {
            String courseName = a.Classroom_Session__r.Courses_Enrollment__r
                                 .Courses_Offering__r.Courses__r.Name;
            String section    = a.Classroom_Session__r.Courses_Enrollment__r.Section_Code__c;
            String semester   = a.Classroom_Session__r.Courses_Enrollment__r
                                 .Courses_Offering__r.Semester__c;

            if (!courseMap.containsKey(courseName)) {
                CourseAttendanceWrapper cw = new CourseAttendanceWrapper();
                cw.courseName  = courseName;
                cw.sectionCode = section;
                cw.semester    = semester;
                cw.sessions    = new List<SessionWrapper>();
                cw.totalSessions  = 0;
                cw.presentCount   = 0;
                cw.absentCount    = 0;
                cw.lateCount      = 0;
                cw.excusedCount   = 0;
                courseMap.put(courseName, cw);
            }

            CourseAttendanceWrapper cw = courseMap.get(courseName);

            // Count by status
            cw.totalSessions++;
            if (a.Status__c == 'Present')       cw.presentCount++;
            else if (a.Status__c == 'Absent')   cw.absentCount++;
            else if (a.Status__c == 'Late')     cw.lateCount++;
            else if (a.Status__c == 'Excused')  cw.excusedCount++;

            // Build session row
            SessionWrapper sw  = new SessionWrapper();
            sw.sessionDate     = a.Classroom_Session__r.Session_Date__c != null
                                   ? a.Classroom_Session__r.Session_Date__c.format()
                                   : '—';
            sw.topicsCovered   = a.Classroom_Session__r.Topics_Covered__c != null
                                   ? a.Classroom_Session__r.Topics_Covered__c : '—';
            sw.status          = a.Status__c;
            sw.statusClass     = getStatusClass(a.Status__c);

            cw.sessions.add(sw);
        }

        // Calculate attendance percentage per course
        List<CourseAttendanceWrapper> result = new List<CourseAttendanceWrapper>();
        for (CourseAttendanceWrapper cw : courseMap.values()) {
            if (cw.totalSessions > 0) {
                Decimal pct = (Decimal.valueOf(cw.presentCount) /
                               Decimal.valueOf(cw.totalSessions)) * 100;
                cw.attendancePercentage = pct.setScale(2);
            } else {
                cw.attendancePercentage = 0;
            }
            // Flag students below 75%
            cw.isBelowThreshold = cw.attendancePercentage < 75;
            result.add(cw);
        }

        return result;
    }

    private static String getStatusClass(String status) {
        if (status == 'Present') return 'status-present';
        if (status == 'Absent')  return 'status-absent';
        if (status == 'Late')    return 'status-late';
        return 'status-excused';
    }

    // ── Wrappers ──────────────────────────────────────────────────────────────
    public class CourseAttendanceWrapper {
        @AuraEnabled public String  courseName;
        @AuraEnabled public String  sectionCode;
        @AuraEnabled public String  semester;
        @AuraEnabled public Integer totalSessions;
        @AuraEnabled public Integer presentCount;
        @AuraEnabled public Integer absentCount;
        @AuraEnabled public Integer lateCount;
        @AuraEnabled public Integer excusedCount;
        @AuraEnabled public Decimal attendancePercentage;
        @AuraEnabled public Boolean isBelowThreshold;
        @AuraEnabled public List<SessionWrapper> sessions;
    }

    public class SessionWrapper {
        @AuraEnabled public String sessionDate;
        @AuraEnabled public String topicsCovered;
        @AuraEnabled public String status;
        @AuraEnabled public String statusClass;
    }
}