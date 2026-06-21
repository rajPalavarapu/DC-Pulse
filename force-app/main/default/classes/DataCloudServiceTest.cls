@isTest
private class DataCloudServiceTest {

    private static void setupToken() {
        DataCloudService.testToken = 'testtoken123';
    }

    @isTest
    static void testGetSegments() {
        setupToken();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        String result = DataCloudService.getSegments();
        Test.stopTest();
        System.assertNotEquals(null, result);
        System.assert(result.contains('TestSeg'));
    }

    @isTest
    static void testGetSegmentDetails() {
        setupToken();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        String result = DataCloudService.getSegmentDetails('TestSeg');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetActivationReadiness() {
        setupToken();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        Map<String, Integer> result = DataCloudService.getActivationReadiness('TestMembershipTable__dlm', 'UnifiedIndividual__dlm');
        Test.stopTest();
        System.assertNotEquals(null, result);
        System.assert(result.containsKey('total'));
        System.assert(result.containsKey('email'));
        System.assert(result.containsKey('phone'));
    }

    @isTest
    static void testGetActivationReadinessEmptyData() {
        setupToken();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout('emptyData'));
        Test.startTest();
        Map<String, Integer> result = DataCloudService.getActivationReadiness('TestMembershipTable__dlm', 'UnifiedIndividual__dlm');
        Test.stopTest();
        System.assertEquals(0, result.get('total'));
    }

    @isTest
    static void testGetIrSummary() {
        setupToken();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        Map<String, Object> result = DataCloudService.getIrSummary();
        Test.stopTest();
        System.assertNotEquals(null, result);
        System.assert(result.containsKey('totalUnified'));
        System.assert(result.containsKey('totalLinks'));
        System.assert(result.containsKey('avgLinksPerProfile'));
    }

    @isTest
    static void testGetIrSummaryZeroUnified() {
        setupToken();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout('emptyData'));
        Test.startTest();
        Map<String, Object> result = DataCloudService.getIrSummary();
        Test.stopTest();
        System.assertEquals(0, result.get('totalUnified'));
    }

    @isTest
    static void testGetSuspiciousMerges() {
        setupToken();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        List<Map<String, Object>> result = DataCloudService.getSuspiciousMerges(5);
        Test.stopTest();
        System.assertNotEquals(null, result);
        System.assertEquals(1, result.size());
        System.assertEquals('uid1', result[0].get('unifiedId'));
    }

    @isTest
    static void testGetSuspiciousMergesEmpty() {
        setupToken();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout('emptyData'));
        Test.startTest();
        List<Map<String, Object>> result = DataCloudService.getSuspiciousMerges(5);
        Test.stopTest();
        System.assertEquals(0, result.size());
    }

    @isTest
    static void testSearchUnifiedProfiles() {
        setupToken();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        List<Map<String, String>> result = DataCloudService.searchUnifiedProfiles('John');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetProfileMergeDetail() {
        setupToken();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        List<Map<String, String>> result = DataCloudService.getProfileMergeDetail('uid1');
        Test.stopTest();
        System.assertNotEquals(null, result);
        System.assertEquals(1, result.size());
        System.assertEquals('srcId1', result[0].get('sourceRecordId'));
        System.assertEquals('dsId1', result[0].get('dataSourceId'));
        System.assertEquals('dsoId1', result[0].get('dataSourceObjectId'));
    }

    @isTest
    static void testGetMissingContactProfilesEmail() {
        setupToken();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        List<Map<String, String>> result = DataCloudService.getMissingContactProfiles('TestTable__dlm', 'email');
        Test.stopTest();
        System.assertNotEquals(null, result);
        System.assertEquals(1, result.size());
        System.assertEquals('John', result[0].get('firstName'));
    }

    @isTest
    static void testGetMissingContactProfilesPhone() {
        setupToken();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        List<Map<String, String>> result = DataCloudService.getMissingContactProfiles('TestTable__dlm', 'phone');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testQueryDataCloud() {
        setupToken();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        String result = DataCloudService.queryDataCloud('SELECT COUNT() FROM UnifiedIndividual__dlm');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testQueryDataCloudError() {
        setupToken();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout('apiError'));
        Test.startTest();
        try {
            DataCloudService.queryDataCloud('SELECT COUNT() FROM UnifiedIndividual__dlm');
            System.assert(false, 'Expected exception not thrown');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('Failed to query'));
        }
        Test.stopTest();
    }

    @isTest
    static void testGetSegmentsApiError() {
        setupToken();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout('apiError'));
        Test.startTest();
        try {
            DataCloudService.getSegments();
            System.assert(false, 'Expected exception not thrown');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('Failed to get segments'));
        }
        Test.stopTest();
    }

    @isTest
    static void testGetSegmentDetailsApiError() {
        setupToken();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout('apiError'));
        Test.startTest();
        try {
            DataCloudService.getSegmentDetails('TestSeg');
            System.assert(false, 'Expected exception not thrown');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('Failed to get segment details'));
        }
        Test.stopTest();
    }
}
