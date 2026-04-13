// courseOfferingDetail.js
import { LightningElement, api, wire, track } from 'lwc';
import getOfferingDetails
    from '@salesforce/apex/CourseOfferingDetailController.getOfferingDetails';

export default class CourseOfferingDetail extends LightningElement {

    @api recordId;
    @track offeringData = null;
    @track isLoading = true;
    @track hasError = false;
    @track errorMessage = '';

    @wire(getOfferingDetails, { offeringId: '$recordId' })
    wiredOffering({ data, error }) {
        this.isLoading = false;
        if (data) {
            this.offeringData = data;
            this.hasError = false;
        } else if (error) {
            this.hasError = true;
            this.errorMessage = 'Error loading offering: ' + error.body.message;
        }
    }

    get hasData() {
        return !this.isLoading && !this.hasError && this.offeringData !== null;
    }
}