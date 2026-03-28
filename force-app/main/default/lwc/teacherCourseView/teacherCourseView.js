// teacherCourseView.js
import { LightningElement, api, wire, track } from 'lwc';
import getTeacherCourses from '@salesforce/apex/TeacherCourseViewController.getTeacherCourses';

export default class TeacherCourseView extends LightningElement {

    @api recordId;
    @track courseData = [];
    @track isLoading = true;
    @track hasError = false;
    @track errorMessage = '';
    @track totalCourses = 0;
    @track totalStudents = 0;
    @track totalSessions = 0;
    @track totalBelowThreshold = 0;

    @wire(getTeacherCourses, { teacherId: '$recordId' })
    wiredCourses({ data, error }) {
        this.isLoading = false;

        if (data) {
            // Add computed properties to each course
            this.courseData = data.map(course => ({
                ...course,
                hasSessions: course.recentSessions.length > 0,
                students: course.students.map(s => ({
                    ...s,
                    progressStyle: `width: ${s.attendancePct}%; background: ${s.attendancePct >= 75 ? '#D4500A' : '#B91C1C'
                        }`
                }))
            }));

            // Summary stats
            this.totalCourses = data.length;
            this.totalStudents = data.reduce((sum, c) => sum + c.enrolledCount, 0);
            this.totalSessions = data.reduce((sum, c) => sum + c.recentSessions.length, 0);
            this.totalBelowThreshold = data.reduce((sum, c) => sum + c.belowThreshold, 0);

            this.hasError = false;

        } else if (error) {
            this.hasError = true;
            this.errorMessage = 'Error loading courses: ' + error.body.message;
            this.courseData = [];
        }
    }

    get hasData() { return this.courseData.length > 0; }
    get isEmpty() { return !this.isLoading && !this.hasError && this.courseData.length === 0; }
}