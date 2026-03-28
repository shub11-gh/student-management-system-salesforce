// File: StudentGradeReportController.cls

public with sharing class StudentGradeReportController {

    // This method is called from the LWC JavaScript file
    // @AuraEnabled makes it accessible to LWC
    // (cacheable=true) means the result is cached — faster for read-only data
    @AuraEnabled(cacheable=true)
    public static List<CourseGradeWrapper> getStudentGrades(Id studentId) {

        // Query all assessment scores for this student
        // Traversing: Junction → Assessment Score → Assessment → CSE → Offering → Course
        List<Assessment_Score__c> scores = [
            SELECT Id,
                   Marks_Obtained__c,
                   Percentage__c,
                   Remarks__c,
                   Assessment__r.Name,
                   Assessment__r.Assessment_Type__c,
                   Assessment__r.Maximum_Marks__c,
                   Assessment__r.Weightage__c,
                   Assessment__r.Assessment_Date__c,
                   Assessment__r.Course_Enrollment__r.Section_Code__c,
                   Assessment__r.Course_Enrollment__r.Courses_Offering__r.Semester__c,
                   Assessment__r.Course_Enrollment__r.Courses_Offering__r.Courses__r.Name
            FROM Assessment_Score__c
            WHERE Section_Student_Junction__r.Student__c = :studentId
              AND Marks_Obtained__c != null
            ORDER BY Assessment__r.Course_Enrollment__r.Courses_Offering__r.Courses__r.Name,
                     Assessment__r.Assessment_Date__c ASC
        ];

        // Group scores by Course Name using a Map
        Map<String, CourseGradeWrapper> courseMap = new Map<String, CourseGradeWrapper>();

        for (Assessment_Score__c score : scores) {
            String courseName = score.Assessment__r.Course_Enrollment__r
                                    .Courses_Offering__r.Courses__r.Name;
            String section    = score.Assessment__r.Course_Enrollment__r.Section_Code__c;
            String semester   = score.Assessment__r.Course_Enrollment__r
                                    .Courses_Offering__r.Semester__c;

            // Create a new course wrapper if we haven't seen this course yet
            if (!courseMap.containsKey(courseName)) {
                CourseGradeWrapper wrapper  = new CourseGradeWrapper();
                wrapper.courseName          = courseName;
                wrapper.sectionCode         = section;
                wrapper.semester            = semester;
                wrapper.assessments         = new List<AssessmentWrapper>();
                courseMap.put(courseName, wrapper);
            }

            // Build an assessment row
            AssessmentWrapper aw    = new AssessmentWrapper();
            aw.assessmentName       = score.Assessment__r.Name;
            aw.assessmentType       = score.Assessment__r.Assessment_Type__c;
            aw.marksObtained        = score.Marks_Obtained__c;
            aw.maximumMarks         = score.Assessment__r.Maximum_Marks__c;
            aw.weightage            = score.Assessment__r.Weightage__c;
            aw.percentage           = score.Percentage__c != null
                                        ? score.Percentage__c.setScale(2)
                                        : 0;
            aw.assessmentDate       = score.Assessment__r.Assessment_Date__c != null
                                        ? score.Assessment__r.Assessment_Date__c
                                                .format()
                                        : '—';
            aw.remarks              = score.Remarks__c != null ? score.Remarks__c : '—';

            // Grade letter based on percentage
            aw.grade = getGrade(aw.percentage);

            courseMap.get(courseName).assessments.add(aw);
        }

        // Calculate course-level weighted average for each course
        List<CourseGradeWrapper> result = new List<CourseGradeWrapper>();
        for (CourseGradeWrapper cw : courseMap.values()) {
            Decimal totalWeighted = 0;
            Decimal totalWeight   = 0;
            for (AssessmentWrapper aw : cw.assessments) {
                if (aw.weightage != null && aw.maximumMarks != null && aw.maximumMarks > 0) {
                    totalWeighted += (aw.marksObtained / aw.maximumMarks) * aw.weightage;
                    totalWeight   += aw.weightage;
                }
            }
            cw.courseAverage = totalWeight > 0
                ? ((totalWeighted / totalWeight) * 100).setScale(2)
                : 0;
            cw.courseGrade   = getGrade(cw.courseAverage);
            result.add(cw);
        }

        return result;
    }

    // Helper: convert percentage to letter grade
    private static String getGrade(Decimal percentage) {
        if (percentage >= 90) return 'O';
        if (percentage >= 80) return 'A+';
        if (percentage >= 70) return 'A';
        if (percentage >= 60) return 'B+';
        if (percentage >= 50) return 'B';
        if (percentage >= 40) return 'C';
        return 'F';
    }

    // ── Wrapper Classes ───────────────────────────────────────────────────────
    // Wrappers are simple data containers used to pass structured
    // data back to the LWC — like JSON objects in JavaScript

    public class CourseGradeWrapper {
        @AuraEnabled public String courseName;
        @AuraEnabled public String sectionCode;
        @AuraEnabled public String semester;
        @AuraEnabled public Decimal courseAverage;
        @AuraEnabled public String courseGrade;
        @AuraEnabled public List<AssessmentWrapper> assessments;
    }

    public class AssessmentWrapper {
        @AuraEnabled public String assessmentName;
        @AuraEnabled public String assessmentType;
        @AuraEnabled public Decimal marksObtained;
        @AuraEnabled public Decimal maximumMarks;
        @AuraEnabled public Decimal weightage;
        @AuraEnabled public Decimal percentage;
        @AuraEnabled public String assessmentDate;
        @AuraEnabled public String remarks;
        @AuraEnabled public String grade;
    }
}