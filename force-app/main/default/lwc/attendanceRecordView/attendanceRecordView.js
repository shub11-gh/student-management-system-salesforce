// attendanceRecordView.js
import { LightningElement, api, wire, track } from 'lwc';
import getAttendanceDetails
    from '@salesforce/apex/AttendanceRecordViewController.getAttendanceDetails';

export default class AttendanceRecordView extends LightningElement {

    @api recordId;
    @track attendanceData = null;
    @track isLoading = true;
    @track hasError = false;
    @track errorMessage = '';

    @wire(getAttendanceDetails, { attendanceId: '$recordId' })
    wiredAttendance({ data, error }) {
        this.isLoading = false;
        if (data) {
            this.attendanceData = data;
            this.hasError = false;
        } else if (error) {
            this.hasError = true;
            this.errorMessage = 'Error loading attendance: ' + error.body.message;
        }
    }

    // Generate initials from student name for avatar
    get studentInitials() {
        if (!this.attendanceData || !this.attendanceData.studentName) return '?';
        const parts = this.attendanceData.studentName.trim().split(' ');
        if (parts.length === 1) return parts[0].charAt(0).toUpperCase();
        return (parts[0].charAt(0) + parts[parts.length - 1].charAt(0))
            .toUpperCase();
    }

    get hasData() {
        return !this.isLoading && !this.hasError && this.attendanceData !== null;
    }
}