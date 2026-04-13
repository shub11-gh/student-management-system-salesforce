// sectionEnrollmentDetail.js
import { LightningElement, api, wire, track } from 'lwc';
import getSectionDetails
    from '@salesforce/apex/SectionEnrollmentDetailController.getSectionDetails';

export default class SectionEnrollmentDetail extends LightningElement {

    @api recordId;
    @track sectionData = null;
    @track isLoading = true;
    @track hasError = false;
    @track errorMessage = '';

    @wire(getSectionDetails, { sectionId: '$recordId' })
    wiredSection({ data, error }) {
        this.isLoading = false;
        if (data) {
            this.sectionData = data;
            this.hasError = false;
        } else if (error) {
            this.hasError = true;
            this.errorMessage = 'Error loading section: ' + error.body.message;
        }
    }

    get hasData() { return !this.isLoading && !this.hasError && this.sectionData !== null; }
    get hasAssessments() { return this.sectionData && this.sectionData.assessments.length > 0; }
    get hasSessions() { return this.sectionData && this.sectionData.sessions.length > 0; }
}