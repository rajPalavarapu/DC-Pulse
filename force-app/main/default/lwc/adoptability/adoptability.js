import { LightningElement, track } from 'lwc';
import getSegments from '@salesforce/apex/DataCloudController.getSegments';
import getActivations from '@salesforce/apex/DataCloudController.getActivations';
import getCalculatedInsights from '@salesforce/apex/DataCloudController.getCalculatedInsights';
import getActivationPlatforms from '@salesforce/apex/DataCloudController.getActivationPlatforms';
import getDmoCoverage from '@salesforce/apex/DataCloudController.getDmoCoverage';
import getOrgContactPointCoverage from '@salesforce/apex/DataCloudController.getOrgContactPointCoverage';
import getIrSummary from '@salesforce/apex/DataCloudController.getIrSummary';
import getDataTransforms from '@salesforce/apex/DataCloudController.getDataTransforms';
import getDataStreams from '@salesforce/apex/DataCloudController.getDataStreams';

export default class Adoptability extends LightningElement {
    @track isLoading = false;
    @track errorMessage = '';
    @track hasLoaded = false;

    // raw data
    @track segments = [];
    @track activations = [];
    @track calculatedInsights = [];
    @track platforms = [];
    @track dmoCoverage = {};
    @track contactPointCoverage = {};
    @track irSummary = {};
    @track dataTransforms = [];
    @track dataStreams = [];

    connectedCallback() {
        this.loadAll();
    }

