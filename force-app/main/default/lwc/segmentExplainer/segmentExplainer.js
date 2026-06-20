import { LightningElement, api, track } from 'lwc';
import getSegments from '@salesforce/apex/DataCloudController.getSegments';
import getSegmentDetails from '@salesforce/apex/DataCloudController.getSegmentDetails';
import getActivationReadiness from '@salesforce/apex/DataCloudController.getActivationReadiness';
import getMissingContactProfiles from '@salesforce/apex/DataCloudController.getMissingContactProfiles';

export default class SegmentExplainer extends LightningElement {
    @api recordId;
    @track segmentOptions = [];
    @track allSegments = [];
    @track selectedSegment = '';
    @track selectedSegmentData = null;
    @track isLoading = false;
    @track isLoadingReadiness = false;
    @track errorMessage = '';
    @track activationReadiness = null;
    @track missingEmailProfiles = null;
    @track missingPhoneProfiles = null;
    @track isLoadingMissingEmail = false;
    @track isLoadingMissingPhone = false;
    @track showMissingEmail = false;
    @track showMissingPhone = false;
    missingEmailColumns = [
        { label: 'First Name', fieldName: 'firstName' },
        { label: 'Last Name', fieldName: 'lastName' },
        { label: 'Unified ID', fieldName: 'unifiedId' },
        { label: 'Email Address', fieldName: 'emailAddress' }
    ];

    missingPhoneColumns = [
        { label: 'First Name', fieldName: 'firstName' },
        { label: 'Last Name', fieldName: 'lastName' },
        { label: 'Unified ID', fieldName: 'unifiedId' },
        { label: 'Phone Number', fieldName: 'phoneNumber' }
    ];

    connectedCallback() {
        this.loadSegments();
    }

