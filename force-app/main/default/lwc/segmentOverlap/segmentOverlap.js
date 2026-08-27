import { LightningElement, track } from 'lwc';
import getSegmentOverlap from '@salesforce/apex/DataCloudController.getSegmentOverlap';

export default class SegmentOverlap extends LightningElement {
    @track pairs = [];
    @track isLoading = false;
    @track errorMessage = '';
    @track hasRun = false;

    handleRun() {
        this.isLoading = true;
        this.errorMessage = '';
        this.pairs = [];
        getSegmentOverlap()
            .then(result => {
                this.pairs = result.map((p, i) => ({
                    ...p,
                    key: i,
                    severityClass: this.severityClass(p.overlapPct),
                    barStyle: 'width:' + Math.max(4, Math.round(p.overlapPct)) + '%',
                    pctLabel: p.overlapPct + '%',
                    rankLabel: i + 1
                }));
                this.hasRun = true;
                this.isLoading = false;
            })
            .catch(err => {
                this.errorMessage = err.body ? err.body.message : err.message;
                this.isLoading = false;
                this.hasRun = true;
            });
    }

    severityClass(pct) {
        if (pct >= 60) return 'ol-bar ol-bar_high';
        if (pct >= 25) return 'ol-bar ol-bar_mid';
        return 'ol-bar ol-bar_low';
    }

    get hasResults() {
        return this.pairs.length > 0;
    }

    get noOverlap() {
        return this.hasRun && !this.isLoading && this.pairs.length === 0 && !this.errorMessage;
    }

    get resultLabel() {
        return this.pairs.length === 1
            ? '1 overlapping pair found'
            : this.pairs.length + ' overlapping pairs found';
    }
}