    loadAll() {
        this.isLoading = true;
        this.errorMessage = '';
        const errors = [];

        const safe = (promise, fallback) =>
            promise.catch(e => {
                const msg = e.body?.message || e.message || JSON.stringify(e);
                if (!msg.includes('NOT_FOUND') && !msg.includes('Not Found') && !msg.includes('does not exist')) {
                    errors.push(msg);
                }
                return fallback;
            });

        Promise.all([
            safe(getSegments(), '{"segments":[]}'),
            safe(getActivations(), '{"activations":[]}'),
            safe(getCalculatedInsights(), '{"calculatedInsights":[]}'),
            safe(getActivationPlatforms(), '{"activationExternalPlatforms":[]}'),
            safe(getDmoCoverage(), {}),
            safe(getOrgContactPointCoverage(), { total: 0, withEmail: 0, withPhone: 0 }),
            safe(getIrSummary(), { totalUnified: 0, totalLinks: 0, avgLinksPerProfile: 0 }),
            safe(getDataTransforms(), '{"dataTransforms":[]}'),
            safe(getDataStreams(), '{"dataStreams":[]}')
        ])
        .then(([segRes, actRes, ciRes, platRes, dmoRes, cpRes, irRes, dtRes, dsRes]) => {
            const parseList = (res, ...keys) => {
                try {
                    const parsed = typeof res === 'string' ? JSON.parse(res) : res;
                    for (const k of keys) { if (parsed[k]) return parsed[k]; }
                } catch(e) { /* ignore */ }
                return [];
            };
            this.segments = parseList(segRes, 'segments');
            this.activations = parseList(actRes, 'activations', 'records');
            this.calculatedInsights = parseList(ciRes, 'calculatedInsights', 'records');
            this.platforms = parseList(platRes, 'activationExternalPlatforms', 'records');
            this.dmoCoverage = dmoRes || {};
            this.contactPointCoverage = cpRes || {};
            this.irSummary = irRes || {};
            this.dataTransforms = parseList(dtRes, 'dataTransforms', 'records');
            this.dataStreams = parseList(dsRes, 'dataStreams', 'records');
            if (errors.length > 0) {
                this.errorMessage = 'Some data failed to load: ' + errors.join('; ');
            }
            this.hasLoaded = true;
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    handleRefresh() {
        this.hasLoaded = false;
        this.loadAll();
    }

    // ── Segment Adoption ──
    get totalSegments() { return this.segments.length; }
    get activeSegments() { return this.segments.filter(s => s.segmentStatus === 'ACTIVE').length; }
    get zeroPopSegments() { return this.segments.filter(s => !s.lastSegmentMemberCount || s.lastSegmentMemberCount === 0); }
    get zeroPopCount() { return this.zeroPopSegments.length; }

    get activatedSegmentApiNames() {
        return new Set(this.activations.map(a => a.segmentApiName || a.segment || ''));
    }

    get neverActivatedSegments() {
        const activated = this.activatedSegmentApiNames;
        return this.segments.filter(s => !activated.has(s.apiName));
    }

    get neverActivatedCount() { return this.neverActivatedSegments.length; }
    get deadEndCount() { return this.neverActivatedCount + this.zeroPopCount; }
    get segmentAdoptionStatus() {
        if (this.deadEndCount === 0) return 'healthy';
        if (this.deadEndCount <= 3) return 'warning';
        return 'error';
    }
    get segmentAdoptionIcon() {
        if (this.segmentAdoptionStatus === 'healthy') return 'utility:check';
        if (this.segmentAdoptionStatus === 'warning') return 'utility:warning';
        return 'utility:error';
    }
    get segmentAdoptionVariant() {
        if (this.segmentAdoptionStatus === 'healthy') return 'success';
        if (this.segmentAdoptionStatus === 'warning') return 'warning';
        return 'error';
    }

    // ── Activation Reach ──
    get totalActivations() { return this.activations.length; }
    get activationReachPercent() {
        if (!this.totalSegments) return 0;
        return Math.round(((this.totalSegments - this.neverActivatedCount) / this.totalSegments) * 100);
    }
    get activationReachStatus() {
        if (this.activationReachPercent >= 80) return 'healthy';
        if (this.activationReachPercent >= 40) return 'warning';
        return 'error';
    }
    get activationReachIcon() {
        if (this.activationReachStatus === 'healthy') return 'utility:check';
        if (this.activationReachStatus === 'warning') return 'utility:warning';
        return 'utility:error';
    }
    get activationReachVariant() {
        if (this.activationReachStatus === 'healthy') return 'success';
        if (this.activationReachStatus === 'warning') return 'warning';
        return 'error';
    }

    // ── Platform Coverage ──
    get totalPlatforms() { return this.platforms.length; }
    get platformNames() { return this.platforms.map(p => p.name || p.label || p.platformType || 'Unknown'); }
    get platformCoverageStatus() {
        if (this.totalPlatforms >= 3) return 'healthy';
        if (this.totalPlatforms >= 1) return 'warning';
        return 'error';
    }
    get platformCoverageIcon() {
        if (this.platformCoverageStatus === 'healthy') return 'utility:check';
        if (this.platformCoverageStatus === 'warning') return 'utility:warning';
        return 'utility:error';
    }
    get platformCoverageVariant() {
        if (this.platformCoverageStatus === 'healthy') return 'success';
        if (this.platformCoverageStatus === 'warning') return 'warning';
        return 'error';
    }

    // ── DMO Coverage ──
    get dmoRows() {
        const labels = {
            'ssot__Individual__dlm': 'Individual',
            'UnifiedIndividual__dlm': 'Unified Individual',
            'IndividualIdentityLink__dlm': 'Identity Link',
            'ssot__ContactPointEmail__dlm': 'Contact Point Email',
            'ssot__ContactPointPhone__dlm': 'Contact Point Phone',
            'ssot__EngagementInteraction__dlm': 'Engagement Interaction'
        };
        return Object.keys(labels).map(key => ({
            key,
            label: labels[key],
            count: this.dmoCoverage[key] || 0,
            populated: (this.dmoCoverage[key] || 0) > 0,
            icon: (this.dmoCoverage[key] || 0) > 0 ? 'utility:check' : 'utility:close',
            variant: (this.dmoCoverage[key] || 0) > 0 ? 'success' : 'error'
        }));
    }
    get populatedDmoCount() { return this.dmoRows.filter(d => d.populated).length; }
    get totalDmoCount() { return this.dmoRows.length; }
    get dmoCoverageStatus() {
        const ratio = this.populatedDmoCount / this.totalDmoCount;
        if (ratio >= 0.8) return 'healthy';
        if (ratio >= 0.5) return 'warning';
        return 'error';
    }
    get dmoCoverageIcon() {
        if (this.dmoCoverageStatus === 'healthy') return 'utility:check';
        if (this.dmoCoverageStatus === 'warning') return 'utility:warning';
        return 'utility:error';
    }
    get dmoCoverageVariant() {
        if (this.dmoCoverageStatus === 'healthy') return 'success';
        if (this.dmoCoverageStatus === 'warning') return 'warning';
        return 'error';
    }

    // ── Contact Point Activatability ──
    get cpTotal() { return this.contactPointCoverage.total || 0; }
    get cpEmailPercent() {
        if (!this.cpTotal) return 0;
        return Math.round((this.contactPointCoverage.withEmail / this.cpTotal) * 100);
    }
    get cpPhonePercent() {
        if (!this.cpTotal) return 0;
        return Math.round((this.contactPointCoverage.withPhone / this.cpTotal) * 100);
    }
    get cpStatus() {
        const minCoverage = Math.min(this.cpEmailPercent, this.cpPhonePercent);
        if (minCoverage >= 60) return 'healthy';
        if (minCoverage >= 30) return 'warning';
        return 'error';
    }
    get cpIcon() {
        if (this.cpStatus === 'healthy') return 'utility:check';
        if (this.cpStatus === 'warning') return 'utility:warning';
        return 'utility:error';
    }
    get cpVariant() {
        if (this.cpStatus === 'healthy') return 'success';
        if (this.cpStatus === 'warning') return 'warning';
        return 'error';
    }

    // ── Segment Freshness ──
    get staleSegments() {
        return this.segments.filter(s => {
            if (!s.lastModifiedDate) return true;
            const days = Math.floor((Date.now() - new Date(s.lastModifiedDate)) / 86400000);
            return days > 90;
        });
    }
    get warningSegments() {
        return this.segments.filter(s => {
            if (!s.lastModifiedDate) return false;
            const days = Math.floor((Date.now() - new Date(s.lastModifiedDate)) / 86400000);
            return days > 30 && days <= 90;
        });
    }
    get freshSegments() {
        return this.segments.filter(s => {
            if (!s.lastModifiedDate) return false;
            const days = Math.floor((Date.now() - new Date(s.lastModifiedDate)) / 86400000);
            return days <= 30;
        });
    }
    get freshnessStatus() {
        if (this.staleSegments.length === 0) return 'healthy';
        if (this.staleSegments.length <= 3) return 'warning';
        return 'error';
    }
    get freshnessIcon() {
        if (this.freshnessStatus === 'healthy') return 'utility:check';
        if (this.freshnessStatus === 'warning') return 'utility:warning';
        return 'utility:error';
    }
    get freshnessVariant() {
        if (this.freshnessStatus === 'healthy') return 'success';
        if (this.freshnessStatus === 'warning') return 'warning';
        return 'error';
    }

    // ── Calculated Insights ──
    get totalCIs() { return this.calculatedInsights.length; }
    get ciUsedInSegments() {
        const ciNames = new Set(this.calculatedInsights.map(ci => ci.apiName));
        return this.segments.filter(s => {
            if (!s.parameters) return false;
            return JSON.stringify(s.parameters).split('').some(() => {
                return [...ciNames].some(name => JSON.stringify(s.parameters).includes(name));
            });
        }).length;
    }
    get unusedCIs() { return this.totalCIs - this.ciUsedInSegments; }
    get ciStatus() {
        if (this.totalCIs === 0) return 'error';
        if (this.unusedCIs > 0) return 'warning';
        return 'healthy';
    }
    get ciIcon() {
        if (this.ciStatus === 'healthy') return 'utility:check';
        if (this.ciStatus === 'warning') return 'utility:warning';
        return 'utility:error';
    }
    get ciVariant() {
        if (this.ciStatus === 'healthy') return 'success';
        if (this.ciStatus === 'warning') return 'warning';
        return 'error';
    }

    // ── IR Adoption ──
    get irMergeRatio() { return this.irSummary.avgLinksPerProfile || 0; }
    get irTotalUnified() { return this.irSummary.totalUnified || 0; }
    get irStatus() {
        if (this.irMergeRatio === 0) return 'error';
        if (this.irMergeRatio < 1.5) return 'warning';
        return 'healthy';
    }
    get irIcon() {
        if (this.irStatus === 'healthy') return 'utility:check';
        if (this.irStatus === 'warning') return 'utility:warning';
        return 'utility:error';
    }
    get irVariant() {
        if (this.irStatus === 'healthy') return 'success';
        if (this.irStatus === 'warning') return 'warning';
        return 'error';
    }

    // ── Maturity Score ──
    get maturityScore() {
        const scores = {
            segment:   this.segmentAdoptionStatus === 'healthy' ? 12 : this.segmentAdoptionStatus === 'warning' ? 6 : 0,
            activation:this.activationReachStatus === 'healthy' ? 12 : this.activationReachStatus === 'warning' ? 6 : 0,
            platform:  this.platformCoverageStatus === 'healthy' ? 10 : this.platformCoverageStatus === 'warning' ? 5 : 0,
            dmo:       this.dmoCoverageStatus === 'healthy' ? 10 : this.dmoCoverageStatus === 'warning' ? 5 : 0,
            cp:        this.cpStatus === 'healthy' ? 12 : this.cpStatus === 'warning' ? 6 : 0,
            freshness: this.freshnessStatus === 'healthy' ? 8 : this.freshnessStatus === 'warning' ? 4 : 0,
            ci:        this.ciStatus === 'healthy' ? 8 : this.ciStatus === 'warning' ? 4 : 0,
            ir:        this.irStatus === 'healthy' ? 8 : this.irStatus === 'warning' ? 4 : 0,
            transform: this.transformStatus === 'healthy' ? 10 : this.transformStatus === 'warning' ? 5 : 0,
            stream:    this.streamStatus === 'healthy' ? 10 : this.streamStatus === 'warning' ? 5 : 0
        };
        return Object.values(scores).reduce((a, b) => a + b, 0);
    }

    get maturityLabel() {
        const irHasRun = this.irMergeRatio > 0;
        const hasActivations = this.totalActivations > 0;
        const hasGoodCoverage = this.cpEmailPercent >= 60;
        if (irHasRun && hasActivations && hasGoodCoverage) return 'Optimization Phase';
        if (irHasRun && hasActivations) return 'Activation Phase';
        if (irHasRun) return 'Unification Phase';
        return 'Ingestion Phase';
    }

    get maturityBarStyle() {
        let color = '#c23934';
        if (this.maturityScore >= 80) color = '#2e844a';
        else if (this.maturityScore >= 55) color = '#0176d3';
        else if (this.maturityScore >= 30) color = '#fe9339';
        return 'width: ' + this.maturityScore + '%; height: 12px; border-radius: 4px; background-color: ' + color + '; transition: width 0.3s;';
    }

    get emailBarStyle() {
        return 'width: ' + this.cpEmailPercent + '%; height: 8px; border-radius: 4px; background-color: #0176d3;';
    }

    get phoneBarStyle() {
        return 'width: ' + this.cpPhonePercent + '%; height: 8px; border-radius: 4px; background-color: #0176d3;';
    }

    get noPlatforms() { return this.totalPlatforms === 0; }
    get noCIs() { return this.totalCIs === 0; }
    get hasUnusedCIs() { return !this.noCIs && this.unusedCIs > 0; }
    get irNotConfigured() { return this.irMergeRatio === 0; }
    get irLowMerge() { return this.irMergeRatio > 0 && this.irMergeRatio < 1.5; }

    // ── Data Transform Health ──
    get totalTransforms() { return this.dataTransforms.length; }

    get transformsWithJobStatus() {
        return this.dataTransforms.map(t => {
            const lastStatus = t.status || t.lastRunStatus || 'NEVER_RUN';
            const lastRun = t.lastRunDate || t.lastModifiedDate || null;
            const daysSinceRun = lastRun ? Math.floor((Date.now() - new Date(lastRun)) / 86400000) : null;
            const rowsProcessed = t.recordsProcessed || 0;
            const isHealthy = lastStatus === 'Succeeded' || lastStatus === 'SUCCESS' || lastStatus === 'Completed';
            const isFailed = lastStatus === 'Failed' || lastStatus === 'ERROR' || lastStatus === 'Aborted';
            const isNeverRun = lastStatus === 'NEVER_RUN';
            const isStale = daysSinceRun !== null && daysSinceRun > 7;
            return {
                id: t.id || t.apiName,
                name: t.label || t.name || t.apiName,
                lastStatus,
                lastRun,
                daysSinceRun,
                rowsProcessed,
                isHealthy,
                isFailed,
                isNeverRun,
                isStale,
                statusLabel: isNeverRun ? 'Never Run' : lastStatus,
                statusIcon: isHealthy && !isStale ? 'utility:check' : 'utility:error',
                statusVariant: isHealthy && !isStale ? 'success' : 'error'
            };
        });
    }

    get failedTransforms() { return this.transformsWithJobStatus.filter(t => t.isFailed); }
    get neverRunTransforms() { return this.transformsWithJobStatus.filter(t => t.isNeverRun); }
    get staleTransforms() { return this.transformsWithJobStatus.filter(t => !t.isNeverRun && !t.isFailed && t.isStale); }
    get healthyTransforms() { return this.transformsWithJobStatus.filter(t => t.isHealthy && !t.isStale); }

    get transformStatus() {
        if (this.failedTransforms.length > 0) return 'error';
        if (this.neverRunTransforms.length > 0 || this.staleTransforms.length > 0) return 'warning';
        if (this.totalTransforms === 0) return 'error';
        return 'healthy';
    }
    get transformIcon() {
        if (this.transformStatus === 'healthy') return 'utility:check';
        if (this.transformStatus === 'warning') return 'utility:warning';
        return 'utility:error';
    }
    get transformVariant() {
        if (this.transformStatus === 'healthy') return 'success';
        if (this.transformStatus === 'warning') return 'warning';
        return 'error';
    }
    get noTransforms() { return this.totalTransforms === 0; }

    // ── Data Stream Freshness ──
    get totalStreams() { return this.dataStreams.length; }

    get streamsWithStatus() {
        return this.dataStreams.map(s => {
            const lastRun = s.lastRefreshDate || s.lastRunDate || s.lastModifiedDate || null;
            const daysSinceRun = lastRun ? Math.floor((Date.now() - new Date(lastRun)) / 86400000) : null;
            const connectorType = s.connectorType || s.dataSourceType || s.type || 'Unknown';
            const isRealtime = connectorType.toLowerCase().includes('stream') || connectorType.toLowerCase().includes('realtime');
            const staleThreshold = isRealtime ? 1 : 7;
            const isStale = daysSinceRun !== null && daysSinceRun > staleThreshold;
            const isNeverRun = daysSinceRun === null;
            return {
                id: s.id || s.apiName,
                name: s.label || s.name || s.apiName,
                connectorType,
                daysSinceRun,
                isStale,
                isNeverRun,
                statusLabel: isNeverRun ? 'Never Run' : (isStale ? daysSinceRun + ' days ago' : 'Fresh'),
                statusVariant: isNeverRun || isStale ? 'error' : 'success',
                statusIcon: isNeverRun || isStale ? 'utility:error' : 'utility:check'
            };
        });
    }

    get staleStreams() { return this.streamsWithStatus.filter(s => s.isStale || s.isNeverRun); }
    get freshStreams() { return this.streamsWithStatus.filter(s => !s.isStale && !s.isNeverRun); }

    get streamStatus() {
        if (this.totalStreams === 0) return 'error';
        if (this.staleStreams.length > 0) return 'warning';
        return 'healthy';
    }
    get streamIcon() {
        if (this.streamStatus === 'healthy') return 'utility:check';
        if (this.streamStatus === 'warning') return 'utility:warning';
        return 'utility:error';
    }
    get streamVariant() {
        if (this.streamStatus === 'healthy') return 'success';
        if (this.streamStatus === 'warning') return 'warning';
        return 'error';
    }
    get noStreams() { return this.totalStreams === 0; }

    // ── Recommendations ──
    get recommendations() {
        const recs = [];
        if (this.neverActivatedCount > 0) {
            recs.push({
                id: 'r1',
                icon: 'utility:warning',
                variant: 'warning',
                text: this.neverActivatedCount + ' segment(s) have never been activated — review and either activate or archive to stop unnecessary credit consumption.'
            });
        }
        if (this.zeroPopCount > 0) {
            recs.push({
                id: 'r2',
                icon: 'utility:warning',
                variant: 'warning',
                text: this.zeroPopCount + ' segment(s) have zero population — check filter criteria or data availability.'
            });
        }
        if (this.totalPlatforms < 2) {
            recs.push({
                id: 'r3',
                icon: 'utility:warning',
                variant: 'warning',
                text: 'Only ' + this.totalPlatforms + ' activation platform(s) configured — consider connecting additional channels to expand audience reach.'
            });
        }
        if (this.cpEmailPercent < 50) {
            recs.push({
                id: 'r4',
                icon: 'utility:warning',
                variant: 'warning',
                text: 'Email contact point coverage is ' + this.cpEmailPercent + '% — a large portion of unified profiles will be dropped on email activation.'
            });
        }
        if (this.cpPhonePercent < 30) {
            recs.push({
                id: 'r5',
                icon: 'utility:warning',
                variant: 'warning',
                text: 'Phone contact point coverage is ' + this.cpPhonePercent + '% — SMS and push activation channels will have significantly reduced reach.'
            });
        }
        if (this.staleSegments.length > 0) {
            recs.push({
                id: 'r6',
                icon: 'utility:clock',
                variant: 'warning',
                text: this.staleSegments.length + ' segment(s) have not been modified in over 90 days — review whether these are still relevant.'
            });
        }
        if (this.totalCIs === 0) {
            recs.push({
                id: 'r7',
                icon: 'utility:error',
                variant: 'error',
                text: 'No Calculated Insights deployed — pre-calculating behavioral flags (LTV, Churn Risk) improves segment performance and reduces credit consumption.'
            });
        } else if (this.unusedCIs > 0) {
            recs.push({
                id: 'r8',
                icon: 'utility:warning',
                variant: 'warning',
                text: this.unusedCIs + ' Calculated Insight(s) are deployed but not referenced in any segment — use them as segment filters to improve reusability.'
            });
        }
        if (this.irMergeRatio < 1.5) {
            recs.push({
                id: 'r9',
                icon: this.irMergeRatio === 0 ? 'utility:error' : 'utility:warning',
                variant: this.irMergeRatio === 0 ? 'error' : 'warning',
                text: this.irMergeRatio === 0
                    ? 'Identity Resolution has not run — no unified profiles found. Verify IR is configured and data streams are active.'
                    : 'Low merge ratio (' + this.irMergeRatio + 'x) — IR may have restrictive match rules or limited overlapping data across sources.'
            });
        }
        if (this.failedTransforms.length > 0) {
            recs.push({
                id: 'r10',
                icon: 'utility:error',
                variant: 'error',
                text: this.failedTransforms.length + ' data transform(s) failed on last run — ' + this.failedTransforms.map(t => t.name).join(', ') + '. Downstream DMOs may have stale or missing data.'
            });
        }
        if (this.neverRunTransforms.length > 0) {
            recs.push({
                id: 'r11',
                icon: 'utility:warning',
                variant: 'warning',
                text: this.neverRunTransforms.length + ' data transform(s) have never run — ' + this.neverRunTransforms.map(t => t.name).join(', ') + '. These transforms are configured but not producing any output.'
            });
        }
        if (this.staleTransforms.length > 0) {
            recs.push({
                id: 'r12',
                icon: 'utility:warning',
                variant: 'warning',
                text: this.staleTransforms.length + ' data transform(s) have not run in over 7 days — check if the schedule is still active.'
            });
        }
        if (this.staleStreams.length > 0) {
            recs.push({
                id: 'r13',
                icon: 'utility:warning',
                variant: 'warning',
                text: this.staleStreams.length + ' data stream(s) have not ingested recently — ' + this.staleStreams.map(s => s.name).join(', ') + '. Source data may be out of date.'
            });
        }
        if (this.noStreams) {
            recs.push({
                id: 'r14',
                icon: 'utility:error',
                variant: 'error',
                text: 'No data streams found — Data Cloud has no active ingestion pipelines configured.'
            });
        }
        if (recs.length === 0) {
            recs.push({
                id: 'r0',
                icon: 'utility:check',
                variant: 'success',
                text: 'No critical issues found. Data Cloud adoption looks healthy across all measured dimensions.'
            });
        }
        return recs;
    }

    get hasRecommendations() { return this.recommendations.length > 0; }
}
