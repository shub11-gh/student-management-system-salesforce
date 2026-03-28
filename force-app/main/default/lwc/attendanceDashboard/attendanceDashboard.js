// File: attendanceDashboard.js
import { LightningElement, api, wire, track } from 'lwc';
import getAttendanceData from '@salesforce/apex/AttendanceDashboardController.getAttendanceData';

export default class AttendanceDashboard extends LightningElement {

    @api recordId;
    @track courseData = [];
    @track isLoading = true;
    @track hasError = false;
    @track errorMessage = '';

    // Summary stats
    @track totalCourses = 0;
    @track totalSessionsAll = 0;
    @track overallPercentage = '0.00';
    @track belowThresholdCount = 0;

    @wire(getAttendanceData, { studentId: '$recordId' })
    wiredData({ data, error }) {
        this.isLoading = false;

        if (data) {
            // Add barStyle to each course for the progress bar
            this.courseData = data.map(course => ({
                ...course,
                barStyle: `width: ${course.attendancePercentage}%; background: ${course.attendancePercentage >= 75 ? '#0066ff' : '#ff4444'
                    }`
            }));

            // Calculate summary stats
            this.totalCourses = data.length;
            this.belowThresholdCount = data.filter(c => c.isBelowThreshold).length;

            let totalPresent = 0;
            let totalSessions = 0;
            data.forEach(c => {
                totalSessions += c.totalSessions;
                totalPresent += c.presentCount;
            });

            this.totalSessionsAll = totalSessions;
            this.overallPercentage = totalSessions > 0
                ? ((totalPresent / totalSessions) * 100).toFixed(2)
                : '0.00';

            this.hasError = false;

        } else if (error) {
            this.hasError = true;
            this.errorMessage = 'Error loading attendance: ' + error.body.message;
            this.courseData = [];
        }
    }

    // Computed properties
    get hasData() { return this.courseData.length > 0; }
    get isEmpty() { return !this.isLoading && !this.hasError && this.courseData.length === 0; }
}