// File: AttendanceRecordViewController.cls

public with sharing class AttendanceRecordViewController {

    @AuraEnabled(cacheable=true)
    public static AttendanceWrapper getAttendanceDetails(Id attendanceId) {

        Attendance__c attendance = [
            SELECT Id,
                   Name,
                   Status__c,
                   Remarks__c,
                   Classroom_Session__r.Name,
                   Classroom_Session__r.Session_Date__c,
                   Classroom_Session__r.Topics_Covered__c,
                   Classroom_Session__r.Classroom_Number__c,
                   Classroom_Session__r.Session_Status__c,
                   Classroom_Session__r.Courses_Enrollment__r.Section_Code__c,
                   Classroom_Session__r.Courses_Enrollment__r.Courses_Offering__r.Courses__r.Name,
                   Classroom_Session__r.Courses_Enrollment__r.Courses_Offering__r.Semester__c,
                   Section_Student_Junction__r.Student__r.Name,
                   Section_Student_Junction__r.Student__r.Student_ID__c,
                   Section_Student_Junction__r.Attendance_Percentage__c
            FROM Attendance__c
            WHERE Id = :attendanceId
            LIMIT 1
        ];

        AttendanceWrapper aw    = new AttendanceWrapper();
        aw.attendanceName       = attendance.Name;
        aw.status               = attendance.Status__c != null
                                    ? attendance.Status__c : '—';
        aw.statusClass          = getStatusClass(attendance.Status__c);
        aw.remarks              = attendance.Remarks__c != null
                                    ? attendance.Remarks__c : 'No remarks';
        aw.studentName          = attendance.Section_Student_Junction__r
                                    .Student__r.Name;
        aw.studentCode          = attendance.Section_Student_Junction__r
                                    .Student__r.Student_ID__c;
        aw.overallAttendancePct = attendance.Section_Student_Junction__r
                                    .Attendance_Percentage__c != null
                                    ? attendance.Section_Student_Junction__r
                                        .Attendance_Percentage__c.setScale(1)
                                    : 0;
        aw.attendanceStyle      = 'width:' + aw.overallAttendancePct
                                    + '%;background:'
                                    + (aw.overallAttendancePct >= 75
                                        ? '#D4500A' : '#B91C1C');
        aw.attendanceStatus     = aw.overallAttendancePct >= 75 ? 'Good' : 'Low';
        aw.attendanceStatusClass = aw.overallAttendancePct >= 75
                                    ? 'badge-good' : 'badge-low';
        aw.sessionName          = attendance.Classroom_Session__r.Name;
        aw.sessionDate          = attendance.Classroom_Session__r
                                    .Session_Date__c != null
                                    ? attendance.Classroom_Session__r
                                        .Session_Date__c.format() : '—';
        aw.topicsCovered        = attendance.Classroom_Session__r
                                    .Topics_Covered__c != null
                                    ? attendance.Classroom_Session__r
                                        .Topics_Covered__c : '—';
        aw.classroomNumber      = attendance.Classroom_Session__r
                                    .Classroom_Number__c != null
                                    ? attendance.Classroom_Session__r
                                        .Classroom_Number__c : '—';
        aw.sessionStatus        = attendance.Classroom_Session__r
                                    .Session_Status__c != null
                                    ? attendance.Classroom_Session__r
                                        .Session_Status__c : '—';
        aw.courseName           = attendance.Classroom_Session__r
                                    .Courses_Enrollment__r
                                    .Courses_Offering__r.Courses__r.Name;
        aw.sectionCode          = attendance.Classroom_Session__r
                                    .Courses_Enrollment__r.Section_Code__c;
        aw.semester             = attendance.Classroom_Session__r
                                    .Courses_Enrollment__r
                                    .Courses_Offering__r.Semester__c;

        return aw;
    }

    private static String getStatusClass(String status) {
        if (status == 'Present') return 'badge-present';
        if (status == 'Absent')  return 'badge-absent';
        if (status == 'Late')    return 'badge-late';
        return 'badge-excused';
    }

    public class AttendanceWrapper {
        @AuraEnabled public String  attendanceName;
        @AuraEnabled public String  status;
        @AuraEnabled public String  statusClass;
        @AuraEnabled public String  remarks;
        @AuraEnabled public String  studentName;
        @AuraEnabled public String  studentCode;
        @AuraEnabled public Decimal overallAttendancePct;
        @AuraEnabled public String  attendanceStyle;
        @AuraEnabled public String  attendanceStatus;
        @AuraEnabled public String  attendanceStatusClass;
        @AuraEnabled public String  sessionName;
        @AuraEnabled public String  sessionDate;
        @AuraEnabled public String  topicsCovered;
        @AuraEnabled public String  classroomNumber;
        @AuraEnabled public String  sessionStatus;
        @AuraEnabled public String  courseName;
        @AuraEnabled public String  sectionCode;
        @AuraEnabled public String  semester;
    }
}