// File: CourseOfferingDetailController.cls

public with sharing class CourseOfferingDetailController {

    @AuraEnabled(cacheable=true)
    public static OfferingWrapper getOfferingDetails(Id offeringId) {

        Course_Offering__c offering = [
            SELECT Id,
                   Name,
                   Academic_Year__c,
                   Semester__c,
                   Course_Coordinator__r.Name,
                   Course_Coordinator__r.Teacher_Email__c,
                   Course_Coordinator__r.Department__c,
                   Courses__r.Name,
                   Courses__r.Course_ID__c,
                   (SELECT Id,
                           Section_Code__c,
                           Maximum_Capacity__c,
                           (SELECT Id, Attendance_Percentage__c
                            FROM Section_Student_Junctions__r),
                           (SELECT Id FROM Assessments__r)
                    FROM Course_Section_Enrollments__r
                    ORDER BY Section_Code__c ASC)
            FROM Course_Offering__c
            WHERE Id = :offeringId
            LIMIT 1
        ];

        OfferingWrapper ow      = new OfferingWrapper();
        ow.courseName           = offering.Courses__r.Name;
        ow.courseCode           = offering.Courses__r.Course_ID__c;
        ow.academicYear         = offering.Academic_Year__c != null
                                    ? offering.Academic_Year__c : '—';
        ow.semester             = offering.Semester__c != null
                                    ? offering.Semester__c : '—';
        ow.coordinatorName      = offering.Course_Coordinator__r != null
                                    ? offering.Course_Coordinator__r.Name : '—';
        ow.coordinatorEmail     = offering.Course_Coordinator__r != null
                                    ? offering.Course_Coordinator__r.Teacher_Email__c : '—';
        ow.coordinatorDept      = offering.Course_Coordinator__r != null
                                    ? offering.Course_Coordinator__r.Department__c : '—';
        ow.totalSections        = offering.Course_Section_Enrollments__r.size();
        ow.totalStudents        = 0;
        ow.totalAssessments     = 0;
        ow.sections             = new List<SectionWrapper>();

        for (Course_Section_Enrollment__c section :
                offering.Course_Section_Enrollments__r) {

            SectionWrapper sw    = new SectionWrapper();
            sw.sectionId         = section.Id;
            sw.sectionCode       = section.Section_Code__c != null
                                     ? section.Section_Code__c : '—';
            sw.maxCapacity       = section.Maximum_Capacity__c != null
                                     ? (Integer)section.Maximum_Capacity__c : 0;
            sw.enrolledCount     = section.Section_Student_Junctions__r.size();
            sw.assessmentCount   = section.Assessments__r.size();
            ow.totalStudents    += sw.enrolledCount;
            ow.totalAssessments += sw.assessmentCount;

            // Average attendance across all students in section
            Decimal totalPct = 0;
            Integer counted  = 0;
            for (Section_Student_Junction__c j :
                    section.Section_Student_Junctions__r) {
                if (j.Attendance_Percentage__c != null) {
                    totalPct += j.Attendance_Percentage__c;
                    counted++;
                }
            }
            sw.avgAttendance = counted > 0
                ? (totalPct / counted).setScale(1) : 0;

            sw.capacityPct   = sw.maxCapacity > 0
                ? ((Decimal)sw.enrolledCount / sw.maxCapacity * 100).setScale(0)
                : 0;
            sw.capacityStyle = 'width:' + sw.capacityPct + '%;background:'
                + (sw.capacityPct >= 90 ? '#B91C1C'
                :  sw.capacityPct >= 70 ? '#D4500A'
                :                         '#15803D');
            sw.attendanceStyle = 'width:' + sw.avgAttendance + '%;background:'
                + (sw.avgAttendance >= 75 ? '#D4500A' : '#B91C1C');

            ow.sections.add(sw);
        }

        return ow;
    }

    public class OfferingWrapper {
        @AuraEnabled public String  courseName;
        @AuraEnabled public String  courseCode;
        @AuraEnabled public String  academicYear;
        @AuraEnabled public String  semester;
        @AuraEnabled public String  coordinatorName;
        @AuraEnabled public String  coordinatorEmail;
        @AuraEnabled public String  coordinatorDept;
        @AuraEnabled public Integer totalSections;
        @AuraEnabled public Integer totalStudents;
        @AuraEnabled public Integer totalAssessments;
        @AuraEnabled public List<SectionWrapper> sections;
    }

    public class SectionWrapper {
        @AuraEnabled public Id      sectionId;
        @AuraEnabled public String  sectionCode;
        @AuraEnabled public Integer maxCapacity;
        @AuraEnabled public Integer enrolledCount;
        @AuraEnabled public Integer assessmentCount;
        @AuraEnabled public Decimal avgAttendance;
        @AuraEnabled public Decimal capacityPct;
        @AuraEnabled public String  capacityStyle;
        @AuraEnabled public String  attendanceStyle;
    }
}