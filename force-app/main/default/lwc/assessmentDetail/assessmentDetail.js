// assessmentDetail.js
import { LightningElement, api, wire, track } from 'lwc';
import getAssessmentDetails
    from '@salesforce/apex/AssessmentDetailController.getAssessmentDetails';

export default class AssessmentDetail extends LightningElement {

    @api recordId;
    @track assessmentData = null;
    @track isLoading = true;
    @track hasError = false;
    @track errorMessage = '';

    @wire(getAssessmentDetails, { assessmentId: '$recordId' })
    wiredAssessment({ data, error }) {
        this.isLoading = false;
        if (data) {
            this.assessmentData = data;
            this.hasError = false;
        } else if (error) {
            this.hasError = true;
            this.errorMessage = 'Error loading assessment: ' + error.body.message;
        }
    }

    get hasData() { return !this.isLoading && !this.hasError && this.assessmentData !== null; }
    get hasScores() { return this.assessmentData && this.assessmentData.scores.length > 0; }
}