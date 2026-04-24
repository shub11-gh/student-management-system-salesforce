// appHomeDashboard.js
import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getDashboardData
    from '@salesforce/apex/AppHomeDashboardController.getDashboardData';

export default class AppHomeDashboard extends NavigationMixin(LightningElement) {

    @track dashData = null;
    @track isLoading = true;
    @track hasError = false;
    @track errorMessage = '';

    @wire(getDashboardData)
    wiredData({ data, error }) {
        this.isLoading = false;
        if (data) {
            // Add initials to top students for avatar
            this.dashData = {
                ...data,
                topStudents: data.topStudents.map(s => ({
                    ...s,
                    initials: this.getInitials(s.studentName)
                }))
            };
            this.hasError = false;
        } else if (error) {
            this.hasError = true;
            this.errorMessage = 'Error loading dashboard: '
                + error.body.message;
        }
    }

    get today() {
        return new Date().toLocaleDateString('en-IN', {
            weekday: 'long',
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
    }

    getInitials(name) {
        if (!name) return '?';
        const parts = name.trim().split(' ');
        if (parts.length === 1) return parts[0].charAt(0).toUpperCase();
        return (parts[0].charAt(0) + parts[parts.length - 1].charAt(0))
            .toUpperCase();
    }

    get hasData() { return !this.isLoading && !this.hasError && this.dashData !== null; }
    get hasEnrollments() { return this.dashData && this.dashData.recentEnrollments.length > 0; }
    get hasAlerts() { return this.dashData && this.dashData.lowAttendanceAlerts.length > 0; }
    get hasTopStudents() { return this.dashData && this.dashData.topStudents.length > 0; }
}