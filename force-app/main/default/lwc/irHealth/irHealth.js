import { LightningElement, track } from 'lwc';
import getIrSummary from '@salesforce/apex/DataCloudController.getIrSummary';
import getSuspiciousMerges from '@salesforce/apex/DataCloudController.getSuspiciousMerges';
import searchUnifiedProfiles from '@salesforce/apex/DataCloudController.searchUnifiedProfiles';
import getProfileMergeDetail from '@salesforce/apex/DataCloudController.getProfileMergeDetail';

export default class IrHealth extends LightningElement {
    @track irSummary = null;
    @track isLoadingSummary = false;

    @track suspiciousThresholdInput = 10;
    @track suspiciousMerges = null;
    @track isLoadingSuspicious = false;
    @track suspiciousExpanded = true;

    @track searchTerm = '';
    @track searchResults = null;
    @track isSearching = false;

    @track selectedProfile = null;
    @track mergeDetail = null;
    @track isLoadingDetail = false;

    @track errorMessage = '';

    suspiciousColumns = [
        { label: 'First Name', fieldName: 'firstName' },
        { label: 'Last Name', fieldName: 'lastName' },
        { label: 'Unified ID', fieldName: 'unifiedId' },
        { label: 'Source Records Merged', fieldName: 'mergeCount', type: 'number', cellAttributes: { alignment: 'left' } },
        { type: 'action', typeAttributes: { rowActions: [{ label: 'View Merges', name: 'view' }] } }
    ];

    searchResultColumns = [
        { label: 'First Name', fieldName: 'firstName' },
        { label: 'Last Name', fieldName: 'lastName' },
        { label: 'Unified ID', fieldName: 'unifiedId' },
        { type: 'action', typeAttributes: { rowActions: [{ label: 'View Merges', name: 'view' }] } }
    ];

    mergeDetailColumns = [
        { label: 'Source Record ID', fieldName: 'sourceRecordId' },
        { label: 'Data Source', fieldName: 'dataSourceId' },
        { label: 'Data Source Object', fieldName: 'dataSourceObjectId' }
    ];


    connectedCallback() {
        this.loadSummary();
    }

    loadSummary() {
        this.isLoadingSummary = true;
        getIrSummary()
            .then(result => {
                this.irSummary = result;
                this.loadSuspiciousMerges();
            })
            .catch(error => {
                this.errorMessage = 'Failed to load IR summary: ' + JSON.stringify(error.body);
            })
            .finally(() => {
                this.isLoadingSummary = false;
            });
    }

    handleThresholdChange(event) {
        const val = parseInt(event.target.value, 10);
        if (!isNaN(val) && val >= 2) {
            this.suspiciousThresholdInput = val;
        }
    }

    handleThresholdApply() {
        this.suspiciousMerges = null;
        this.suspiciousExpanded = true;
        this.loadSuspiciousMerges();
    }

    handleToggleSuspicious() {
        this.suspiciousExpanded = !this.suspiciousExpanded;
    }

loadSuspiciousMerges() {
        this.isLoadingSuspicious = true;
        getSuspiciousMerges({ threshold: this.suspiciousThresholdInput })
            .then(result => {
                this.suspiciousMerges = result;
            })
            .catch(error => {
                this.errorMessage = 'Failed to load suspicious merges: ' + JSON.stringify(error.body);
            })
            .finally(() => {
                this.isLoadingSuspicious = false;
            });
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
    }

    handleSearchKeyUp(event) {
        if (event.key === 'Enter' && this.searchTerm.trim().length >= 2) {
            this.runSearch();
        }
    }

    handleSearchClick() {
        if (this.searchTerm.trim().length >= 2) {
            this.runSearch();
        }
    }

    runSearch() {
        this.isSearching = true;
        this.searchResults = null;
        this.selectedProfile = null;
        this.mergeDetail = null;
        searchUnifiedProfiles({ searchTerm: this.searchTerm.trim() })
            .then(result => {
                this.searchResults = result;
            })
            .catch(error => {
                this.errorMessage = 'Search failed: ' + JSON.stringify(error.body);
            })
            .finally(() => {
                this.isSearching = false;
            });
    }

    drillIntoProfile(row) {
        this.selectedProfile = row;
        this.mergeDetail = null;
        this.isLoadingDetail = true;
        getProfileMergeDetail({ unifiedId: row.unifiedId })
            .then(result => {
                this.mergeDetail = result;
            })
            .catch(error => {
                this.errorMessage = 'Failed to load merge detail: ' + JSON.stringify(error.body);
            })
            .finally(() => {
                this.isLoadingDetail = false;
            });
    }

    handleProfileSelect(event) {
        if (event.detail.action.name === 'view') {
            this.drillIntoProfile(event.detail.row);
        }
    }

    handleSuspiciousSelect(event) {
        if (event.detail.action.name === 'view') {
            this.drillIntoProfile(event.detail.row);
        }
    }

    handleBackToSearch() {
        this.selectedProfile = null;
        this.mergeDetail = null;
    }

