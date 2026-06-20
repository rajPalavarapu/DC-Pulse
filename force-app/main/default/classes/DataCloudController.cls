public with sharing class DataCloudController {

    @AuraEnabled(cacheable=true)
    public static String getSegments() {
        return DataCloudService.getSegments();
    }

    @AuraEnabled(cacheable=true)
    public static String getSegmentDetails(String segmentApiName) {
        return DataCloudService.getSegmentDetails(segmentApiName);
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, Integer> getActivationReadiness(String membershipTable, String segmentOnApiName) {
        return DataCloudService.getActivationReadiness(membershipTable, segmentOnApiName);
    }

    @AuraEnabled(cacheable=false)
    public static List<Map<String, String>> getMissingContactProfiles(String membershipTable, String contactType) {
        return DataCloudService.getMissingContactProfiles(membershipTable, contactType);
    }

    @AuraEnabled(cacheable=false)
    public static String queryDataCloud(String sql) {
        return DataCloudService.queryDataCloud(sql);
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getIrSummary() {
        return DataCloudService.getIrSummary();
    }

    @AuraEnabled(cacheable=false)
    public static List<Map<String, Object>> getSuspiciousMerges(Integer threshold) {
        return DataCloudService.getSuspiciousMerges(threshold);
    }

    @AuraEnabled(cacheable=false)
    public static List<Map<String, String>> searchUnifiedProfiles(String searchTerm) {
        return DataCloudService.searchUnifiedProfiles(searchTerm);
    }

    @AuraEnabled(cacheable=false)
    public static List<Map<String, String>> getProfileMergeDetail(String unifiedId) {
        return DataCloudService.getProfileMergeDetail(unifiedId);
    }
}
