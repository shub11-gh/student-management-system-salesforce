// File: GlobalSearchController.cls

public with sharing class GlobalSearchController {

    @AuraEnabled(cacheable=true)
    public static SearchResultWrapper search(String searchTerm) {

        // Sanitize input to prevent SOSL injection
        // Strip special SOSL characters that could alter the query
        String sanitized = String.escapeSingleQuotes(searchTerm.trim());
        sanitized = sanitized.replaceAll('[?&|!{}\\[\\]()^~*:\\\\"\'+-]', '');

        // Must be at least 2 characters to search
        if (sanitized.length() < 2) {
            return new SearchResultWrapper();
        }

        // Append wildcard for partial matching
        // e.g. searching "joh" finds "John"
        String searchKey = sanitized + '*';

        // SOSL searches across multiple objects in one query
        // RETURNING clause specifies which objects and fields to return
        List<List<sObject>> results = [
            FIND :searchKey
            IN ALL FIELDS
            RETURNING
                Student__c (
                    Id, Name, Student_ID__c,
                    Student_Email__c, Phone_No__c,
                    Program__c, CGPA__c
                    ORDER BY Name
                    LIMIT 10
                ),
                Teacher__c (
                    Id, Name, Teacher_ID__c,
                    Teacher_Email__c, Department__c,
                    Phone_No__c
                    ORDER BY Name
                    LIMIT 10
                ),
                Course__c (
                    Id, Name, Course_ID__c
                    ORDER BY Name
                    LIMIT 10
                )
        ];

        SearchResultWrapper wrapper  = new SearchResultWrapper();
        wrapper.students             = new List<StudentResult>();
        wrapper.teachers             = new List<TeacherResult>();
        wrapper.courses              = new List<CourseResult>();

        // Process Student results
        for (sObject s : results[0]) {
            Student__c st       = (Student__c) s;
            StudentResult sr    = new StudentResult();
            sr.recordId         = st.Id;
            sr.name             = st.Name;
            sr.studentId        = st.Student_ID__c;
            sr.email            = st.Student_Email__c != null
                                    ? st.Student_Email__c : '—';
            sr.phone            = st.Phone_No__c != null
                                    ? st.Phone_No__c : '—';
            sr.program          = st.Program__c != null
                                    ? st.Program__c : '—';
            sr.cgpa             = st.CGPA__c != null
                                    ? st.CGPA__c.setScale(2) : 0;
            wrapper.students.add(sr);
        }

        // Process Teacher results
        for (sObject s : results[1]) {
            Teacher__c t        = (Teacher__c) s;
            TeacherResult tr    = new TeacherResult();
            tr.recordId         = t.Id;
            tr.name             = t.Name;
            tr.teacherId        = t.Teacher_ID__c;
            tr.email            = t.Teacher_Email__c != null
                                    ? t.Teacher_Email__c : '—';
            tr.department       = t.Department__c != null
                                    ? t.Department__c : '—';
            tr.phone            = t.Phone_No__c != null
                                    ? t.Phone_No__c : '—';
            wrapper.teachers.add(tr);
        }

        // Process Course results
        for (sObject s : results[2]) {
            Course__c c         = (Course__c) s;
            CourseResult cr     = new CourseResult();
            cr.recordId         = c.Id;
            cr.name             = c.Name;
            cr.courseCode       = c.Course_ID__c != null
                                    ? c.Course_ID__c : '—';
            wrapper.courses.add(cr);
        }

        wrapper.totalResults = wrapper.students.size()
                             + wrapper.teachers.size()
                             + wrapper.courses.size();
        wrapper.hasResults   = wrapper.totalResults > 0;

        return wrapper;
    }

    // ── Wrapper Classes ───────────────────────────────────────────────────────
    public class SearchResultWrapper {
        @AuraEnabled public List<StudentResult> students;
        @AuraEnabled public List<TeacherResult> teachers;
        @AuraEnabled public List<CourseResult>  courses;
        @AuraEnabled public Integer             totalResults;
        @AuraEnabled public Boolean             hasResults;

        public SearchResultWrapper() {
            this.students     = new List<StudentResult>();
            this.teachers     = new List<TeacherResult>();
            this.courses      = new List<CourseResult>();
            this.totalResults = 0;
            this.hasResults   = false;
        }
    }

    public class StudentResult {
        @AuraEnabled public Id      recordId;
        @AuraEnabled public String  name;
        @AuraEnabled public String  studentId;
        @AuraEnabled public String  email;
        @AuraEnabled public String  phone;
        @AuraEnabled public String  program;
        @AuraEnabled public Decimal cgpa;
    }

    public class TeacherResult {
        @AuraEnabled public Id     recordId;
        @AuraEnabled public String name;
        @AuraEnabled public String teacherId;
        @AuraEnabled public String email;
        @AuraEnabled public String department;
        @AuraEnabled public String phone;
    }

    public class CourseResult {
        @AuraEnabled public Id     recordId;
        @AuraEnabled public String name;
        @AuraEnabled public String courseCode;
    }
}