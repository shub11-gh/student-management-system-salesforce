// File: TestDataFactory.cls

@isTest
public class TestDataFactory {

    // Creates and inserts a Student record
    public static Student__c createStudent(String name, Boolean doInsert) {
        Student__c student      = new Student__c();
        student.Name            = name;
        student.Student_Email__c = name.replaceAll(' ', '.').toLowerCase()
                                    + '@testuniversity.com';
        student.Phone_No__c     = '9876543210';
        student.Date_of_Birth__c = Date.newInstance(2000, 1, 15);
        student.Program__c      = 'BCA';
        student.Enrollment_Date__c = Date.today();
        student.Address__c   = '123 Test Street, Test City';
        student.Gender__c   = 'Male';
        if (doInsert) insert student;
        return student;
    }

    // Creates and inserts a Teacher record
    public static Teacher__c createTeacher(String name, Boolean doInsert) {
    Teacher__c teacher       = new Teacher__c();
    teacher.Name             = name;
    teacher.Teacher_Email__c = name.replaceAll(' ', '.').toLowerCase() + '@testuniversity.com';
    teacher.Phone_No__c      = '9876543211';
    teacher.Department__c = 'CSE';
    teacher.Qualification__c    = 'M.Tech';
    teacher.Date_of_Joining__c  = Date.today();
    if (doInsert) insert teacher;
    return teacher;
}

    // Creates and inserts a Course record
    public static Course__c createCourse(String name, Boolean doInsert) {
        Course__c course    = new Course__c();
        course.Name         = name;
        course.Course_ID__c = 'CS' + Integer.valueOf(Math.random() * 1000);
        if (doInsert) insert course;
        return course;
    }

    // Creates and inserts a Course Offering record
    public static Course_Offering__c createOffering(
            Id courseId, Id teacherId, Boolean doInsert) {
        Course_Offering__c offering         = new Course_Offering__c();
        offering.Courses__c                 = courseId;
        offering.Course_Coordinator__c      = teacherId;
        offering.Academic_Year__c           = '2024-2025';
        offering.Semester__c                = 'Semester 1';
        if (doInsert) insert offering;
        return offering;
    }

    // Creates and inserts a Course Section Enrollment record
    public static Course_Section_Enrollment__c createSection(
            Id offeringId, Boolean doInsert) {
        Course_Section_Enrollment__c section = new Course_Section_Enrollment__c();
        section.Name                          = 'Section A';
        section.Courses_Offering__c           = offeringId;
        section.Section_Code__c               = 'A';
        section.Maximum_Capacity__c           = 30;
        if (doInsert) insert section;
        return section;
    }

    // Creates and inserts a Section Student Junction record
    public static Section_Student_Junction__c createJunction(
            Id sectionId, Id studentId, Boolean doInsert) {
        Section_Student_Junction__c junction    = new Section_Student_Junction__c();
        junction.Course_Section_Enrollment__c   = sectionId;
        junction.Student__c                     = studentId;
        if (doInsert) insert junction;
        return junction;
    }

    // Creates and inserts an Assessment record
    public static Assessment__c createAssessment(
            Id sectionId, Boolean doInsert) {
        Assessment__c assessment            = new Assessment__c();
        assessment.Name                     = 'Test Assessment';
        assessment.Assessment_Type__c       = 'IA-1';
        assessment.Maximum_Marks__c         = 100;
        assessment.Weightage__c             = 40;
        assessment.Assessment_Date__c       = Date.today().addDays(7);
        assessment.Course_Enrollment__c     = sectionId;
        if (doInsert) insert assessment;
        return assessment;
    }

    // Creates and inserts an Assessment Score record
    public static Assessment_Score__c createScore(
            Id assessmentId, Id junctionId,
            Decimal marks, Boolean doInsert) {
        Assessment_Score__c score               = new Assessment_Score__c();
        score.Assessment__c                     = assessmentId;
        score.Section_Student_Junction__c       = junctionId;
        score.Marks_Obtained__c                 = marks;
        if (doInsert) insert score;
        return score;
    }

    // Creates and inserts a Classroom Session record
    public static Classroom_Session__c createSession(
            Id sectionId, String status, Boolean doInsert) {
        Classroom_Session__c session        = new Classroom_Session__c();
        session.Classroom_Number__c = 'LH' + String.valueOf(Math.abs(Crypto.getRandomInteger())).left(3);
        session.Session_Date__c             = Date.today();
        session.Session_Status__c           = status;
        session.Topics_Covered__c           = 'Test Topic';
        session.Courses_Enrollment__c       = sectionId;
        if (doInsert) insert session;
        return session;
    }

    // Creates and inserts an Attendance record
    public static Attendance__c createAttendance(
            Id sessionId, Id junctionId,
            String status, Boolean doInsert) {
        Attendance__c attendance                    = new Attendance__c();
        attendance.Classroom_Session__c             = sessionId;
        attendance.Section_Student_Junction__c      = junctionId;
        attendance.Status__c                        = status;
        if (doInsert) insert attendance;
        return attendance;
    }

    // Creates a full data set — course, teacher, section, student, junction
    public static Map<String, Id> createFullSetup() {
        Teacher__c teacher      = createTeacher('Test Teacher', true);
        Course__c course        = createCourse('Test Course', true);
        Course_Offering__c off  = createOffering(course.Id, teacher.Id, true);
        Course_Section_Enrollment__c sec = createSection(off.Id, true);
        Student__c student      = createStudent('Test Student', true);

        return new Map<String, Id>{
            'teacherId'   => teacher.Id,
            'courseId'    => course.Id,
            'offeringId'  => off.Id,
            'sectionId'   => sec.Id,
            'studentId'   => student.Id
        };
    }
}