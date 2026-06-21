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
        Map<String, Integer> result = DataCloudController.getActivationReadiness('TestTable__dlm', 'UnifiedIndividual__dlm');
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
}
