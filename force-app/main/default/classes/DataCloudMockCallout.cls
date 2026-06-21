@isTest
global class DataCloudMockCallout implements HttpCalloutMock {

    private String mode;

    global DataCloudMockCallout() { this.mode = 'success'; }
    global DataCloudMockCallout(String mode) { this.mode = mode; }

    global HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        String endpoint = req.getEndpoint();

        if (endpoint.contains('/oauth2/token')) {
            if (mode == 'tokenError') {
                res.setStatusCode(401);
                res.setBody('{"error":"invalid_client"}');
            } else {
                res.setStatusCode(200);
                res.setBody('{"access_token":"testtoken123"}');
            }
            return res;
        }

        if (mode == 'apiError') {
            res.setStatusCode(500);
            res.setBody('{"error":"server error"}');
            return res;
        }

        if (endpoint.endsWith('/ssot/segments') && req.getMethod() == 'GET') {
            res.setStatusCode(200);
            res.setBody('{"segments":[{"apiName":"TestSeg","displayName":"Test Segment","segmentStatus":"ACTIVE","lastSegmentMemberCount":100}]}');
            return res;
        }

        if (endpoint.contains('/ssot/segments/') && req.getMethod() == 'GET') {
            res.setStatusCode(200);
            res.setBody('{"segments":[{"apiName":"TestSeg","displayName":"Test Segment","segmentStatus":"ACTIVE"}]}');
            return res;
        }

        if (endpoint.contains('/ssot/query-sql')) {
            if (mode == 'emptyData') {
                res.setStatusCode(200);
                res.setBody('{"data":[]}');
                return res;
            }
            String body = req.getBody();
            if (body != null && body.contains('GROUP BY')) {
                res.setStatusCode(200);
                res.setBody('{"data":[["uid1","John","Doe","3"]]}');
            } else if (body != null && body.contains('ssot__DataSourceObjectId__c')) {
                res.setStatusCode(200);
                res.setBody('{"data":[["srcId1","dsId1","dsoId1"]]}');
            } else if (body != null && body.contains('ssot__FirstName__c') && body.contains('ssot__LastName__c')) {
                res.setStatusCode(200);
                res.setBody('{"data":[["John","Doe","uid1","john@test.com"]]}');
            } else {
                res.setStatusCode(200);
                res.setBody('{"data":[[5]]}');
            }
            return res;
        }

        res.setStatusCode(200);
        res.setBody('{}');
        return res;
    }
}
