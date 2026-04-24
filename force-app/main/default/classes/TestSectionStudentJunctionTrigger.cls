// File: TestSectionStudentJunctionTrigger.cls

@isTest
public class TestSectionStudentJunctionTrigger {

    @testSetup
    static void setupData() {
        // Creates shared test data for all test methods in this class
        Map<String, Id> ids = TestDataFactory.createFullSetup();
    }

    // Test 1: Valid enrollment should succeed
    @isTest
    static void testValidEnrollment() {
        Course_Section_Enrollment__c section =
            [SELECT Id FROM Course_Section_Enrollment__c LIMIT 1];
        Student__c student =
            [SELECT Id FROM Student__c LIMIT 1];

        Test.startTest();
            Section_Student_Junction__c junction =
                TestDataFactory.createJunction(
                    section.Id, student.Id, false);
            insert junction;
        Test.stopTest();

        // Verify the junction was created successfully
        List<Section_Student_Junction__c> result = [
            SELECT Id FROM Section_Student_Junction__c
            WHERE Student__c = :student.Id
        ];
        System.assertEquals(1, result.size(),
            'One junction record should have been created');
    }

    // Test 2: Duplicate enrollment should fail
    @isTest
    static void testDuplicateEnrollment() {
        Course_Section_Enrollment__c section =
            [SELECT Id FROM Course_Section_Enrollment__c LIMIT 1];
        Student__c student =
            [SELECT Id FROM Student__c LIMIT 1];

        // Insert first enrollment
        TestDataFactory.createJunction(section.Id, student.Id, true);

        Test.startTest();
            // Try to insert duplicate
            Section_Student_Junction__c duplicate =
                TestDataFactory.createJunction(
                    section.Id, student.Id, false);
            Database.SaveResult result =
                Database.insert(duplicate, false);
        Test.stopTest();

        // Verify the duplicate was blocked
        System.assertEquals(false, result.isSuccess(),
            'Duplicate enrollment should have been blocked');
        System.assert(
            result.getErrors()[0].getMessage().contains(
                'already enrolled'),
            'Error message should mention already enrolled');
    }

    // Test 3: Enrollment beyond capacity should fail
    @isTest
    static void testCapacityExceeded() {
        Course_Section_Enrollment__c section =
            [SELECT Id FROM Course_Section_Enrollment__c LIMIT 1];

        // Set capacity to 1
        section.Maximum_Capacity__c = 1;
        update section;

        // Create and fill the section with 1 student
        Student__c student1 = TestDataFactory.createStudent('Student One', true);
        TestDataFactory.createJunction(section.Id, student1.Id, true);

        // Try to add a second student beyond capacity
        Student__c student2 = TestDataFactory.createStudent('Student Two', true);

        Test.startTest();
            Section_Student_Junction__c overflow =
                TestDataFactory.createJunction(
                    section.Id, student2.Id, false);
            Database.SaveResult result =
                Database.insert(overflow, false);
        Test.stopTest();

        System.assertEquals(false, result.isSuccess(),
            'Enrollment beyond capacity should have been blocked');
        System.assert(
            result.getErrors()[0].getMessage().contains('full'),
            'Error message should mention section is full');
    }
}