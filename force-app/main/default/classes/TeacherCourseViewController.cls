// File: TeacherCourseViewController.cls

public with sharing class TeacherCourseViewController {

    @AuraEnabled(cacheable=true)
    public static List<CourseOfferingWrapper> getTeacherCourses(Id teacherId) {

        // Get all course offerings coordinated by this teacher
        List<Course_Section_Enrollment__c> sections = [
            SELECT Id,
                   Section_Code__c,
                   Maximum_Capacity__c,
                   Courses_Offering__r.Academic_Year__c,
                   Courses_Offering__r.Semester__c,
                   Courses_Offering__r.Courses__r.Name,
                   Courses_Offering__r.Courses__r.Course_ID__c,
                   (SELECT Id,
                           Student__r.Name,
                           Student__r.Student_ID__c,
                           Student__r.Student_Email__c,
                           Attendance_Percentage__c
                    FROM Section_Student_Junctions__r
                    ORDER BY Student__r.Name ASC),
                   (SELECT Id,
                           Name,
                           Session_Date__c,
                           Topics_Covered__c,
                           Session_Status__c,
                           Classroom_Number__c
                    FROM Classroom_Sessions__r
                    ORDER BY Session_Date__c DESC
                    LIMIT 5)
            FROM Course_Section_Enrollment__c
            WHERE Courses_Offering__r.Course_Coordinator__c = :teacherId
            ORDER BY Courses_Offering__r.Courses__r.Name ASC
        ];

        List<CourseOfferingWrapper> result = new List<CourseOfferingWrapper>();

        for (Course_Section_Enrollment__c section : sections) {

            CourseOfferingWrapper cw = new CourseOfferingWrapper();
            cw.sectionId     = section.Id;
            cw.courseName    = section.Courses_Offering__r.Courses__r.Name;
            cw.courseId      = section.Courses_Offering__r.Courses__r.Course_ID__c;
            cw.sectionCode   = section.Section_Code__c;
            cw.academicYear  = section.Courses_Offering__r.Academic_Year__c;
            cw.semester      = section.Courses_Offering__r.Semester__c;
            cw.maxCapacity   = section.Maximum_Capacity__c != null
                                 ? (Integer)section.Maximum_Capacity__c : 0;

            // Students
            cw.students = new List<StudentWrapper>();
            Integer belowThreshold = 0;
            for (Section_Student_Junction__c j : section.Section_Student_Junctions__r) {
                StudentWrapper sw       = new StudentWrapper();
                sw.studentName          = j.Student__r.Name;
                sw.studentId            = j.Student__r.Student_ID__c;
                sw.studentEmail         = j.Student__r.Student_Email__c;
                sw.attendancePct        = j.Attendance_Percentage__c != null
                                            ? j.Attendance_Percentage__c.setScale(2) : 0;
                sw.attendanceStatus     = sw.attendancePct >= 75 ? 'Good' : 'Low';
                sw.attendanceClass      = sw.attendancePct >= 75
                                            ? 'status-good' : 'status-low';
                if (sw.attendancePct < 75) belowThreshold++;
                cw.students.add(sw);
            }
            cw.enrolledCount   = cw.students.size();
            cw.belowThreshold  = belowThreshold;

            // Recent Sessions
            cw.recentSessions = new List<SessionWrapper>();
            for (Classroom_Session__c cs : section.Classroom_Sessions__r) {
                SessionWrapper sw    = new SessionWrapper();
                sw.sessionDate       = cs.Session_Date__c != null
                                         ? cs.Session_Date__c.format() : '—';
                sw.topicsCovered     = cs.Topics_Covered__c != null
                                         ? cs.Topics_Covered__c : '—';
                sw.sessionStatus     = cs.Session_Status__c;
                sw.classroomNumber   = cs.Classroom_Number__c;
                sw.statusClass       = getSessionStatusClass(cs.Session_Status__c);
                cw.recentSessions.add(sw);
            }

            result.add(cw);
        }

        return result;
    }

    private static String getSessionStatusClass(String status) {
        if (status == 'Completed')  return 'session-completed';
        if (status == 'Scheduled')  return 'session-scheduled';
        if (status == 'Cancelled')  return 'session-cancelled';
        return 'session-scheduled';
    }

    // ── Wrappers ──────────────────────────────────────────────────────────────
    public class CourseOfferingWrapper {
        @AuraEnabled public Id      sectionId;
        @AuraEnabled public String  courseName;
        @AuraEnabled public String  courseId;
        @AuraEnabled public String  sectionCode;
        @AuraEnabled public String  academicYear;
        @AuraEnabled public String  semester;
        @AuraEnabled public Integer maxCapacity;
        @AuraEnabled public Integer enrolledCount;
        @AuraEnabled public Integer belowThreshold;
        @AuraEnabled public List<StudentWrapper>  students;
        @AuraEnabled public List<SessionWrapper>  recentSessions;
    }

    public class StudentWrapper {
        @AuraEnabled public String  studentName;
        @AuraEnabled public String  studentId;
        @AuraEnabled public String  studentEmail;
        @AuraEnabled public Decimal attendancePct;
        @AuraEnabled public String  attendanceStatus;
        @AuraEnabled public String  attendanceClass;
    }

    public class SessionWrapper {
        @AuraEnabled public String sessionDate;
        @AuraEnabled public String topicsCovered;
        @AuraEnabled public String sessionStatus;
        @AuraEnabled public String classroomNumber;
        @AuraEnabled public String statusClass;
    }
}