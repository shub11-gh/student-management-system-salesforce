// File: SectionEnrollmentDetailController.cls

public with sharing class SectionEnrollmentDetailController {

    @AuraEnabled(cacheable=true)
    public static SectionWrapper getSectionDetails(Id sectionId) {

        Course_Section_Enrollment__c section = [
            SELECT Id,
                   Name,
                   Section_Code__c,
                   Maximum_Capacity__c,
                   Courses_Offering__r.Academic_Year__c,
                   Courses_Offering__r.Semester__c,
                   Courses_Offering__r.Courses__r.Name,
                   Courses_Offering__r.Course_Coordinator__r.Name,
                   (SELECT Id,
                           Student__r.Name,
                           Student__r.Student_ID__c,
                           Student__r.Student_Email__c,
                           Student__r.CGPA__c,
                           Attendance_Percentage__c
                    FROM Section_Student_Junctions__r
                    ORDER BY Student__r.Name ASC),
                   (SELECT Id,
                           Name,
                           Assessment_Type__c,
                           Maximum_Marks__c,
                           Weightage__c,
                           Assessment_Date__c
                    FROM Assessments__r
                    ORDER BY Assessment_Date__c ASC),
                   (SELECT Id,
                           Name,
                           Session_Date__c,
                           Session_Status__c,
                           Topics_Covered__c,
                           Classroom_Number__c
                    FROM Classroom_Sessions__r
                    ORDER BY Session_Date__c DESC
                    LIMIT 10)
            FROM Course_Section_Enrollment__c
            WHERE Id = :sectionId
            LIMIT 1
        ];

        SectionWrapper sw       = new SectionWrapper();
        sw.sectionCode          = section.Section_Code__c != null
                                    ? section.Section_Code__c : '—';
        sw.courseName           = section.Courses_Offering__r.Courses__r.Name;
        sw.academicYear         = section.Courses_Offering__r.Academic_Year__c != null
                                    ? section.Courses_Offering__r.Academic_Year__c : '—';
        sw.semester             = section.Courses_Offering__r.Semester__c != null
                                    ? section.Courses_Offering__r.Semester__c : '—';
        sw.coordinator          = section.Courses_Offering__r.Course_Coordinator__r != null
                                    ? section.Courses_Offering__r.Course_Coordinator__r.Name
                                    : '—';
        sw.maxCapacity          = section.Maximum_Capacity__c != null
                                    ? (Integer)section.Maximum_Capacity__c : 0;
        sw.enrolledCount        = section.Section_Student_Junctions__r.size();
        sw.assessmentCount      = section.Assessments__r.size();
        sw.sessionCount         = section.Classroom_Sessions__r.size();

        // Capacity %
        sw.capacityPct          = sw.maxCapacity > 0
            ? ((Decimal)sw.enrolledCount / sw.maxCapacity * 100).setScale(0) : 0;

        // Students
        sw.students = new List<StudentWrapper>();
        Integer belowThreshold  = 0;
        for (Section_Student_Junction__c j :
                section.Section_Student_Junctions__r) {
            StudentWrapper stw      = new StudentWrapper();
            stw.junctionId          = j.Id;
            stw.studentName         = j.Student__r.Name;
            stw.studentCode         = j.Student__r.Student_ID__c;
            stw.studentEmail        = j.Student__r.Student_Email__c;
            stw.cgpa                = j.Student__r.CGPA__c != null
                                        ? j.Student__r.CGPA__c.setScale(2) : 0;
            stw.attendancePct       = j.Attendance_Percentage__c != null
                                        ? j.Attendance_Percentage__c.setScale(1) : 0;
            stw.attendanceStyle     = 'width:' + stw.attendancePct + '%;background:'
                + (stw.attendancePct >= 75 ? '#D4500A' : '#B91C1C');
            stw.attendanceClass     = stw.attendancePct >= 75
                                        ? 'badge-good' : 'badge-low';
            stw.attendanceStatus    = stw.attendancePct >= 75 ? 'Good' : 'Low';
            if (stw.attendancePct < 75) belowThreshold++;
            sw.students.add(stw);
        }
        sw.belowThreshold = belowThreshold;

        // Assessments
        sw.assessments = new List<AssessmentWrapper>();
        for (Assessment__c a : section.Assessments__r) {
            AssessmentWrapper aw    = new AssessmentWrapper();
            aw.assessmentId         = a.Id;
            aw.assessmentName       = a.Name;
            aw.assessmentType       = a.Assessment_Type__c != null
                                        ? a.Assessment_Type__c : '—';
            aw.maximumMarks         = a.Maximum_Marks__c != null
                                        ? (Integer)a.Maximum_Marks__c : 0;
            aw.weightage            = a.Weightage__c != null
                                        ? a.Weightage__c.setScale(1) : 0;
            aw.assessmentDate       = a.Assessment_Date__c != null
                                        ? a.Assessment_Date__c.format() : '—';
            sw.assessments.add(aw);
        }

        // Sessions
        sw.sessions = new List<SessionWrapper>();
        Integer completedCount = 0;
        for (Classroom_Session__c cs : section.Classroom_Sessions__r) {
            SessionWrapper sesw     = new SessionWrapper();
            sesw.sessionId          = cs.Id;
            sesw.sessionName        = cs.Name;
            sesw.sessionDate        = cs.Session_Date__c != null
                                        ? cs.Session_Date__c.format() : '—';
            sesw.sessionStatus      = cs.Session_Status__c != null
                                        ? cs.Session_Status__c : '—';
            sesw.topicsCovered      = cs.Topics_Covered__c != null
                                        ? cs.Topics_Covered__c : '—';
            sesw.classroomNumber    = cs.Classroom_Number__c != null
                                        ? cs.Classroom_Number__c : '—';
            sesw.statusClass        = getStatusClass(cs.Session_Status__c);
            if (cs.Session_Status__c == 'Completed') completedCount++;
            sw.sessions.add(sesw);
        }
        sw.completedSessions = completedCount;

        return sw;
    }

    private static String getStatusClass(String status) {
        if (status == 'Completed')  return 'badge-completed';
        if (status == 'Cancelled')  return 'badge-cancelled';
        return 'badge-scheduled';
    }

    public class SectionWrapper {
        @AuraEnabled public String  sectionCode;
        @AuraEnabled public String  courseName;
        @AuraEnabled public String  academicYear;
        @AuraEnabled public String  semester;
        @AuraEnabled public String  coordinator;
        @AuraEnabled public Integer maxCapacity;
        @AuraEnabled public Integer enrolledCount;
        @AuraEnabled public Integer assessmentCount;
        @AuraEnabled public Integer sessionCount;
        @AuraEnabled public Integer belowThreshold;
        @AuraEnabled public Integer completedSessions;
        @AuraEnabled public Decimal capacityPct;
        @AuraEnabled public List<StudentWrapper>    students;
        @AuraEnabled public List<AssessmentWrapper> assessments;
        @AuraEnabled public List<SessionWrapper>    sessions;
    }

    public class StudentWrapper {
        @AuraEnabled public Id      junctionId;
        @AuraEnabled public String  studentName;
        @AuraEnabled public String  studentCode;
        @AuraEnabled public String  studentEmail;
        @AuraEnabled public Decimal cgpa;
        @AuraEnabled public Decimal attendancePct;
        @AuraEnabled public String  attendanceStyle;
        @AuraEnabled public String  attendanceClass;
        @AuraEnabled public String  attendanceStatus;
    }

    public class AssessmentWrapper {
        @AuraEnabled public Id      assessmentId;
        @AuraEnabled public String  assessmentName;
        @AuraEnabled public String  assessmentType;
        @AuraEnabled public Integer maximumMarks;
        @AuraEnabled public Decimal weightage;
        @AuraEnabled public String  assessmentDate;
    }

    public class SessionWrapper {
        @AuraEnabled public Id     sessionId;
        @AuraEnabled public String sessionName;
        @AuraEnabled public String sessionDate;
        @AuraEnabled public String sessionStatus;
        @AuraEnabled public String topicsCovered;
        @AuraEnabled public String classroomNumber;
        @AuraEnabled public String statusClass;
    }
}