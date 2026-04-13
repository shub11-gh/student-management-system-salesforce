// File: AssessmentDetailController.cls

public with sharing class AssessmentDetailController {

    @AuraEnabled(cacheable=true)
    public static AssessmentWrapper getAssessmentDetails(Id assessmentId) {

        Assessment__c assessment = [
            SELECT Id,
                   Name,
                   Assessment_Type__c,
                   Maximum_Marks__c,
                   Weightage__c,
                   Assessment_Date__c,
                   Course_Enrollment__r.Section_Code__c,
                   Course_Enrollment__r.Courses_Offering__r.Semester__c,
                   Course_Enrollment__r.Courses_Offering__r.Academic_Year__c,
                   Course_Enrollment__r.Courses_Offering__r.Courses__r.Name,
                   (SELECT Id,
                           Marks_Obtained__c,
                           Percentage__c,
                           Remarks__c,
                           Section_Student_Junction__r.Student__r.Name,
                           Section_Student_Junction__r.Student__r.Student_ID__c
                    FROM Assessment_Scores__r
                    ORDER BY Marks_Obtained__c DESC)
            FROM Assessment__c
            WHERE Id = :assessmentId
            LIMIT 1
        ];

        AssessmentWrapper aw    = new AssessmentWrapper();
        aw.assessmentName       = assessment.Name;
        aw.assessmentType       = assessment.Assessment_Type__c != null
                                    ? assessment.Assessment_Type__c : '—';
        aw.maximumMarks         = assessment.Maximum_Marks__c != null
                                    ? (Integer)assessment.Maximum_Marks__c : 0;
        aw.weightage            = assessment.Weightage__c != null
                                    ? assessment.Weightage__c.setScale(1) : 0;
        aw.assessmentDate       = assessment.Assessment_Date__c != null
                                    ? assessment.Assessment_Date__c.format() : '—';
        aw.courseName           = assessment.Course_Enrollment__r
                                    .Courses_Offering__r.Courses__r.Name;
        aw.sectionCode          = assessment.Course_Enrollment__r.Section_Code__c;
        aw.semester             = assessment.Course_Enrollment__r
                                    .Courses_Offering__r.Semester__c;
        aw.academicYear         = assessment.Course_Enrollment__r
                                    .Courses_Offering__r.Academic_Year__c;

        // Score calculations
        aw.totalScored          = assessment.Assessment_Scores__r.size();
        aw.scores               = new List<ScoreWrapper>();

        Decimal totalMarks      = 0;
        Decimal highest         = -1;
        Decimal lowest          = 999;
        Integer passCount       = 0;
        Decimal passMark        = aw.maximumMarks > 0
                                    ? aw.maximumMarks * 0.4 : 0;

        Integer rank = 1;
        for (Assessment_Score__c score : assessment.Assessment_Scores__r) {
            ScoreWrapper sw         = new ScoreWrapper();
            sw.scoreId              = score.Id;
            sw.studentName          = score.Section_Student_Junction__r
                                        .Student__r.Name;
            sw.studentCode          = score.Section_Student_Junction__r
                                        .Student__r.Student_ID__c;
            sw.marksObtained        = score.Marks_Obtained__c != null
                                        ? score.Marks_Obtained__c : 0;
            sw.percentage           = score.Percentage__c != null
                                        ? score.Percentage__c.setScale(1) : 0;
            sw.remarks              = score.Remarks__c != null
                                        ? score.Remarks__c : '—';
            sw.grade                = getGrade(sw.percentage);
            sw.gradeClass           = getGradeClass(sw.percentage);
            sw.rank                 = rank++;
            sw.scoreStyle           = 'width:' + sw.percentage + '%;background:'
                + getBarColor(sw.percentage);
            sw.isTopPerformer       = rank == 2;

            totalMarks += sw.marksObtained;
            if (sw.marksObtained > highest) highest = sw.marksObtained;
            if (sw.marksObtained < lowest)  lowest  = sw.marksObtained;
            if (sw.marksObtained >= passMark) passCount++;

            aw.scores.add(sw);
        }

        aw.classAverage  = aw.totalScored > 0
            ? (totalMarks / aw.totalScored).setScale(2) : 0;
        aw.highestMark   = highest >= 0 ? highest : 0;
        aw.lowestMark    = lowest < 999 ? lowest  : 0;
        aw.passCount     = passCount;
        aw.failCount     = aw.totalScored - passCount;
        aw.avgPercentage = aw.maximumMarks > 0
            ? (aw.classAverage / aw.maximumMarks * 100).setScale(1) : 0;
        aw.avgStyle      = 'width:' + aw.avgPercentage + '%;background:#D4500A';

        return aw;
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

    private static String getGradeClass(Decimal pct) {
        if (pct >= 70) return 'grade-high';
        if (pct >= 40) return 'grade-mid';
        return 'grade-low';
    }

    private static String getBarColor(Decimal pct) {
        if (pct >= 70) return '#D4500A';
        if (pct >= 40) return '#D97706';
        return '#B91C1C';
    }

    public class AssessmentWrapper {
        @AuraEnabled public String  assessmentName;
        @AuraEnabled public String  assessmentType;
        @AuraEnabled public Integer maximumMarks;
        @AuraEnabled public Decimal weightage;
        @AuraEnabled public String  assessmentDate;
        @AuraEnabled public String  courseName;
        @AuraEnabled public String  sectionCode;
        @AuraEnabled public String  semester;
        @AuraEnabled public String  academicYear;
        @AuraEnabled public Integer totalScored;
        @AuraEnabled public Integer passCount;
        @AuraEnabled public Integer failCount;
        @AuraEnabled public Decimal classAverage;
        @AuraEnabled public Decimal highestMark;
        @AuraEnabled public Decimal lowestMark;
        @AuraEnabled public Decimal avgPercentage;
        @AuraEnabled public String  avgStyle;
        @AuraEnabled public List<ScoreWrapper> scores;
    }

    public class ScoreWrapper {
        @AuraEnabled public Id      scoreId;
        @AuraEnabled public String  studentName;
        @AuraEnabled public String  studentCode;
        @AuraEnabled public Decimal marksObtained;
        @AuraEnabled public Decimal percentage;
        @AuraEnabled public String  grade;
        @AuraEnabled public String  gradeClass;
        @AuraEnabled public String  remarks;
        @AuraEnabled public Integer rank;
        @AuraEnabled public String  scoreStyle;
        @AuraEnabled public Boolean isTopPerformer;
    }
}