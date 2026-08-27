@isTest
private class DataCloudControllerTest {

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
        String result = DataCloudController.getSegments();
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetSegmentDetails() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        String result = DataCloudController.getSegmentDetails('TestSeg');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetActivationReadiness() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        Map<String, Integer> result = DataCloudController.getActivationReadiness('TestTable__dlm', 'UnifiedIndividual__dlm', 'testSegId123');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetMissingContactProfiles() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        List<Map<String, String>> result = DataCloudController.getMissingContactProfiles('TestTable__dlm', 'email');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testQueryDataCloud() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        String result = DataCloudController.queryDataCloud('SELECT COUNT() FROM UnifiedIndividual__dlm');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetIrSummary() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        Map<String, Object> result = DataCloudController.getIrSummary();
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetSuspiciousMerges() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        List<Map<String, Object>> result = DataCloudController.getSuspiciousMerges(5);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testSearchUnifiedProfiles() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        List<Map<String, String>> result = DataCloudController.searchUnifiedProfiles('John');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetProfileMergeDetail() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        List<Map<String, String>> result = DataCloudController.getProfileMergeDetail('uid1');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetActivations() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        String result = DataCloudController.getActivations();
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetCalculatedInsights() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        String result = DataCloudController.getCalculatedInsights();
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetActivationPlatforms() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        String result = DataCloudController.getActivationPlatforms();
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetDmoCoverage() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        Map<String, Integer> result = DataCloudController.getDmoCoverage();
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetOrgContactPointCoverage() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        Map<String, Integer> result = DataCloudController.getOrgContactPointCoverage();
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetDataTransforms() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        String result = DataCloudController.getDataTransforms();
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetDataStreams() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        String result = DataCloudController.getDataStreams();
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetSegmentOverlap() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout('overlapData'));
        Test.startTest();
        List<Map<String, Object>> result = DataCloudController.getSegmentOverlap();
        Test.stopTest();
        System.assertNotEquals(null, result);
        System.assert(result.size() > 0);
    }

    @isTest
    static void testGetSegmentsByCategory() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        List<Map<String, Object>> result = DataCloudController.getSegmentsByCategory('zero');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetSegmentsByCategoryError() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout('apiError'));
        Test.startTest();
        try {
            DataCloudController.getSegmentsByCategory('zero');
        } catch (Exception e) {
            System.assertNotEquals(null, e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGetSegmentHealthSummary() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        Map<String, Object> result = DataCloudController.getSegmentHealthSummary();
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetSegmentHealthSummaryError() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout('apiError'));
        Test.startTest();
        try {
            DataCloudController.getSegmentHealthSummary();
        } catch (Exception e) {
            System.assertNotEquals(null, e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testSearchSegments() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        List<Map<String, Object>> result = DataCloudController.searchSegments('Test');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testSearchSegmentsError() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout('apiError'));
        Test.startTest();
        try {
            DataCloudController.searchSegments('Test');
        } catch (Exception e) {
            System.assertNotEquals(null, e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGetProfileExplorer() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        List<Map<String, Object>> result = DataCloudController.getProfileExplorer('John');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetProfileExplorerError() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout('apiError'));
        Test.startTest();
        try {
            DataCloudController.getProfileExplorer('John');
        } catch (Exception e) {
            System.assertNotEquals(null, e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGetSegmentOverlapError() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout('apiError'));
        Test.startTest();
        try {
            DataCloudController.getSegmentOverlap();
            System.assert(false, 'Expected exception');
        } catch (Exception e) {
            System.assertNotEquals(null, e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGetSegmentsError() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout('apiError'));
        Test.startTest();
        try {
            DataCloudController.getSegments();
            System.assert(false, 'Expected exception');
        } catch (Exception e) {
            System.assertNotEquals(null, e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGetSegmentDetailsError() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout('apiError'));
        Test.startTest();
        try {
            DataCloudController.getSegmentDetails('TestSeg');
            System.assert(false, 'Expected exception');
        } catch (Exception e) {
            System.assertNotEquals(null, e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGetActivationsError() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout('apiError'));
        Test.startTest();
        try {
            DataCloudController.getActivations();
            System.assert(false, 'Expected exception');
        } catch (Exception e) {
            System.assertNotEquals(null, e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGetCalculatedInsightsError() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout('apiError'));
        Test.startTest();
        try {
            DataCloudController.getCalculatedInsights();
            System.assert(false, 'Expected exception');
        } catch (Exception e) {
            System.assertNotEquals(null, e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGetDataTransformsError() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout('apiError'));
        Test.startTest();
        try {
            DataCloudController.getDataTransforms();
            System.assert(false, 'Expected exception');
        } catch (Exception e) {
            System.assertNotEquals(null, e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGetDataStreamsError() {
        setupConfig();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout('apiError'));
        Test.startTest();
        try {
            DataCloudController.getDataStreams();
            System.assert(false, 'Expected exception');
        } catch (Exception e) {
            System.assertNotEquals(null, e.getMessage());
        }
        Test.stopTest();
    }
}
