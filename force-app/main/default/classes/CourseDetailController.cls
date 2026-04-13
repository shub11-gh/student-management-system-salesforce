// File: CourseDetailController.cls

public with sharing class CourseDetailController {

    @AuraEnabled(cacheable=true)
    public static CourseWrapper getCourseDetails(Id courseId) {

        // Query the course with all related offerings → sections → students
        Course__c course = [
            SELECT Id,
                   Name,
                   Course_ID__c,
                   (SELECT Id,
                           Name,
                           Academic_Year__c,
                           Semester__c,
                           Course_Coordinator__r.Name,
                           (SELECT Id,
                                   Section_Code__c,
                                   Maximum_Capacity__c,
                                   (SELECT Id FROM Section_Student_Junctions__r)
                            FROM Course_Section_Enrollments__r)
                    FROM Course_Offerings__r
                    ORDER BY Academic_Year__c DESC, Semester__c ASC)
            FROM Course__c
            WHERE Id = :courseId
            LIMIT 1
        ];

        CourseWrapper cw     = new CourseWrapper();
        cw.courseName        = course.Name;
        cw.courseCode        = course.Course_ID__c;
        cw.totalOfferings    = 0;
        cw.totalSections     = 0;
        cw.totalStudents     = 0;
        cw.offerings         = new List<OfferingWrapper>();

        for (Course_Offering__c offering : course.Course_Offerings__r) {
            cw.totalOfferings++;

            OfferingWrapper ow  = new OfferingWrapper();
            ow.offeringId       = offering.Id;
            ow.offeringName     = offering.Name;
            ow.academicYear     = offering.Academic_Year__c != null
                                    ? offering.Academic_Year__c : '—';
            ow.semester         = offering.Semester__c != null
                                    ? offering.Semester__c : '—';
            ow.coordinator      = offering.Course_Coordinator__r != null
                                    ? offering.Course_Coordinator__r.Name : '—';
            ow.sections         = new List<SectionWrapper>();

            for (Course_Section_Enrollment__c section :
                        offering.Course_Section_Enrollments__r) {
                cw.totalSections++;

                SectionWrapper sw   = new SectionWrapper();
                sw.sectionId        = section.Id;
                sw.sectionCode      = section.Section_Code__c != null
                                        ? section.Section_Code__c : '—';
                sw.maxCapacity      = section.Maximum_Capacity__c != null
                                        ? (Integer)section.Maximum_Capacity__c : 0;
                sw.enrolledCount    = section.Section_Student_Junctions__r.size();
                cw.totalStudents   += sw.enrolledCount;

                // Capacity fill percentage for progress bar
                sw.capacityPct      = sw.maxCapacity > 0
                    ? ((Decimal)sw.enrolledCount / sw.maxCapacity * 100).setScale(0)
                    : 0;
                sw.capacityStyle    = 'width:' + sw.capacityPct + '%;background:'
                    + (sw.capacityPct >= 90 ? '#B91C1C'
                    : sw.capacityPct >= 70  ? '#D4500A'
                    :                         '#15803D');

                ow.sections.add(sw);
            }

            cw.offerings.add(ow);
        }

        return cw;
    }

    public class CourseWrapper {
        @AuraEnabled public String  courseName;
        @AuraEnabled public String  courseCode;
        @AuraEnabled public Integer totalOfferings;
        @AuraEnabled public Integer totalSections;
        @AuraEnabled public Integer totalStudents;
        @AuraEnabled public List<OfferingWrapper> offerings;
    }

    public class OfferingWrapper {
        @AuraEnabled public Id     offeringId;
        @AuraEnabled public String offeringName;
        @AuraEnabled public String academicYear;
        @AuraEnabled public String semester;
        @AuraEnabled public String coordinator;
        @AuraEnabled public List<SectionWrapper> sections;
    }

    public class SectionWrapper {
        @AuraEnabled public Id      sectionId;
        @AuraEnabled public String  sectionCode;
        @AuraEnabled public Integer maxCapacity;
        @AuraEnabled public Integer enrolledCount;
        @AuraEnabled public Decimal capacityPct;
        @AuraEnabled public String  capacityStyle;
    }
}