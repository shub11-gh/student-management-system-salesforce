// File: AssessmentScoreViewController.cls

public with sharing class AssessmentScoreViewController {

    @AuraEnabled(cacheable=true)
    public static ScoreWrapper getScoreDetails(Id scoreId) {

        Assessment_Score__c score = [
            SELECT Id,
                   Name,
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
                   Assessment__r.Course_Enrollment__r.Courses_Offering__r.Courses__r.Name,
                   Section_Student_Junction__r.Student__r.Name,
                   Section_Student_Junction__r.Student__r.Student_ID__c,
                   Section_Student_Junction__r.Student__r.CGPA__c
            FROM Assessment_Score__c
            WHERE Id = :scoreId
            LIMIT 1
        ];

        // Get all scores for this assessment to calculate rank and class average
        List<Assessment_Score__c> allScores = [
            SELECT Id, Marks_Obtained__c
            FROM Assessment_Score__c
            WHERE Assessment__c = :score.Assessment__c
              AND Marks_Obtained__c != null
            ORDER BY Marks_Obtained__c DESC
        ];

        ScoreWrapper sw         = new ScoreWrapper();
        sw.scoreName            = score.Name;
        sw.studentName          = score.Section_Student_Junction__r
                                    .Student__r.Name;
        sw.studentCode          = score.Section_Student_Junction__r
                                    .Student__r.Student_ID__c;
        sw.cgpa                 = score.Section_Student_Junction__r
                                    .Student__r.CGPA__c != null
                                    ? score.Section_Student_Junction__r
                                        .Student__r.CGPA__c.setScale(2) : 0;
        sw.assessmentName       = score.Assessment__r.Name;
        sw.assessmentType       = score.Assessment__r.Assessment_Type__c != null
                                    ? score.Assessment__r.Assessment_Type__c : '—';
        sw.maximumMarks         = score.Assessment__r.Maximum_Marks__c != null
                                    ? (Integer)score.Assessment__r.Maximum_Marks__c
                                    : 0;
        sw.weightage            = score.Assessment__r.Weightage__c != null
                                    ? score.Assessment__r.Weightage__c.setScale(1)
                                    : 0;
        sw.assessmentDate       = score.Assessment__r.Assessment_Date__c != null
                                    ? score.Assessment__r.Assessment_Date__c.format()
                                    : '—';
        sw.courseName           = score.Assessment__r.Course_Enrollment__r
                                    .Courses_Offering__r.Courses__r.Name;
        sw.sectionCode          = score.Assessment__r.Course_Enrollment__r
                                    .Section_Code__c;
        sw.semester             = score.Assessment__r.Course_Enrollment__r
                                    .Courses_Offering__r.Semester__c;
        sw.marksObtained        = score.Marks_Obtained__c != null
                                    ? score.Marks_Obtained__c : 0;
        sw.percentage           = score.Percentage__c != null
                                    ? score.Percentage__c.setScale(1) : 0;
        sw.remarks              = score.Remarks__c != null
                                    ? score.Remarks__c : 'No remarks';
        sw.grade                = getGrade(sw.percentage);
        sw.gradeClass           = getGradeClass(sw.percentage);
        sw.scoreStyle           = 'width:' + sw.percentage + '%;background:'
                                    + getBarColor(sw.percentage);

        // Class average and rank calculation
        Decimal totalMarks      = 0;
        Integer rank            = 1;
        Integer totalStudents   = allScores.size();

        for (Assessment_Score__c s : allScores) {
            if (s.Marks_Obtained__c != null) {
                totalMarks += s.Marks_Obtained__c;
                if (s.Marks_Obtained__c > sw.marksObtained) rank++;
            }
        }

        sw.rank             = rank;
        sw.totalStudents    = totalStudents;
        sw.classAverage     = totalStudents > 0
            ? (totalMarks / totalStudents).setScale(2) : 0;
        sw.classAvgPct      = sw.maximumMarks > 0
            ? (sw.classAverage / sw.maximumMarks * 100).setScale(1) : 0;
        sw.classAvgStyle    = 'width:' + sw.classAvgPct + '%;background:#78716C';
        sw.isTopPerformer   = rank == 1;
        sw.isAboveAverage   = sw.marksObtained > sw.classAverage;

        // Weighted contribution to CGPA
        sw.weightedScore    = sw.maximumMarks > 0
            ? ((sw.marksObtained / sw.maximumMarks) * sw.weightage).setScale(2)
            : 0;

        return sw;
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

    public class ScoreWrapper {
        @AuraEnabled public String  scoreName;
        @AuraEnabled public String  studentName;
        @AuraEnabled public String  studentCode;
        @AuraEnabled public Decimal cgpa;
        @AuraEnabled public String  assessmentName;
        @AuraEnabled public String  assessmentType;
        @AuraEnabled public Integer maximumMarks;
        @AuraEnabled public Decimal weightage;
        @AuraEnabled public String  assessmentDate;
        @AuraEnabled public String  courseName;
        @AuraEnabled public String  sectionCode;
        @AuraEnabled public String  semester;
        @AuraEnabled public Decimal marksObtained;
        @AuraEnabled public Decimal percentage;
        @AuraEnabled public String  grade;
        @AuraEnabled public String  gradeClass;
        @AuraEnabled public String  remarks;
        @AuraEnabled public String  scoreStyle;
        @AuraEnabled public Integer rank;
        @AuraEnabled public Integer totalStudents;
        @AuraEnabled public Decimal classAverage;
        @AuraEnabled public Decimal classAvgPct;
        @AuraEnabled public String  classAvgStyle;
        @AuraEnabled public Boolean isTopPerformer;
        @AuraEnabled public Boolean isAboveAverage;
        @AuraEnabled public Decimal weightedScore;
    }
}