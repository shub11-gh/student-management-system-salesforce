// File: TestCGPACalculation.cls

@isTest
public class TestCGPACalculation {

    @testSetup
    static void setupData() {
        Map<String, Id> ids = TestDataFactory.createFullSetup();

        // Create junction
        Section_Student_Junction__c junction =
            TestDataFactory.createJunction(
                ids.get('sectionId'), ids.get('studentId'), true);

        // Create assessment
        TestDataFactory.createAssessment(ids.get('sectionId'), true);
    }

    // Test 1: CGPA updates when score is inserted
    @isTest
    static void testCGPACalculatedOnInsert() {
        Section_Student_Junction__c junction =
            [SELECT Id FROM Section_Student_Junction__c LIMIT 1];
        Assessment__c assessment =
            [SELECT Id FROM Assessment__c LIMIT 1];
        Student__c student =
            [SELECT Id FROM Student__c LIMIT 1];

        Test.startTest();
            // Insert score of 80 out of 100 with weightage 40
            // Expected weighted: (80/100) * 40 = 32
            // CGPA = (32/40) * 10 = 8.00
            TestDataFactory.createScore(
                assessment.Id, junction.Id, 80, true);
        Test.stopTest();

        Student__c updated = [SELECT CGPA__c FROM Student__c
                              WHERE Id = :student.Id];
        System.assertEquals(8.00, updated.CGPA__c,
            'CGPA should be 8.00 for 80/100 marks');
    }

    // Test 2: CGPA updates when score is updated
    @isTest
    static void testCGPAUpdatedOnScoreChange() {
        Section_Student_Junction__c junction =
            [SELECT Id FROM Section_Student_Junction__c LIMIT 1];
        Assessment__c assessment =
            [SELECT Id FROM Assessment__c LIMIT 1];
        Student__c student =
            [SELECT Id FROM Student__c LIMIT 1];

        Assessment_Score__c score =
            TestDataFactory.createScore(
                assessment.Id, junction.Id, 80, true);

        Test.startTest();
            score.Marks_Obtained__c = 50;
            update score;
        Test.stopTest();

        Student__c updated = [SELECT CGPA__c FROM Student__c
                              WHERE Id = :student.Id];
        System.assertEquals(5.00, updated.CGPA__c,
            'CGPA should be 5.00 after updating marks to 50');
    }

    // Test 3: CGPA resets when score is deleted
    @isTest
    static void testCGPAResetOnScoreDelete() {
        Section_Student_Junction__c junction =
            [SELECT Id FROM Section_Student_Junction__c LIMIT 1];
        Assessment__c assessment =
            [SELECT Id FROM Assessment__c LIMIT 1];
        Student__c student =
            [SELECT Id FROM Student__c LIMIT 1];

        Assessment_Score__c score =
            TestDataFactory.createScore(
                assessment.Id, junction.Id, 80, true);

        Test.startTest();
            delete score;
        Test.stopTest();

        Student__c updated = [SELECT CGPA__c FROM Student__c
                              WHERE Id = :student.Id];
        System.assertEquals(0, updated.CGPA__c,
            'CGPA should be 0 after deleting the only score');
    }
}