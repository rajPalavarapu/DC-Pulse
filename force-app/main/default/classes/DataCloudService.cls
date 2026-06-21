public with sharing class DataCloudService {

    private static final String API_VERSION = 'v66.0';

    @TestVisible
    private static String testToken = null;

    private static String getBaseUrl() {
        return URL.getOrgDomainUrl().toExternalForm();
    }

    private static String getAccessToken() {
        if (testToken != null) {
            return testToken;
        }
        String token = UserInfo.getSessionId();
        if (String.isBlank(token)) {
            throw new CalloutException('No active session found. Please ensure you are logged into Salesforce.');
        }
        return token;
    }

    private static HttpResponse makeGetRequest(String endpoint) {
        String token = getAccessToken();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(getBaseUrl() + endpoint);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + token);
        return new Http().send(req);
    }

    private static HttpResponse makePostRequest(String endpoint, String body) {
        String token = getAccessToken();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(getBaseUrl() + endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setBody(body);
        return new Http().send(req);
    }

    public static String getSegments() {
        HttpResponse res = makeGetRequest('/services/data/' + API_VERSION + '/ssot/segments');
        if (res.getStatusCode() == 200) {
            return res.getBody();
        }
        throw new CalloutException('Failed to get segments: ' + res.getStatus() + ' ' + res.getBody());
    }

    public static String getSegmentDetails(String segmentApiName) {
        HttpResponse res = makeGetRequest('/services/data/' + API_VERSION + '/ssot/segments/' + segmentApiName);
        if (res.getStatusCode() == 200) {
            return res.getBody();
        }
        throw new CalloutException('Failed to get segment details: ' + res.getStatus() + ' ' + res.getBody());
    }

    public static Map<String, Integer> getActivationReadiness(String membershipTable, String segmentOnApiName) {
        Map<String, Integer> results = new Map<String, Integer>();

        String totalSql = 'SELECT COUNT() FROM ' + membershipTable;

        String emailSql = 'SELECT COUNT() AS cnt FROM ' + membershipTable + ' mem ' +
            'LEFT JOIN IndividualIdentityLink__dlm lnk ON mem.Id__c = lnk.UnifiedRecordId__c ' +
            'LEFT JOIN ssot__ContactPointEmail__dlm cpe ON lnk.SourceRecordId__c = cpe.ssot__PartyId__c ' +
            'WHERE cpe.ssot__Id__c IS NOT NULL';

        String phoneSql = 'SELECT COUNT() AS cnt FROM ' + membershipTable + ' mem ' +
            'LEFT JOIN IndividualIdentityLink__dlm lnk ON mem.Id__c = lnk.UnifiedRecordId__c ' +
            'LEFT JOIN ssot__ContactPointPhone__dlm cpp ON lnk.SourceRecordId__c = cpp.ssot__PartyId__c ' +
            'WHERE cpp.ssot__Id__c IS NOT NULL';

        HttpResponse totalRes = makePostRequest('/services/data/' + API_VERSION + '/ssot/query-sql?dataspace=default', '{"sql": "' + totalSql.escapeJava() + '"}');
        HttpResponse emailRes = makePostRequest('/services/data/' + API_VERSION + '/ssot/query-sql?dataspace=default', '{"sql": "' + emailSql.escapeJava() + '"}');
        HttpResponse phoneRes = makePostRequest('/services/data/' + API_VERSION + '/ssot/query-sql?dataspace=default', '{"sql": "' + phoneSql.escapeJava() + '"}');

        results.put('total', extractCount(totalRes));
        results.put('email', extractCount(emailRes));
        results.put('phone', extractCount(phoneRes));

        return results;
    }

    private static Integer extractCount(HttpResponse res) {
        Integer statusCode = res.getStatusCode();
        if (statusCode == 200 || statusCode == 201) {
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> rows = (List<Object>) body.get('data');
            if (rows != null && !rows.isEmpty()) {
                List<Object> firstRow = (List<Object>) rows[0];
                if (firstRow != null && !firstRow.isEmpty()) {
                    return Integer.valueOf(String.valueOf(firstRow[0]));
                }
            }
        }
        return 0;
    }

    public static List<Map<String, String>> getMissingContactProfiles(String membershipTable, String contactType) {
        String joinTable = contactType == 'phone' ? 'ssot__ContactPointPhone__dlm' : 'ssot__ContactPointEmail__dlm';
        String joinAlias = contactType == 'phone' ? 'cpp' : 'cpe';

        String contactField = contactType == 'phone' ? joinAlias + '.ssot__TelephoneNumber__c' : joinAlias + '.ssot__EmailAddress__c';
        String contactLabel = contactType == 'phone' ? 'phoneNumber' : 'emailAddress';

        String sql = 'SELECT ui.ssot__FirstName__c, ui.ssot__LastName__c, ui.ssot__Id__c, ' + contactField + ' ' +
            'FROM ' + membershipTable + ' mem ' +
            'JOIN UnifiedIndividual__dlm ui ON mem.Id__c = ui.ssot__Id__c ' +
            'LEFT JOIN IndividualIdentityLink__dlm lnk ON mem.Id__c = lnk.UnifiedRecordId__c ' +
            'LEFT JOIN ' + joinTable + ' ' + joinAlias + ' ON lnk.SourceRecordId__c = ' + joinAlias + '.ssot__PartyId__c ' +
            'WHERE ' + joinAlias + '.ssot__Id__c IS NULL ' +
            'LIMIT 10';

        HttpResponse res = makePostRequest('/services/data/' + API_VERSION + '/ssot/query-sql?dataspace=default', '{"sql": "' + sql.escapeJava() + '"}');

        List<Map<String, String>> profiles = new List<Map<String, String>>();
        Integer statusCode = res.getStatusCode();
        if (statusCode == 200 || statusCode == 201) {
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> rows = (List<Object>) body.get('data');
            if (rows != null) {
                for (Object row : rows) {
                    List<Object> cols = (List<Object>) row;
                    Map<String, String> profile = new Map<String, String>();
                    profile.put('firstName', cols[0] != null ? String.valueOf(cols[0]) : '');
                    profile.put('lastName', cols[1] != null ? String.valueOf(cols[1]) : '');
                    profile.put('unifiedId', cols[2] != null ? String.valueOf(cols[2]) : '');
                    profile.put(contactLabel, '— Not Available —');
                    profiles.add(profile);
                }
            }
        }
        return profiles;
    }

    public static String queryDataCloud(String sql) {
        String body = '{"sql": "' + sql.escapeJava() + '"}';
        HttpResponse res = makePostRequest('/services/data/' + API_VERSION + '/ssot/query-sql?dataspace=default', body);
        if (res.getStatusCode() == 200) {
            return res.getBody();
        }
        throw new CalloutException('Failed to query Data Cloud: ' + res.getStatus() + ' ' + res.getBody());
    }

    public static Map<String, Object> getIrSummary() {
        String unifiedSql = 'SELECT COUNT() FROM UnifiedIndividual__dlm';
        String linkSql = 'SELECT COUNT() FROM IndividualIdentityLink__dlm';
        HttpResponse unifiedRes = makePostRequest('/services/data/' + API_VERSION + '/ssot/query-sql?dataspace=default', '{"sql": "' + unifiedSql.escapeJava() + '"}');
        HttpResponse linkRes = makePostRequest('/services/data/' + API_VERSION + '/ssot/query-sql?dataspace=default', '{"sql": "' + linkSql.escapeJava() + '"}');
        Integer totalUnified = extractCount(unifiedRes);
        Integer totalLinks = extractCount(linkRes);
        Decimal avg = totalUnified > 0 ? ((Decimal)totalLinks / totalUnified).setScale(1) : 0;
        Map<String, Object> results = new Map<String, Object>();
        results.put('totalUnified', totalUnified);
        results.put('totalLinks', totalLinks);
        results.put('avgLinksPerProfile', avg);
        return results;
    }

    public static List<Map<String, Object>> getSuspiciousMerges(Integer threshold) {
        String sql = 'SELECT lnk.UnifiedRecordId__c, ui.ssot__FirstName__c, ui.ssot__LastName__c, COUNT() AS mergeCount ' +
            'FROM IndividualIdentityLink__dlm lnk ' +
            'JOIN UnifiedIndividual__dlm ui ON lnk.UnifiedRecordId__c = ui.ssot__Id__c ' +
            'GROUP BY lnk.UnifiedRecordId__c, ui.ssot__FirstName__c, ui.ssot__LastName__c ' +
            'HAVING COUNT() >= ' + threshold + ' ' +
            'ORDER BY COUNT() DESC ' +
            'LIMIT 25';
        HttpResponse res = makePostRequest('/services/data/' + API_VERSION + '/ssot/query-sql?dataspace=default', '{"sql": "' + sql.escapeJava() + '"}');
        List<Map<String, Object>> merges = new List<Map<String, Object>>();
        Integer statusCode = res.getStatusCode();
        if (statusCode == 200 || statusCode == 201) {
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> rows = (List<Object>) body.get('data');
            if (rows != null) {
                for (Object row : rows) {
                    List<Object> cols = (List<Object>) row;
                    Map<String, Object> mergeRow = new Map<String, Object>();
                    mergeRow.put('unifiedId', cols[0] != null ? String.valueOf(cols[0]) : '');
                    mergeRow.put('firstName', cols[1] != null ? String.valueOf(cols[1]) : '');
                    mergeRow.put('lastName', cols[2] != null ? String.valueOf(cols[2]) : '');
                    mergeRow.put('mergeCount', cols[3] != null ? Integer.valueOf(String.valueOf(cols[3])) : 0);
                    merges.add(mergeRow);
                }
            }
        }
        return merges;
    }

    public static List<Map<String, String>> searchUnifiedProfiles(String searchTerm) {
        String safe = searchTerm.replace('\'', '\'\'');
        String sql = 'SELECT ssot__Id__c, ssot__FirstName__c, ssot__LastName__c ' +
            'FROM UnifiedIndividual__dlm ' +
            'WHERE ssot__FirstName__c LIKE \'%' + safe + '%\' ' +
            'OR ssot__LastName__c LIKE \'%' + safe + '%\' ' +
            'LIMIT 20';
        HttpResponse res = makePostRequest('/services/data/' + API_VERSION + '/ssot/query-sql?dataspace=default', '{"sql": "' + sql.escapeJava() + '"}');
        List<Map<String, String>> profiles = new List<Map<String, String>>();
        Integer statusCode = res.getStatusCode();
        if (statusCode == 200 || statusCode == 201) {
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> rows = (List<Object>) body.get('data');
            if (rows != null) {
                for (Object row : rows) {
                    List<Object> cols = (List<Object>) row;
                    Map<String, String> profile = new Map<String, String>();
                    profile.put('unifiedId', cols[0] != null ? String.valueOf(cols[0]) : '');
                    profile.put('firstName', cols[1] != null ? String.valueOf(cols[1]) : '');
                    profile.put('lastName', cols[2] != null ? String.valueOf(cols[2]) : '');
                    profiles.add(profile);
                }
            }
        }
        return profiles;
    }

    public static List<Map<String, String>> getProfileMergeDetail(String unifiedId) {
        String safe = unifiedId.replace('\'', '\'\'');
        String sql = 'SELECT SourceRecordId__c, ssot__DataSourceId__c, ssot__DataSourceObjectId__c ' +
            'FROM IndividualIdentityLink__dlm ' +
            'WHERE UnifiedRecordId__c = \'' + safe + '\' ' +
            'LIMIT 50';
        HttpResponse res = makePostRequest('/services/data/' + API_VERSION + '/ssot/query-sql?dataspace=default', '{"sql": "' + sql.escapeJava() + '"}');
        List<Map<String, String>> records = new List<Map<String, String>>();
        Integer statusCode = res.getStatusCode();
        if (statusCode == 200 || statusCode == 201) {
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> rows = (List<Object>) body.get('data');
            if (rows != null) {
                for (Object row : rows) {
                    List<Object> cols = (List<Object>) row;
                    Map<String, String> record = new Map<String, String>();
                    record.put('sourceRecordId', cols[0] != null ? String.valueOf(cols[0]) : '');
                    record.put('dataSourceId', cols[1] != null ? String.valueOf(cols[1]) : '');
                    record.put('dataSourceObjectId', cols[2] != null ? String.valueOf(cols[2]) : '');
                    records.add(record);
                }
            }
        }
        return records;
    }
}
