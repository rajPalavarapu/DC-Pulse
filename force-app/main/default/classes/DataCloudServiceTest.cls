@isTest
private class DataCloudServiceTest {

    private static void setupConfig() {
        DC_Lens_Config__c config = new DC_Lens_Config__c();
        config.Consumer_Key__c = 'testkey';
        config.Consumer_Secret__c = 'testsecret';
        upsert config;
    }

    @isTest
    static void testGetSegments() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        String result = DataCloudService.getSegments();
        Test.stopTest();
        System.assertNotEquals(null, result);
        System.assert(result.contains('TestSeg'));
    }

    @isTest
    static void testGetSegmentDetails() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        String result = DataCloudService.getSegmentDetails('TestSeg');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetActivationReadiness() {
        setupConfig();
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
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout('emptyData'));
        Test.startTest();
        Map<String, Integer> result = DataCloudService.getActivationReadiness('TestMembershipTable__dlm', 'UnifiedIndividual__dlm');
        Test.stopTest();
        System.assertEquals(0, result.get('total'));
    }

    @isTest
    static void testGetIrSummary() {
        setupConfig();
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
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout('emptyData'));
        Test.startTest();
        Map<String, Object> result = DataCloudService.getIrSummary();
        Test.stopTest();
        System.assertEquals(0, result.get('totalUnified'));
    }

    @isTest
    static void testGetSuspiciousMerges() {
        setupConfig();
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
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout('emptyData'));
        Test.startTest();
        List<Map<String, Object>> result = DataCloudService.getSuspiciousMerges(5);
        Test.stopTest();
        System.assertEquals(0, result.size());
    }

    @isTest
    static void testSearchUnifiedProfiles() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        List<Map<String, String>> result = DataCloudService.searchUnifiedProfiles('John');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetProfileMergeDetail() {
        setupConfig();
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
        setupConfig();
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
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        List<Map<String, String>> result = DataCloudService.getMissingContactProfiles('TestTable__dlm', 'phone');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testQueryDataCloud() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        String result = DataCloudService.queryDataCloud('SELECT COUNT() FROM UnifiedIndividual__dlm');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testQueryDataCloudError() {
        setupConfig();
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
    static void testMissingConfig() {
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        try {
            DataCloudService.getSegments();
            System.assert(false, 'Expected exception not thrown');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('missing Consumer Key'));
        }
        Test.stopTest();
    }

    @isTest
    static void testGetSegmentsApiError() {
        setupConfig();
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
        setupConfig();
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

    @isTest
    static void testGetActivations() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        String result = DataCloudService.getActivations();
        Test.stopTest();
        System.assertNotEquals(null, result);
        System.assert(result.contains('act1'));
    }

    @isTest
    static void testGetActivationsApiError() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout('apiError'));
        Test.startTest();
        try {
            DataCloudService.getActivations();
            System.assert(false, 'Expected exception not thrown');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('Failed to get activations'));
        }
        Test.stopTest();
    }

    @isTest
    static void testGetCalculatedInsights() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        String result = DataCloudService.getCalculatedInsights();
        Test.stopTest();
        System.assertNotEquals(null, result);
        System.assert(result.contains('TestCI'));
    }

    @isTest
    static void testGetCalculatedInsightsApiError() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout('apiError'));
        Test.startTest();
        try {
            DataCloudService.getCalculatedInsights();
            System.assert(false, 'Expected exception not thrown');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('Failed to get calculated insights'));
        }
        Test.stopTest();
    }

    @isTest
    static void testGetActivationPlatforms() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        String result = DataCloudService.getActivationPlatforms();
        Test.stopTest();
        System.assertNotEquals(null, result);
        System.assert(result.contains('Marketing Cloud'));
    }

    @isTest
    static void testGetActivationPlatformsApiError() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout('apiError'));
        Test.startTest();
        try {
            DataCloudService.getActivationPlatforms();
            System.assert(false, 'Expected exception not thrown');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('Failed to get activation platforms'));
        }
        Test.stopTest();
    }

    @isTest
    static void testGetDmoCoverage() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        Map<String, Integer> result = DataCloudService.getDmoCoverage();
        Test.stopTest();
        System.assertNotEquals(null, result);
        System.assert(result.size() > 0);
    }

    @isTest
    static void testGetOrgContactPointCoverage() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        Map<String, Integer> result = DataCloudService.getOrgContactPointCoverage();
        Test.stopTest();
        System.assertNotEquals(null, result);
        System.assert(result.containsKey('total'));
        System.assert(result.containsKey('withEmail'));
        System.assert(result.containsKey('withPhone'));
    }

    @isTest
    static void testGetDataTransforms() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        String result = DataCloudService.getDataTransforms();
        Test.stopTest();
        System.assertNotEquals(null, result);
        System.assert(result.contains('TestTransform'));
    }

    @isTest
    static void testGetDataTransformsApiError() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout('apiError'));
        Test.startTest();
        try {
            DataCloudService.getDataTransforms();
            System.assert(false, 'Expected exception not thrown');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('Failed to get data transforms'));
        }
        Test.stopTest();
    }

    @isTest
    static void testGetDataStreams() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        String result = DataCloudService.getDataStreams();
        Test.stopTest();
        System.assertNotEquals(null, result);
        System.assert(result.contains('TestStream'));
    }

    @isTest
    static void testGetDataStreamsApiError() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout('apiError'));
        Test.startTest();
        try {
            DataCloudService.getDataStreams();
            System.assert(false, 'Expected exception not thrown');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('Failed to get data streams'));
        }
        Test.stopTest();
    }
}
