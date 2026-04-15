// classroomSessionDetail.js
import { LightningElement, api, wire, track } from 'lwc';
import getSessionDetails
    from '@salesforce/apex/ClassroomSessionDetailController.getSessionDetails';

export default class ClassroomSessionDetail extends LightningElement {

    @api recordId;
    @track sessionData = null;
    @track isLoading = true;
    @track hasError = false;
    @track errorMessage = '';

    @wire(getSessionDetails, { sessionId: '$recordId' })
    wiredSession({ data, error }) {
        this.isLoading = false;
        if (data) {
            this.sessionData = data;
            this.hasError = false;
        } else if (error) {
            this.hasError = true;
            this.errorMessage = 'Error loading session: ' + error.body.message;
        }
    }

    get hasData() { return !this.isLoading && !this.hasError && this.sessionData !== null; }
    get hasAttendance() { return this.sessionData && this.sessionData.attendance.length > 0; }
}