    get hasSuspiciousMerges() {
        return this.suspiciousMerges && this.suspiciousMerges.length > 0;
    }

    get noSuspiciousMerges() {
        return this.suspiciousMerges && this.suspiciousMerges.length === 0;
    }

    get suspiciousToggleLabel() {
        return this.suspiciousExpanded ? 'Collapse' : 'Expand';
    }

    get suspiciousToggleIcon() {
        return this.suspiciousExpanded ? 'utility:chevronup' : 'utility:chevrondown';
    }

    get hasSearchResults() {
        return this.searchResults && this.searchResults.length > 0;
    }

    get noSearchResults() {
        return this.searchResults && this.searchResults.length === 0;
    }

    get selectedProfileName() {
        if (!this.selectedProfile) return '';
        return (this.selectedProfile.firstName || '') + ' ' + (this.selectedProfile.lastName || '');
    }

    get mergeCount() {
        return this.mergeDetail ? this.mergeDetail.length : 0;
    }

    get suspiciousThreshold() {
        return this.suspiciousThresholdInput;
    }

    get isMergeCountHigh() {
        return this.mergeCount > this.suspiciousThresholdInput;
    }

    get mergeChartCapped() {
        return this.mergeDetail && this.mergeDetail.length > 12;
    }

    get mergeChartOverflowCount() {
        return this.mergeDetail ? this.mergeDetail.length - 12 : 0;
    }

    get mergeChart() {
        if (!this.mergeDetail || !this.selectedProfile) return null;
        const capped = this.mergeDetail.slice(0, 12);
        const total = capped.length;

        const nodeR    = 22;
        const centerR  = 44;
        const labelPad = 32; // gap between node edge and label start
        const labelW   = 200; // fixed width reserved for label text on each side

        let orbitRadius;
        if      (total <= 2) orbitRadius = 110;
        else if (total <= 4) orbitRadius = 140;
        else if (total <= 6) orbitRadius = 165;
        else if (total <= 8) orbitRadius = 185;
        else                  orbitRadius = 205;

        // Fixed pixel canvas — labels get labelW px on every side, no scaling
        const svgW = (orbitRadius + nodeR + labelPad + labelW) * 2;
        const svgH = (orbitRadius + nodeR + labelPad + 80) * 2;
        const cx   = Math.round(svgW / 2);
        const cy   = Math.round(svgH / 2);

        const trunc = (str, len) => {
            if (!str) return '—';
            return str.length > len ? str.slice(0, len) + '…' : str;
        };

        const nodes = capped.map((rec, i) => {
            const angle = (2 * Math.PI * i) / total - Math.PI / 2;
            const cosA  = Math.cos(angle);
            const sinA  = Math.sin(angle);

            // Center of the numbered circle
            const nx = Math.round(cx + orbitRadius * cosA);
            const ny = Math.round(cy + orbitRadius * sinA);

            // Label x: fixed distance past the node edge, in the radial direction
            const lDist = orbitRadius + nodeR + labelPad;
            const lx    = Math.round(cx + lDist * cosA);
            const ly    = Math.round(cy + lDist * sinA);

            // Text-anchor: left side of chart anchors to 'end', right to 'start', top/bottom 'middle'
            let anchor;
            if      (cosA >  0.3) anchor = 'start';
            else if (cosA < -0.3) anchor = 'end';
            else                   anchor = 'middle';

            // Vertical stacking of 3 label lines
            let ly1, ly2, ly3;
            if (Math.abs(cosA) <= 0.3) {
                // Top / bottom nodes — stack above or below
                if (sinA < 0) { ly1 = ly - 34; ly2 = ly - 18; ly3 = ly - 2; }
                else          { ly1 = ly + 6;  ly2 = ly + 22; ly3 = ly + 38; }
            } else {
                // Left / right nodes — vertically centred on ly
                ly1 = ly - 16;
                ly2 = ly;
                ly3 = ly + 16;
            }

            return {
                nx, ny, lx, ly1, ly2, ly3, anchor,
                index:    String(i + 1),
                dsLabel:  trunc(rec.dataSourceId, 26),
                dsoLabel: trunc(rec.dataSourceObjectId, 26),
                srcShort: rec.sourceRecordId ? '…' + rec.sourceRecordId.slice(-16) : '—',
                spokeKey: 'spoke-' + (rec.sourceRecordId || String(i)),
                nodeKey:  'node-'  + (rec.sourceRecordId || String(i))
            };
        });

        return {
            nodes, cx, cy, centerR,
            centerY1: cy - 11,
            centerY2: cy +  5,
            centerY3: cy + 19,
            // No max-width — fixed pixel size, container scrolls
            viewBox:  '0 0 ' + svgW + ' ' + svgH,
            svgStyle: 'width:' + svgW + 'px;height:' + svgH + 'px;display:block;margin:0 auto;'
        };
    }

    get hasMergeChart() {
        return this.mergeDetail && this.mergeDetail.length > 0;
    }
}
