// File: TestAttendanceBatch.cls

@isTest
public class TestAttendanceBatch {

    @testSetup
    static void setupData() {
        Map<String, Id> ids = TestDataFactory.createFullSetup();

        Section_Student_Junction__c junction =
            TestDataFactory.createJunction(
                ids.get('sectionId'), ids.get('studentId'), true);

        // Create 4 completed sessions
        for (Integer i = 0; i < 4; i++) {
            Classroom_Session__c session =
                TestDataFactory.createSession(
                    ids.get('sectionId'), 'Completed', true);

            // 3 present, 1 absent = 75% attendance
            String status = i < 3 ? 'Present' : 'Absent';
            TestDataFactory.createAttendance(
                session.Id, junction.Id, status, true);
        }
    }

    // Test 1: Batch calculates correct attendance percentage
    @isTest
    static void testAttendancePercentageCalculation() {
        Test.startTest();
            AttendancePercentageBatch batch =
                new AttendancePercentageBatch();
            Database.executeBatch(batch, 200);
        Test.stopTest();

        Section_Student_Junction__c junction =
            [SELECT Attendance_Percentage__c
             FROM Section_Student_Junction__c LIMIT 1];

        // 3 present out of 4 = 75%
        System.assertEquals(75.00,
            junction.Attendance_Percentage__c,
            'Attendance should be 75% (3 present out of 4 sessions)');
    }

    // Test 2: Scheduler class executes without error
    @isTest
    static void testScheduler() {
        Test.startTest();
            String cronExp = '0 0 8 * * ?';
            System.schedule(
                'Test Attendance Scheduler',
                cronExp,
                new AttendancePercentageScheduler()
            );
        Test.stopTest();

        // If no exception thrown the scheduler works correctly
        System.assert(true, 'Scheduler should execute without errors');
    }

    // Test 3: Batch handles empty data gracefully
    @isTest
    static void testBatchWithNoAttendance() {
        // Delete all attendance records
        delete [SELECT Id FROM Attendance__c];

        Test.startTest();
            Database.executeBatch(new AttendancePercentageBatch(), 200);
        Test.stopTest();

        Section_Student_Junction__c junction =
            [SELECT Attendance_Percentage__c
             FROM Section_Student_Junction__c LIMIT 1];

        System.assertEquals(0, junction.Attendance_Percentage__c,
            'Attendance should be 0 when no records exist');
    }
}