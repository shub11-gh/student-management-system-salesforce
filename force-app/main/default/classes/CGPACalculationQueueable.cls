// File: CGPACalculationQueueable.cls

public class CGPACalculationQueueable implements Queueable {

    // Unlike @future, Queueable CAN accept non-primitive types
    private Set<Id> junctionIds;

    public CGPACalculationQueueable(Set<Id> junctionIds) {
        this.junctionIds = junctionIds;
    }

    public void execute(QueueableContext context) {

        // Step 1: Get Student IDs from junction IDs
        List<Section_Student_Junction__c> junctions = [
            SELECT Id, Student__c
            FROM Section_Student_Junction__c
            WHERE Id IN :junctionIds
        ];

        Set<Id> studentIds = new Set<Id>();
        for (Section_Student_Junction__c j : junctions) {
            if (j.Student__c != null) studentIds.add(j.Student__c);
        }

        if (studentIds.isEmpty()) return;

        // Step 2: Get all scores for these students
        List<Assessment_Score__c> allScores = [
            SELECT Id,
                   Marks_Obtained__c,
                   Assessment__r.Maximum_Marks__c,
                   Assessment__r.Weightage__c,
                   Section_Student_Junction__r.Student__c
            FROM Assessment_Score__c
            WHERE Section_Student_Junction__r.Student__c IN :studentIds
              AND Marks_Obtained__c != null
              AND Assessment__r.Maximum_Marks__c != null
              AND Assessment__r.Weightage__c != null
        ];

        // Step 3: Group by student
        Map<Id, List<Assessment_Score__c>> scoresByStudent =
            new Map<Id, List<Assessment_Score__c>>();

        for (Assessment_Score__c score : allScores) {
            Id sId = score.Section_Student_Junction__r.Student__c;
            if (!scoresByStudent.containsKey(sId)) {
                scoresByStudent.put(sId, new List<Assessment_Score__c>());
            }
            scoresByStudent.get(sId).add(score);
        }

        // Step 4: Calculate CGPA per student
        List<Student__c> toUpdate = new List<Student__c>();
        for (Id studentId : studentIds) {
            Decimal totalWeighted = 0;
            Decimal totalWeight   = 0;

            if (scoresByStudent.containsKey(studentId)) {
                for (Assessment_Score__c score :
                        scoresByStudent.get(studentId)) {
                    Decimal weightedScore =
                        (score.Marks_Obtained__c /
                         score.Assessment__r.Maximum_Marks__c)
                        * score.Assessment__r.Weightage__c;
                    totalWeighted += weightedScore;
                    totalWeight   += score.Assessment__r.Weightage__c;
                }
            }

            Decimal cgpa = 0;
            if (totalWeight > 0) {
                cgpa = (totalWeighted / totalWeight * 10).setScale(2);
            }

            toUpdate.add(new Student__c(
                Id      = studentId,
                CGPA__c = cgpa
            ));
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }

        // Log the Job ID for monitoring
        System.debug('CGPACalculationQueueable completed. Job ID: '
            + context.getJobId());
    }
}