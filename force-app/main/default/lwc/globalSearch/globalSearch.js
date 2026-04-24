// globalSearch.js
import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import search from '@salesforce/apex/GlobalSearchController.search';

// NavigationMixin gives this component the ability to
// navigate to any Salesforce record page
export default class GlobalSearch extends NavigationMixin(LightningElement) {

    @track searchTerm = '';
    @track searchResults = null;
    @track isLoading = false;
    @track showNoResults = false;

    // Debounce timer — waits 400ms after user stops typing before searching
    // prevents a new API call on every single keystroke
    debounceTimer;

    handleSearch(event) {
        const term = event.target.value;
        this.searchTerm = term;
        this.showNoResults = false;

        // Clear previous timer on each keystroke
        clearTimeout(this.debounceTimer);

        if (term.length < 2) {
            this.searchResults = null;
            return;
        }

        // Start new timer — only fires if user stops typing for 400ms
        this.debounceTimer = setTimeout(() => {
            this.runSearch(term);
        }, 400);
    }

    runSearch(term) {
        this.isLoading = true;
        search({ searchTerm: term })
            .then(data => {
                this.isLoading = false;

                // Add initials to each student and teacher for avatar
                this.searchResults = {
                    ...data,
                    students: data.students.map(s => ({
                        ...s,
                        initials: this.getInitials(s.name)
                    })),
                    teachers: data.teachers.map(t => ({
                        ...t,
                        initials: this.getInitials(t.name)
                    }))
                };

                this.showNoResults = !data.hasResults;
            })
            .catch(() => {
                this.isLoading = false;
                this.searchResults = null;
            });
    }

    // NavigationMixin — navigates to the clicked record page
    // This covers the "Navigation Patterns" curriculum topic
    navigateToRecord(event) {
        const recordId = event.currentTarget.dataset.id;
        const objectType = event.currentTarget.dataset.type;

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: objectType,
                actionName: 'view'
            }
        });
    }

    clearSearch() {
        this.searchTerm = '';
        this.searchResults = null;
        this.showNoResults = false;
    }

    getInitials(name) {
        if (!name) return '?';
        const parts = name.trim().split(' ');
        if (parts.length === 1) return parts[0].charAt(0).toUpperCase();
        return (parts[0].charAt(0) + parts[parts.length - 1].charAt(0))
            .toUpperCase();
    }

    // Computed properties
    get showResults() { return this.searchResults && this.searchResults.hasResults; }
    get showClear() { return this.searchTerm.length > 0 && !this.isLoading; }
    get hasStudents() { return this.searchResults && this.searchResults.students.length > 0; }
    get hasTeachers() { return this.searchResults && this.searchResults.teachers.length > 0; }
    get hasCourses() { return this.searchResults && this.searchResults.courses.length > 0; }
}