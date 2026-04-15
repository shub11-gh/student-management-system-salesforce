// File: ClassroomSessionDetailController.cls

public with sharing class ClassroomSessionDetailController {

    @AuraEnabled(cacheable=true)
    public static SessionWrapper getSessionDetails(Id sessionId) {

        Classroom_Session__c session = [
            SELECT Id,
                   Name,
                   Session_Date__c,
                   Session_Status__c,
                   Topics_Covered__c,
                   Classroom_Number__c,
                   Courses_Enrollment__r.Section_Code__c,
                   Courses_Enrollment__r.Courses_Offering__r.Semester__c,
                   Courses_Enrollment__r.Courses_Offering__r.Academic_Year__c,
                   Courses_Enrollment__r.Courses_Offering__r.Courses__r.Name,
                   Courses_Enrollment__r.Courses_Offering__r.Course_Coordinator__r.Name,
                   (SELECT Id,
                           Status__c,
                           Remarks__c,
                           Section_Student_Junction__r.Student__r.Name,
                           Section_Student_Junction__r.Student__r.Student_ID__c
                    FROM Attendances__r
                    ORDER BY Section_Student_Junction__r.Student__r.Name ASC)
            FROM Classroom_Session__c
            WHERE Id = :sessionId
            LIMIT 1
        ];

        SessionWrapper sw       = new SessionWrapper();
        sw.sessionName          = session.Name;
        sw.sessionDate          = session.Session_Date__c != null
                                    ? session.Session_Date__c.format() : '—';
        sw.sessionStatus        = session.Session_Status__c != null
                                    ? session.Session_Status__c : '—';
        sw.statusClass          = getStatusClass(session.Session_Status__c);
        sw.topicsCovered        = session.Topics_Covered__c != null
                                    ? session.Topics_Covered__c : '—';
        sw.classroomNumber      = session.Classroom_Number__c != null
                                    ? session.Classroom_Number__c : '—';
        sw.courseName           = session.Courses_Enrollment__r
                                    .Courses_Offering__r.Courses__r.Name;
        sw.sectionCode          = session.Courses_Enrollment__r.Section_Code__c;
        sw.semester             = session.Courses_Enrollment__r
                                    .Courses_Offering__r.Semester__c;
        sw.academicYear         = session.Courses_Enrollment__r
                                    .Courses_Offering__r.Academic_Year__c;
        sw.coordinator          = session.Courses_Enrollment__r
                                    .Courses_Offering__r.Course_Coordinator__r != null
                                    ? session.Courses_Enrollment__r
                                        .Courses_Offering__r.Course_Coordinator__r.Name
                                    : '—';

        // Count attendance by status
        sw.totalStudents  = session.Attendances__r.size();
        sw.presentCount   = 0;
        sw.absentCount    = 0;
        sw.lateCount      = 0;
        sw.excusedCount   = 0;
        sw.attendance     = new List<AttendanceWrapper>();

        for (Attendance__c a : session.Attendances__r) {
            AttendanceWrapper aw    = new AttendanceWrapper();
            aw.attendanceId         = a.Id;
            aw.studentName          = a.Section_Student_Junction__r.Student__r.Name;
            aw.studentCode          = a.Section_Student_Junction__r
                                        .Student__r.Student_ID__c;
            aw.status               = a.Status__c != null ? a.Status__c : '—';
            aw.remarks              = a.Remarks__c != null ? a.Remarks__c : '—';
            aw.statusClass          = getAttendanceClass(a.Status__c);

            if (a.Status__c == 'Present')      sw.presentCount++;
            else if (a.Status__c == 'Absent')  sw.absentCount++;
            else if (a.Status__c == 'Late')    sw.lateCount++;
            else if (a.Status__c == 'Excused') sw.excusedCount++;

            sw.attendance.add(aw);
        }

        // Attendance percentage for this session
        sw.attendancePct    = sw.totalStudents > 0
            ? ((Decimal)sw.presentCount / sw.totalStudents * 100).setScale(1) : 0;
        sw.attendanceStyle  = 'width:' + sw.attendancePct + '%;background:'
            + (sw.attendancePct >= 75 ? '#D4500A' : '#B91C1C');

        return sw;
    }

    private static String getStatusClass(String status) {
        if (status == 'Completed')  return 'badge-completed';
        if (status == 'Cancelled')  return 'badge-cancelled';
        return 'badge-scheduled';
    }

    private static String getAttendanceClass(String status) {
        if (status == 'Present') return 'badge-present';
        if (status == 'Absent')  return 'badge-absent';
        if (status == 'Late')    return 'badge-late';
        return 'badge-excused';
    }

    public class SessionWrapper {
        @AuraEnabled public String  sessionName;
        @AuraEnabled public String  sessionDate;
        @AuraEnabled public String  sessionStatus;
        @AuraEnabled public String  statusClass;
        @AuraEnabled public String  topicsCovered;
        @AuraEnabled public String  classroomNumber;
        @AuraEnabled public String  courseName;
        @AuraEnabled public String  sectionCode;
        @AuraEnabled public String  semester;
        @AuraEnabled public String  academicYear;
        @AuraEnabled public String  coordinator;
        @AuraEnabled public Integer totalStudents;
        @AuraEnabled public Integer presentCount;
        @AuraEnabled public Integer absentCount;
        @AuraEnabled public Integer lateCount;
        @AuraEnabled public Integer excusedCount;
        @AuraEnabled public Decimal attendancePct;
        @AuraEnabled public String  attendanceStyle;
        @AuraEnabled public List<AttendanceWrapper> attendance;
    }

    public class AttendanceWrapper {
        @AuraEnabled public Id     attendanceId;
        @AuraEnabled public String studentName;
        @AuraEnabled public String studentCode;
        @AuraEnabled public String status;
        @AuraEnabled public String remarks;
        @AuraEnabled public String statusClass;
    }
}