    loadSegments() {
        this.isLoading = true;
        getSegments()
            .then(result => {
                const parsed = JSON.parse(result);
                this.allSegments = parsed.segments;
                this.segmentOptions = parsed.segments.map(seg => ({
                    label: seg.displayName,
                    value: seg.apiName
                }));
            })
            .catch(error => {
                this.errorMessage = 'Failed to load segments: ' + JSON.stringify(error.body);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleSegmentChange(event) {
        this.selectedSegment = event.detail.value;
        this.activationReadiness = null;
        this.missingEmailProfiles = null;
        this.missingPhoneProfiles = null;
        this.showMissingEmail = false;
        this.showMissingPhone = false;
        this.errorMessage = '';
        this.loadSegmentDetails(this.selectedSegment);
    }

    // ── Segment Health Dashboard ──
    get totalSegmentCount() {
        return this.allSegments.length;
    }

    get zeroPopulationSegments() {
        return this.allSegments.filter(s => !s.lastSegmentMemberCount || s.lastSegmentMemberCount === 0);
    }

    get zeroPopulationCount() {
        return this.zeroPopulationSegments.length;
    }

    get hasZeroPopulation() {
        return this.zeroPopulationCount > 0;
    }

    get inactiveSegments() {
        return this.allSegments.filter(s => s.segmentStatus === 'INACTIVE');
    }

    get inactiveCount() {
        return this.inactiveSegments.length;
    }

    get hasInactive() {
        return this.inactiveCount > 0;
    }

    get manualRefreshSegments() {
        return this.allSegments.filter(s => s.publishInterval === 'NO_REFRESH');
    }

    get manualRefreshCount() {
        return this.manualRefreshSegments.length;
    }

    get hasManualRefresh() {
        return this.manualRefreshCount > 0;
    }

    get zeroPopulationNames() {
        return this.zeroPopulationSegments.map(s => s.displayName).join(', ');
    }

    get inactiveNames() {
        return this.inactiveSegments.map(s => s.displayName).join(', ');
    }

    get manualRefreshNames() {
        return this.manualRefreshSegments.map(s => s.displayName).join(', ');
    }

    // ── Filter Limit Checker ──
    get filterCount() {
        if (!this.selectedSegmentData || !this.selectedSegmentData.includeCriteria) return 0;
        try {
            const raw = this.selectedSegmentData.includeCriteria
                .replace(/&quot;/g, '"')
                .replace(/&#39;/g, "'");
            const criteria = JSON.parse(raw);
            return this.countFilters(criteria);
        } catch (e) {
            return 0;
        }
    }

    countFilters(node) {
        if (!node) return 0;
        if (node.type === 'TextComparison' || node.type === 'NumberComparison' || node.type === 'DateComparison') {
            return 1;
        }
        if (node.type === 'LogicalExpression') {
            return this.countFilters(node.left) + this.countFilters(node.right);
        }
        if (node.criteria) {
            return node.criteria.reduce((sum, c) => sum + this.countFilters(c), 0);
        }
        return 0;
    }

    get filterLimitWarning() {
        return this.filterCount >= 40;
    }

    get filterLimitCritical() {
        return this.filterCount >= 48;
    }

    get filterCountLabel() {
        return this.filterCount + ' / 50 filters used';
    }

    get hasNoLookback() {
        return this.selectedSegmentData &&
            (!this.selectedSegmentData.lookbackPeriod || this.selectedSegmentData.lookbackPeriod === 'P0D');
    }

    get builtOnLabel() {
        const raw = this.selectedSegmentData && this.selectedSegmentData.segmentOnApiName;
        if (!raw) return '';
        return raw.replace('ssot__', '').replace('__dlm', '');
    }

    // ── DMO Warning ──
    get showDmoWarning() {
        return this.selectedSegmentData &&
            this.selectedSegmentData.segmentOnApiName &&
            this.selectedSegmentData.segmentOnApiName.includes('Individual__dlm') &&
            !this.selectedSegmentData.segmentOnApiName.includes('Unified');
    }

    // ── Activation Readiness ──
    get emailCoveragePercent() {
        if (!this.activationReadiness || !this.activationReadiness.total) return 0;
        return Math.round((this.activationReadiness.email / this.activationReadiness.total) * 100);
    }

    get phoneCoveragePercent() {
        if (!this.activationReadiness || !this.activationReadiness.total) return 0;
        return Math.round((this.activationReadiness.phone / this.activationReadiness.total) * 100);
    }

    get emailDropCount() {
        if (!this.activationReadiness) return 0;
        return this.activationReadiness.total - this.activationReadiness.email;
    }

    get phoneDropCount() {
        if (!this.activationReadiness) return 0;
        return this.activationReadiness.total - this.activationReadiness.phone;
    }

    get emailDropWarning() {
        return this.emailDropCount > 0;
    }

    get phoneDropWarning() {
        return this.phoneDropCount > 0;
    }

    get hasMembershipTable() {
        return this.selectedSegmentData &&
            this.selectedSegmentData.segmentMembershipDmo &&
            this.selectedSegmentData.segmentMembershipDmo.latestTable;
    }

    get noMembershipTable() {
        return !this.hasMembershipTable;
    }

    // ── Missing Profiles ──
    get missingEmailButtonLabel() {
        return this.showMissingEmail ? 'Hide Profiles' : 'View Profiles';
    }

    get missingPhoneButtonLabel() {
        return this.showMissingPhone ? 'Hide Profiles' : 'View Profiles';
    }

    get missingEmailSql() {
        if (!this.hasMembershipTable) return '';
        const table = this.selectedSegmentData.segmentMembershipDmo.latestTable;
        return `SELECT ui.ssot__FirstName__c, ui.ssot__LastName__c, ui.ssot__Id__c, cpe.ssot__EmailAddress__c\nFROM ${table} mem\nJOIN UnifiedIndividual__dlm ui ON mem.Id__c = ui.ssot__Id__c\nLEFT JOIN IndividualIdentityLink__dlm lnk ON mem.Id__c = lnk.UnifiedRecordId__c\nLEFT JOIN ssot__ContactPointEmail__dlm cpe ON lnk.SourceRecordId__c = cpe.ssot__PartyId__c\nWHERE cpe.ssot__Id__c IS NULL`;
    }

    get missingPhoneSql() {
        if (!this.hasMembershipTable) return '';
        const table = this.selectedSegmentData.segmentMembershipDmo.latestTable;
        return `SELECT ui.ssot__FirstName__c, ui.ssot__LastName__c, ui.ssot__Id__c, cpp.ssot__TelephoneNumber__c\nFROM ${table} mem\nJOIN UnifiedIndividual__dlm ui ON mem.Id__c = ui.ssot__Id__c\nLEFT JOIN IndividualIdentityLink__dlm lnk ON mem.Id__c = lnk.UnifiedRecordId__c\nLEFT JOIN ssot__ContactPointPhone__dlm cpp ON lnk.SourceRecordId__c = cpp.ssot__PartyId__c\nWHERE cpp.ssot__Id__c IS NULL`;
    }

    // ── Last Refresh Health ──
    get lastModifiedFormatted() {
        if (!this.selectedSegmentData || !this.selectedSegmentData.lastModifiedDate) return 'Unknown';
        const date = new Date(this.selectedSegmentData.lastModifiedDate);
        return date.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
    }

    get daysSinceRefresh() {
        if (!this.selectedSegmentData || !this.selectedSegmentData.lastModifiedDate) return null;
        const modified = new Date(this.selectedSegmentData.lastModifiedDate);
        const now = new Date();
        return Math.floor((now - modified) / (1000 * 60 * 60 * 24));
    }

    get isStale() {
        return this.daysSinceRefresh !== null && this.daysSinceRefresh > 7;
    }

    get refreshStatusLabel() {
        if (this.daysSinceRefresh === null) return '';
        if (this.daysSinceRefresh === 0) return 'Updated today';
        if (this.daysSinceRefresh === 1) return 'Updated yesterday';
        return 'Updated ' + this.daysSinceRefresh + ' days ago';
    }

    get publishIntervalFormatted() {
        const interval = this.selectedSegmentData && this.selectedSegmentData.publishInterval;
        if (!interval) return 'Unknown';
        if (interval === 'NO_REFRESH') return 'Manual only';
        if (interval === 'DAILY') return 'Daily';
        if (interval === 'HOURLY') return 'Hourly';
        if (interval === 'WEEKLY') return 'Weekly';
        return interval;
    }

    // ── Criteria Readability ──
    get parsedCriteria() {
        if (!this.selectedSegmentData || !this.selectedSegmentData.includeCriteria) return null;
        try {
            const raw = this.selectedSegmentData.includeCriteria
                .replace(/&quot;/g, '"')
                .replace(/&#39;/g, "'");
            const criteria = JSON.parse(raw);
            return this.formatCriteria(criteria);
        } catch (e) {
            return null;
        }
    }

    formatCriteria(node) {
        if (!node) return '';
        if (node.type === 'TextComparison' || node.type === 'NumberComparison' || node.type === 'DateComparison') {
            const field = node.subject ? node.subject.fieldApiName : '';
            const op = this.formatOperator(node.operator);
            const values = node.values ? node.values.join(', ') : '';
            return field + ' ' + op + ' ' + values;
        }
        if (node.type === 'LogicalExpression') {
            const left = this.formatCriteria(node.left);
            const right = this.formatCriteria(node.right);
            return left + ' ' + node.operator + ' ' + right;
        }
        if (node.criteria) {
            return node.criteria.map(c => this.formatCriteria(c)).join(' AND ');
        }
        return JSON.stringify(node);
    }

    formatOperator(op) {
        const map = {
            'equal': '=',
            'notEqual': '≠',
            'greaterThan': '>',
            'lessThan': '<',
            'greaterThanOrEqual': '≥',
            'lessThanOrEqual': '≤',
            'contains': 'contains',
            'startsWith': 'starts with',
            'endsWith': 'ends with',
            'isNull': 'is blank',
            'isNotNull': 'is not blank'
        };
        return map[op] || op;
    }

    // ── Data Loading ──
    loadSegmentDetails(segmentApiName) {
        this.isLoading = true;
        this.selectedSegmentData = null;
        getSegmentDetails({ segmentApiName })
            .then(result => {
                const parsed = JSON.parse(result);
                this.selectedSegmentData = parsed.segments[0];
                if (this.hasMembershipTable) {
                    this.loadActivationReadiness(this.selectedSegmentData.segmentMembershipDmo.latestTable);
                }
            })
            .catch(error => {
                this.errorMessage = 'Failed to load segment details: ' + JSON.stringify(error.body);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    loadActivationReadiness(membershipTable) {
        this.isLoadingReadiness = true;
        const segmentOnApiName = this.selectedSegmentData ? this.selectedSegmentData.segmentOnApiName : '';
        getActivationReadiness({ membershipTable, segmentOnApiName })
            .then(result => {
                this.activationReadiness = result;
            })
            .catch(error => {
                this.errorMessage = 'Failed to load activation readiness: ' + JSON.stringify(error.body);
            })
            .finally(() => {
                this.isLoadingReadiness = false;
            });
    }

    handleViewMissingEmail() {
        this.showMissingEmail = !this.showMissingEmail;
        if (this.showMissingEmail && !this.missingEmailProfiles) {
            this.isLoadingMissingEmail = true;
            getMissingContactProfiles({
                membershipTable: this.selectedSegmentData.segmentMembershipDmo.latestTable,
                contactType: 'email'
            })
            .then(result => { this.missingEmailProfiles = result; })
            .catch(error => { this.errorMessage = 'Failed to load missing email profiles: ' + JSON.stringify(error.body); })
            .finally(() => { this.isLoadingMissingEmail = false; });
        }
    }

    handleViewMissingPhone() {
        this.showMissingPhone = !this.showMissingPhone;
        if (this.showMissingPhone && !this.missingPhoneProfiles) {
            this.isLoadingMissingPhone = true;
            getMissingContactProfiles({
                membershipTable: this.selectedSegmentData.segmentMembershipDmo.latestTable,
                contactType: 'phone'
            })
            .then(result => { this.missingPhoneProfiles = result; })
            .catch(error => { this.errorMessage = 'Failed to load missing phone profiles: ' + JSON.stringify(error.body); })
            .finally(() => { this.isLoadingMissingPhone = false; });
        }
    }
}
