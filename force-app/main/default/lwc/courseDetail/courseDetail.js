// courseDetail.js
import { LightningElement, api, wire, track } from 'lwc';
import getCourseDetails from '@salesforce/apex/CourseDetailController.getCourseDetails';

export default class CourseDetail extends LightningElement {

    @api recordId;
    @track courseData = null;
    @track isLoading = true;
    @track hasError = false;
    @track errorMessage = '';

    @wire(getCourseDetails, { courseId: '$recordId' })
    wiredCourse({ data, error }) {
        this.isLoading = false;
        if (data) {
            // Add .length to each offering's sections for the header pill
            this.courseData = {
                ...data,
                offerings: data.offerings.map(o => ({
                    ...o,
                    sections: o.sections.map(s => ({ ...s }))
                }))
            };
            this.hasError = false;
        } else if (error) {
            this.hasError = true;
            this.errorMessage = 'Error loading course: ' + error.body.message;
        }
    }

    get hasData() { return !this.isLoading && !this.hasError && this.courseData !== null; }
}