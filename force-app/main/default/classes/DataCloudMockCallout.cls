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
            res.setStatusCode(200);
            res.setBody('{"access_token":"testtoken123"}');
            return res;
        }

        if (mode == 'apiError') {
            res.setStatusCode(500);
            res.setBody('{"error":"server error"}');
            return res;
        }

        if (endpoint.endsWith('/ssot/activations') && req.getMethod() == 'GET') {
            res.setStatusCode(200);
            res.setBody('{"activations":[{"id":"act1","segmentApiName":"TestSeg","name":"Test Activation"}]}');
            return res;
        }

        if (endpoint.endsWith('/ssot/calculated-insights') && req.getMethod() == 'GET') {
            res.setStatusCode(200);
            res.setBody('{"calculatedInsights":[{"apiName":"TestCI","label":"Test CI"}]}');
            return res;
        }

        if (endpoint.endsWith('/ssot/activation-external-platforms') && req.getMethod() == 'GET') {
            res.setStatusCode(200);
            res.setBody('{"activationExternalPlatforms":[{"id":"plat1","name":"Marketing Cloud"}]}');
            return res;
        }

        if (endpoint.endsWith('/ssot/data-transforms') && req.getMethod() == 'GET') {
            res.setStatusCode(200);
            res.setBody('{"dataTransforms":[{"id":"dt1","apiName":"TestTransform","label":"Test Transform","status":"Succeeded"}]}');
            return res;
        }

        if (endpoint.endsWith('/ssot/data-streams') && req.getMethod() == 'GET') {
            res.setStatusCode(200);
            res.setBody('{"dataStreams":[{"id":"ds1","apiName":"TestStream","label":"Test Stream","connectorType":"Batch"}]}');
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
