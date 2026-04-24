// assessmentScoreView.js
import { LightningElement, api, wire, track } from 'lwc';
import getScoreDetails
    from '@salesforce/apex/AssessmentScoreViewController.getScoreDetails';

export default class AssessmentScoreView extends LightningElement {

    @api recordId;
    @track scoreData = null;
    @track isLoading = true;
    @track hasError = false;
    @track errorMessage = '';

    @wire(getScoreDetails, { scoreId: '$recordId' })
    wiredScore({ data, error }) {
        this.isLoading = false;
        if (data) {
            this.scoreData = data;
            this.hasError = false;
        } else if (error) {
            this.hasError = true;
            this.errorMessage = 'Error loading score: ' + error.body.message;
        }
    }

    get studentInitials() {
        if (!this.scoreData || !this.scoreData.studentName) return '?';
        const parts = this.scoreData.studentName.trim().split(' ');
        if (parts.length === 1) return parts[0].charAt(0).toUpperCase();
        return (parts[0].charAt(0) + parts[parts.length - 1].charAt(0))
            .toUpperCase();
    }

    get hasData() {
        return !this.isLoading && !this.hasError && this.scoreData !== null;
    }
}