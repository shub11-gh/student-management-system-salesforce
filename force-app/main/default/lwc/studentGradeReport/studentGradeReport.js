// File: studentGradeReport.js
import { LightningElement, api, wire, track } from 'lwc';
import getStudentGrades from '@salesforce/apex/StudentGradeReportController.getStudentGrades';

export default class StudentGradeReport extends LightningElement {

    // recordId is automatically set by Salesforce when the component
    // is placed on a record page — it gives us the current Student's ID
    @api recordId;

    @track courseGrades = [];
    @track isLoading = true;
    @track hasError = false;
    @track errorMessage = '';
    @track cgpa = '—';

    // @wire automatically calls the Apex method when recordId is available
    // and re-calls it if recordId changes
    @wire(getStudentGrades, { studentId: '$recordId' })
    wiredGrades({ data, error }) {
        this.isLoading = false;

        if (data) {
            // Add a progressStyle property to each assessment
            // so the HTML can render a progress bar inline
            this.courseGrades = data.map(course => ({
                ...course,
                assessments: course.assessments.map(a => ({
                    ...a,
                    progressStyle: `width: ${a.percentage}%; background: ${this.getBarColor(a.percentage)}`,
                    hasRemarks: a.remarks !== '—'
                }))
            }));
            this.cgpa = this.calculateOverallCGPA(data);
            this.hasError = false;

        } else if (error) {
            this.hasError = true;
            this.errorMessage = 'Error loading grade report: ' + error.body.message;
            this.courseGrades = [];
        }
    }

    // Calculate overall CGPA across all courses
    calculateOverallCGPA(courses) {
        let totalWeighted = 0;
        let totalWeight = 0;

        courses.forEach(course => {
            course.assessments.forEach(a => {
                if (a.weightage && a.maximumMarks > 0) {
                    totalWeighted += (a.marksObtained / a.maximumMarks) * a.weightage;
                    totalWeight += a.weightage;
                }
            });
        });

        if (totalWeight === 0) return '—';
        return ((totalWeighted / totalWeight) * 10).toFixed(2);
    }

    // Color of the progress bar changes with score
    getBarColor(percentage) {
        if (percentage >= 80) return '#2e7d32'; // green
        if (percentage >= 60) return '#f57c00'; // orange
        if (percentage >= 40) return '#1565c0'; // blue
        return '#c62828';                        // red
    }

    // Computed properties for template conditions
    get hasData() { return this.courseGrades.length > 0; }
    get isEmpty() { return !this.isLoading && !this.hasError && this.courseGrades.length === 0; }
    get gradeClass() { return 'grade-badge'; }
}