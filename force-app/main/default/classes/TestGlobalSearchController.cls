// File: TestGlobalSearchController.cls

@isTest
public class TestGlobalSearchController {

    @testSetup
    static void setupData() {
        TestDataFactory.createStudent('Rahul Kumar', true);
        TestDataFactory.createStudent('Priya Sharma', true);
        TestDataFactory.createTeacher('Dr. Rajesh Singh', true);
        TestDataFactory.createCourse('Data Structures', true);
    }

    // Test 1: Search returns correct results
    @isTest
    static void testSearchReturnsResults() {
        Student__c student = [SELECT Id FROM Student__c
                              WHERE Name = 'Rahul Kumar' LIMIT 1];

        // Tell Salesforce which records SOSL should return in test context
        Test.setFixedSearchResults(new List<Id>{ student.Id });

        Test.startTest();
            GlobalSearchController.SearchResultWrapper result =
                GlobalSearchController.search('Rahul');
        Test.stopTest();

        System.assert(result.hasResults,
            'Search should return results for Rahul');
        System.assertEquals(1, result.students.size(),
            'Should find exactly 1 student named Rahul');
    }

    // Test 2: Search returns results across multiple objects
    @isTest
    static void testSearchAcrossObjects() {
        Student__c student  = [SELECT Id FROM Student__c LIMIT 1];
        Teacher__c teacher  = [SELECT Id FROM Teacher__c LIMIT 1];
        Course__c course    = [SELECT Id FROM Course__c LIMIT 1];

        // Set fixed results across all 3 object types
        Test.setFixedSearchResults(new List<Id>{
            student.Id,
            teacher.Id,
            course.Id
        });

        Test.startTest();
            GlobalSearchController.SearchResultWrapper result =
                GlobalSearchController.search('Data');
        Test.stopTest();

        System.assert(result.totalResults > 0,
            'Search should return at least one result');
    }

    // Test 3: Short search term returns empty results
    @isTest
    static void testShortSearchTermReturnsEmpty() {
        Test.startTest();
            GlobalSearchController.SearchResultWrapper result =
                GlobalSearchController.search('R');
        Test.stopTest();

        System.assertEquals(0, result.totalResults,
            'Single character search should return no results');
    }

    // Test 4: SOSL injection attempt is sanitized
    @isTest
    static void testSearchSanitization() {
        Test.startTest();
            GlobalSearchController.SearchResultWrapper result =
                GlobalSearchController.search('test\' OR name LIKE \'%');
        Test.stopTest();

        System.assert(result != null,
            'Sanitized search should complete without error');
    }
}