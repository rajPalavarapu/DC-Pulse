@isTest
private class DataCloudControllerTest {

    private static void setupToken() {
        DataCloudService.testToken = 'testtoken123';
    }

    @isTest
    static void testGetSegments() {
        setupToken();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        String result = DataCloudController.getSegments();
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetSegmentDetails() {
        setupToken();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        String result = DataCloudController.getSegmentDetails('TestSeg');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetActivationReadiness() {
        setupToken();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        Map<String, Integer> result = DataCloudController.getActivationReadiness('TestTable__dlm', 'UnifiedIndividual__dlm');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetMissingContactProfiles() {
        setupToken();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        List<Map<String, String>> result = DataCloudController.getMissingContactProfiles('TestTable__dlm', 'email');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testQueryDataCloud() {
        setupToken();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        String result = DataCloudController.queryDataCloud('SELECT COUNT() FROM UnifiedIndividual__dlm');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetIrSummary() {
        setupToken();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        Map<String, Object> result = DataCloudController.getIrSummary();
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetSuspiciousMerges() {
        setupToken();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        List<Map<String, Object>> result = DataCloudController.getSuspiciousMerges(5);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testSearchUnifiedProfiles() {
        setupToken();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        List<Map<String, String>> result = DataCloudController.searchUnifiedProfiles('John');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetProfileMergeDetail() {
        setupToken();
        Test.setMock(HttpCalloutMock.class, new DataCloudMockCallout());
        Test.startTest();
        List<Map<String, String>> result = DataCloudController.getProfileMergeDetail('uid1');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }
}
