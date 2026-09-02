public with sharing class DataCloudService {

    private static final String API_VERSION = 'v66.0';

    private static String cachedToken;

    private static String getBaseUrl() {
        return URL.getOrgDomainUrl().toExternalForm();
    }

    private static String getAccessToken() {
        if (cachedToken != null) return cachedToken;
        DC_Lens_Config__c config = DC_Lens_Config__c.getInstance();
        if (config == null || config.Consumer_Key__c == null || config.Consumer_Secret__c == null) {
            throw new CalloutException('Data Cloud Insights Config custom setting is missing Consumer Key or Secret.');
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(getBaseUrl() + '/services/oauth2/token');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setBody(
            'grant_type=client_credentials' +
            '&client_id=' + EncodingUtil.urlEncode(config.Consumer_Key__c, 'UTF-8') +
            '&client_secret=' + EncodingUtil.urlEncode(config.Consumer_Secret__c, 'UTF-8')
        );

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() == 200) {
            Map<String, Object> tokenResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            cachedToken = (String) tokenResponse.get('access_token');
            return cachedToken;
        }
        throw new CalloutException('Failed to get access token: ' + res.getStatus() + ' ' + res.getBody());
    }

    private static HttpResponse makeGetRequest(String endpoint) {
        String token = getAccessToken();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(getBaseUrl() + endpoint);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setTimeout(120000);
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
        req.setTimeout(120000);
        return new Http().send(req);
    }

    public static String getSegments() {
        HttpResponse res = makeGetRequest('/services/data/' + API_VERSION + '/ssot/segments');
        if (res.getStatusCode() == 200) {
            return res.getBody();
        }
        throw new CalloutException('Failed to get segments: ' + res.getStatus() + ' ' + res.getBody());
    }

    public static List<Map<String, Object>> getSegmentsByCategory(String category) {
        HttpResponse res = makeGetRequest('/services/data/' + API_VERSION + '/ssot/segments?limit=2000');
        List<Map<String, Object>> results = new List<Map<String, Object>>();
        if (res.getStatusCode() != 200) return results;
        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        List<Object> segments = (List<Object>) body.get('segments');
        if (segments == null) return results;
        for (Object seg : segments) {
            Map<String, Object> s = (Map<String, Object>) seg;
            Integer memberCount = s.get('lastSegmentMemberCount') != null
                ? Integer.valueOf(String.valueOf(s.get('lastSegmentMemberCount'))) : 0;
            String status   = (String) s.get('segmentStatus');
            String interval = (String) s.get('publishInterval');
            Boolean match = false;
            if (category == 'zero'     && memberCount == 0) match = true;
            if (category == 'inactive' && 'INACTIVE'.equals(status)) match = true;
            if (category == 'manual'   && 'NO_REFRESH'.equals(interval)) match = true;
            if (match) {
                results.add(new Map<String, Object>{
                    'displayName'           => s.get('displayName'),
                    'apiName'               => s.get('apiName'),
                    'segmentStatus'         => status,
                    'lastSegmentMemberCount'=> memberCount,
                    'publishInterval'       => interval
                });
            }
        }
        return results;
    }

    public static Map<String, Object> getSegmentHealthSummary() {
        HttpResponse res = makeGetRequest('/services/data/' + API_VERSION + '/ssot/segments?limit=500');
        Map<String, Object> summary = new Map<String, Object>{
            'totalCount' => 0, 'zeroPopulationCount' => 0,
            'inactiveCount' => 0, 'manualRefreshCount' => 0,
            'zeroPopulationNames' => new List<String>(),
            'inactiveNames' => new List<String>(),
            'manualRefreshNames' => new List<String>()
        };
        if (res.getStatusCode() != 200) return summary;
        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        List<Object> segments = (List<Object>) body.get('segments');
        if (segments == null) return summary;
        Integer zeroCount = 0, inactiveCount = 0, manualCount = 0;
        List<String> zeroNames = new List<String>(), inactiveNames = new List<String>(), manualNames = new List<String>();
        for (Object seg : segments) {
            Map<String, Object> s = (Map<String, Object>) seg;
            String displayName = (String) s.get('displayName');
            Integer memberCount = s.get('lastSegmentMemberCount') != null
                ? Integer.valueOf(String.valueOf(s.get('lastSegmentMemberCount'))) : 0;
            String status = (String) s.get('segmentStatus');
            String interval = (String) s.get('publishInterval');
            if (memberCount == 0) { zeroCount++; if (zeroNames.size() < 5) zeroNames.add(displayName); }
            if ('INACTIVE'.equals(status)) { inactiveCount++; if (inactiveNames.size() < 5) inactiveNames.add(displayName); }
            if ('NO_REFRESH'.equals(interval)) { manualCount++; if (manualNames.size() < 5) manualNames.add(displayName); }
        }
        summary.put('totalCount', segments.size());
        summary.put('zeroPopulationCount', zeroCount);
        summary.put('inactiveCount', inactiveCount);
        summary.put('manualRefreshCount', manualCount);
        summary.put('zeroPopulationNames', zeroNames);
        summary.put('inactiveNames', inactiveNames);
        summary.put('manualRefreshNames', manualNames);
        return summary;
    }

    public static List<Map<String, Object>> searchSegments(String searchTerm) {
        HttpResponse res = makeGetRequest('/services/data/' + API_VERSION + '/ssot/segments?limit=500');
        List<Map<String, Object>> results = new List<Map<String, Object>>();
        if (res.getStatusCode() != 200) return results;
        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        List<Object> segments = (List<Object>) body.get('segments');
        if (segments == null) return results;
        String lowerSearch = searchTerm.toLowerCase();
        String lowerSearchUnderscored = lowerSearch.replace(' ', '_');
        for (Object seg : segments) {
            Map<String, Object> s = (Map<String, Object>) seg;
            String displayName = (String) s.get('displayName');
            String apiName    = (String) s.get('apiName');
            String nameField  = (String) s.get('name');
            String lowerDisplay = displayName != null ? displayName.toLowerCase() : '';
            String lowerApi     = apiName    != null ? apiName.toLowerCase()     : '';
            String lowerName    = nameField  != null ? nameField.toLowerCase()   : '';
            Boolean matches = lowerDisplay.contains(lowerSearch)
                || lowerApi.contains(lowerSearch)
                || lowerApi.contains(lowerSearchUnderscored)
                || lowerApi.replace('_', ' ').contains(lowerSearch)
                || lowerName.contains(lowerSearch);
            if (matches) {
                String label = displayName != null ? displayName
                             : (nameField  != null ? nameField : apiName);
                results.add(new Map<String, Object>{
                    'apiName' => apiName,
                    'displayName' => label,
                    'segmentStatus' => s.get('segmentStatus'),
                    'lastSegmentMemberCount' => s.get('lastSegmentMemberCount')
                });
                if (results.size() >= 20) break;
            }
        }
        return results;
    }

    public static String getSegmentDetails(String segmentApiName) {
        HttpResponse res = makeGetRequest('/services/data/' + API_VERSION + '/ssot/segments/' + segmentApiName);
        if (res.getStatusCode() == 200) {
            return res.getBody();
        }
        throw new CalloutException('Failed to get segment details: ' + res.getStatus() + ' ' + res.getBody());
    }

    public static Map<String, Integer> getActivationReadiness(String membershipTable, String segmentOnApiName, String marketSegmentId) {
        Map<String, Integer> results = new Map<String, Integer>();

        // Membership tables are shared across all segments and accumulate rows across every publish run.
        // Segment_Id__c stores the 15-char Salesforce ID; marketSegmentId from the API is 18 chars — truncate to match.
        String segId15 = (marketSegmentId != null && marketSegmentId.length() >= 15)
            ? marketSegmentId.left(15) : (marketSegmentId != null ? marketSegmentId : '');
        String safeSegId = segId15.replace('\'', '\'\'');

        String latestTs = null;
        HttpResponse maxTsRes = makePostRequest(
            '/services/data/' + API_VERSION + '/ssot/query-sql?dataspace=default',
            '{"sql": "SELECT MAX(Timestamp__c) AS maxTs FROM ' + membershipTable + ' WHERE Segment_Id__c = \'' + safeSegId + '\'"}'
        );
        if (maxTsRes.getStatusCode() == 200 || maxTsRes.getStatusCode() == 201) {
            Map<String, Object> tsBody = (Map<String, Object>) JSON.deserializeUntyped(maxTsRes.getBody());
            List<Object> tsRows = (List<Object>) tsBody.get('data');
            if (tsRows != null && !tsRows.isEmpty()) {
                List<Object> firstRow = (List<Object>) tsRows[0];
                if (firstRow != null && !firstRow.isEmpty() && firstRow[0] != null) {
                    latestTs = String.valueOf(firstRow[0]);
                }
            }
        }

        String safeTs = latestTs != null ? latestTs.replace('\'', '\'\'') : '';
        String baseFilter = ' WHERE Segment_Id__c = \'' + safeSegId + '\''
            + (latestTs != null ? ' AND Timestamp__c = \'' + safeTs + '\'' : '')
            + ' AND Delta_Type__c <> \'removed\'';
        String joinFilter = ' AND mem.Segment_Id__c = \'' + safeSegId + '\''
            + (latestTs != null ? ' AND mem.Timestamp__c = \'' + safeTs + '\'' : '')
            + ' AND mem.Delta_Type__c <> \'removed\'';

        String totalSql = 'SELECT COUNT() FROM ' + membershipTable + baseFilter;

        String emailSql = 'SELECT COUNT(DISTINCT mem.Id__c) AS cnt FROM ' + membershipTable + ' mem ' +
            'LEFT JOIN IndividualIdentityLink__dlm lnk ON mem.Id__c = lnk.UnifiedRecordId__c ' +
            'LEFT JOIN ssot__ContactPointEmail__dlm cpe ON lnk.SourceRecordId__c = cpe.ssot__PartyId__c ' +
            'WHERE cpe.ssot__Id__c IS NOT NULL' + joinFilter;

        String phoneSql = 'SELECT COUNT(DISTINCT mem.Id__c) AS cnt FROM ' + membershipTable + ' mem ' +
            'LEFT JOIN IndividualIdentityLink__dlm lnk ON mem.Id__c = lnk.UnifiedRecordId__c ' +
            'LEFT JOIN ssot__ContactPointPhone__dlm cpp ON lnk.SourceRecordId__c = cpp.ssot__PartyId__c ' +
            'WHERE cpp.ssot__Id__c IS NOT NULL' + joinFilter;

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

    public static List<Map<String, Object>> getSegmentOverlap() {
        // Step 1 — fetch all segments
        HttpResponse segRes = makeGetRequest('/services/data/' + API_VERSION + '/ssot/segments?limit=500');
        if (segRes.getStatusCode() != 200) throw new CalloutException('Failed to load segments');
        Map<String, Object> segBody = (Map<String, Object>) JSON.deserializeUntyped(segRes.getBody());
        List<Object> allSegs = (List<Object>) segBody.get('segments');
        if (allSegs == null || allSegs.isEmpty()) return new List<Map<String, Object>>();

        // Collect active segments with non-zero population
        List<Map<String, Object>> candidates = new List<Map<String, Object>>();
        for (Object seg : allSegs) {
            Map<String, Object> s = (Map<String, Object>) seg;
            if (!'ACTIVE'.equals((String) s.get('segmentStatus'))) continue;
            Integer memberCount = s.get('lastSegmentMemberCount') != null
                ? Integer.valueOf(String.valueOf(s.get('lastSegmentMemberCount'))) : 0;
            if (memberCount == 0) continue;
            candidates.add(new Map<String, Object>{
                'displayName' => (String) s.get('displayName'),
                'apiName'     => (String) s.get('apiName'),
                'memberCount' => memberCount
            });
        }

        // Cap at 10 — 1 token + 1 list + 10 details + 45 pairs = 57 callouts max, well under the 100 limit
        candidates.sort(new MemberCountComparator());
        List<Map<String, Object>> top = new List<Map<String, Object>>();
        for (Integer i = 0; i < Math.min(10, candidates.size()); i++) {
            top.add(candidates[i]);
        }

        // Step 2 — resolve membershipTable and marketSegmentId from detail API per segment
        for (Map<String, Object> seg : top) {
            HttpResponse detailRes = makeGetRequest(
                '/services/data/' + API_VERSION + '/ssot/segments/' + (String) seg.get('apiName')
            );
            if (detailRes.getStatusCode() != 200) continue;
            Map<String, Object> detailBody = (Map<String, Object>) JSON.deserializeUntyped(detailRes.getBody());
            List<Object> segsArr = (List<Object>) detailBody.get('segments');
            if (segsArr == null || segsArr.isEmpty()) continue;
            Map<String, Object> detail = (Map<String, Object>) segsArr[0];
            // marketSegmentId is needed to filter Segment_Id__c in the shared membership table
            String marketSegmentId = (String) detail.get('marketSegmentId');
            if (!String.isBlank(marketSegmentId)) seg.put('marketSegmentId', marketSegmentId);
            Map<String, Object> membershipDmo = (Map<String, Object>) detail.get('segmentMembershipDmo');
            if (membershipDmo == null) continue;
            String latestTable = (String) membershipDmo.get('latestTable');
            if (!String.isBlank(latestTable)) seg.put('membershipTable', latestTable);
        }

        // Keep only segments where we have both table and segment ID
        List<Map<String, Object>> withTable = new List<Map<String, Object>>();
        for (Map<String, Object> seg : top) {
            if (!String.isBlank((String) seg.get('membershipTable'))
                && !String.isBlank((String) seg.get('marketSegmentId'))) {
                withTable.add(seg);
            }
        }
        if (withTable.size() < 2) return new List<Map<String, Object>>();

        // Step 3 — fetch MAX(Timestamp__c) per segment for latest publish snapshot
        // marketSegmentId from API is 18-char; Segment_Id__c stores 15-char — must truncate to match
        for (Map<String, Object> seg : withTable) {
            String table    = (String) seg.get('membershipTable');
            String rawId    = (String) seg.get('marketSegmentId');
            String segId15  = (rawId != null && rawId.length() >= 15) ? rawId.left(15) : rawId;
            String safeId   = segId15 != null ? segId15.replace('\'', '\'\'') : '';
            seg.put('segId15', safeId);
            String tsSql = 'SELECT MAX(Timestamp__c) AS maxTs FROM ' + table
                         + ' WHERE Segment_Id__c = \'' + safeId + '\'';
            HttpResponse tsRes = makePostRequest(
                '/services/data/' + API_VERSION + '/ssot/query-sql?dataspace=default',
                '{"sql": "' + tsSql.escapeJava() + '"}'
            );
            if (tsRes.getStatusCode() == 200 || tsRes.getStatusCode() == 201) {
                Map<String, Object> tsBody = (Map<String, Object>) JSON.deserializeUntyped(tsRes.getBody());
                List<Object> rows = (List<Object>) tsBody.get('data');
                if (rows != null && !rows.isEmpty()) {
                    List<Object> firstRow = (List<Object>) rows[0];
                    if (firstRow != null && !firstRow.isEmpty() && firstRow[0] != null) {
                        seg.put('latestTs', String.valueOf(firstRow[0]).replace('\'', '\'\''));
                    }
                }
            }
        }

        // Step 4 — one COUNT JOIN query per pair, filtered by Segment_Id__c + latest snapshot + not removed
        List<Map<String, Object>> pairs = new List<Map<String, Object>>();
        for (Integer i = 0; i < withTable.size(); i++) {
            for (Integer j = i + 1; j < withTable.size(); j++) {
                String tableA = (String) withTable[i].get('membershipTable');
                String tableB = (String) withTable[j].get('membershipTable');
                String segIdA = (String) withTable[i].get('segId15');
                String segIdB = (String) withTable[j].get('segId15');
                String tsA    = (String) withTable[i].get('latestTs');
                String tsB    = (String) withTable[j].get('latestTs');
                // Skip pairs where timestamp couldn't be resolved — would produce wrong counts
                if (String.isBlank(tsA) || String.isBlank(tsB)) continue;

                String sql = 'SELECT COUNT() FROM ' + tableA + ' a '
                           + 'INNER JOIN ' + tableB + ' b ON a.Id__c = b.Id__c '
                           + 'WHERE a.Segment_Id__c = \'' + segIdA + '\''
                           + ' AND b.Segment_Id__c = \'' + segIdB + '\''
                           + ' AND a.Timestamp__c = \'' + tsA + '\''
                           + ' AND b.Timestamp__c = \'' + tsB + '\''
                           + ' AND a.Delta_Type__c <> \'removed\''
                           + ' AND b.Delta_Type__c <> \'removed\'';

                HttpResponse qRes = makePostRequest(
                    '/services/data/' + API_VERSION + '/ssot/query-sql?dataspace=default',
                    '{"sql": "' + sql.escapeJava() + '"}'
                );
                Integer overlap = 0;
                if (qRes.getStatusCode() == 200 || qRes.getStatusCode() == 201) {
                    overlap = extractCount(qRes);
                }
                if (overlap == 0) continue;
                Integer countA = (Integer) withTable[i].get('memberCount');
                Integer countB = (Integer) withTable[j].get('memberCount');
                Integer smaller = Math.min(countA, countB);
                Decimal pct = smaller > 0 ? ((Decimal) overlap / smaller * 100).setScale(1) : 0;
                if (pct < 25) continue;
                pairs.add(new Map<String, Object>{
                    'segmentA'     => (String) withTable[i].get('displayName'),
                    'segmentB'     => (String) withTable[j].get('displayName'),
                    'countA'       => countA,
                    'countB'       => countB,
                    'overlapCount' => overlap,
                    'overlapPct'   => pct
                });
            }
        }

        // Sort by overlap count descending, return top 20
        pairs.sort(new OverlapCountComparator());
        List<Map<String, Object>> topPairs = new List<Map<String, Object>>();
        for (Integer i = 0; i < Math.min(20, pairs.size()); i++) {
            topPairs.add(pairs[i]);
        }
        return topPairs;
    }

    private class MemberCountComparator implements Comparator<Map<String, Object>> {
        public Integer compare(Map<String, Object> a, Map<String, Object> b) {
            Integer ca = (Integer) a.get('memberCount');
            Integer cb = (Integer) b.get('memberCount');
            return cb - ca;
        }
    }

    private class OverlapCountComparator implements Comparator<Map<String, Object>> {
        public Integer compare(Map<String, Object> a, Map<String, Object> b) {
            Integer ca = (Integer) a.get('overlapCount');
            Integer cb = (Integer) b.get('overlapCount');
            return cb - ca;
        }
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

    public static List<Map<String, Object>> getProfileExplorer(String searchTerm) {
        String safe = searchTerm != null ? searchTerm.replace('\'', '\'\'') : '';
        String whereClause = (safe.length() >= 2)
            ? ' WHERE ui.ssot__FirstName__c LIKE \'%' + safe + '%\' OR ui.ssot__LastName__c LIKE \'%' + safe + '%\''
            : '';
        String sql = 'SELECT ui.ssot__Id__c, ui.ssot__FirstName__c, ui.ssot__LastName__c, COUNT(lnk.SourceRecordId__c) AS sourceProfiles '
            + 'FROM UnifiedIndividual__dlm ui '
            + 'LEFT JOIN IndividualIdentityLink__dlm lnk ON ui.ssot__Id__c = lnk.UnifiedRecordId__c '
            + whereClause
            + ' GROUP BY ui.ssot__Id__c, ui.ssot__FirstName__c, ui.ssot__LastName__c '
            + 'ORDER BY COUNT(lnk.SourceRecordId__c) DESC '
            + 'LIMIT 50';
        HttpResponse res = makePostRequest(
            '/services/data/' + API_VERSION + '/ssot/query-sql?dataspace=default',
            '{"sql": "' + sql.escapeJava() + '"}'
        );
        List<Map<String, Object>> profiles = new List<Map<String, Object>>();
        Integer statusCode = res.getStatusCode();
        if (statusCode == 200 || statusCode == 201) {
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> rows = (List<Object>) body.get('data');
            if (rows != null) {
                for (Object row : rows) {
                    List<Object> cols = (List<Object>) row;
                    Map<String, Object> profile = new Map<String, Object>();
                    profile.put('unifiedId',      cols[0] != null ? String.valueOf(cols[0]) : '');
                    profile.put('firstName',       cols[1] != null ? String.valueOf(cols[1]) : '');
                    profile.put('lastName',        cols[2] != null ? String.valueOf(cols[2]) : '');
                    profile.put('sourceProfiles',  cols[3] != null ? Integer.valueOf(String.valueOf(cols[3])) : 0);
                    profiles.add(profile);
                }
            }
        }
        return profiles;
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

    public static String getActivations() {
        HttpResponse res = makeGetRequest('/services/data/' + API_VERSION + '/ssot/activations');
        if (res.getStatusCode() == 200) return res.getBody();
        throw new CalloutException('Failed to get activations: ' + res.getStatus() + ' ' + res.getBody());
    }

    public static String getCalculatedInsights() {
        HttpResponse res = makeGetRequest('/services/data/' + API_VERSION + '/ssot/calculated-insights');
        if (res.getStatusCode() == 200) return res.getBody();
        throw new CalloutException('Failed to get calculated insights: ' + res.getStatus() + ' ' + res.getBody());
    }

    public static String getActivationPlatforms() {
        HttpResponse res = makeGetRequest('/services/data/' + API_VERSION + '/ssot/activation-external-platforms');
        if (res.getStatusCode() == 200) return res.getBody();
        throw new CalloutException('Failed to get activation platforms: ' + res.getStatus() + ' ' + res.getBody());
    }

    public static Map<String, Integer> getDmoCoverage() {
        List<String> dmos = new List<String>{
            'ssot__Individual__dlm',
            'UnifiedIndividual__dlm',
            'IndividualIdentityLink__dlm',
            'ssot__ContactPointEmail__dlm',
            'ssot__ContactPointPhone__dlm',
            'ssot__EngagementInteraction__dlm'
        };
        Map<String, Integer> coverage = new Map<String, Integer>();
        for (String dmo : dmos) {
            try {
                HttpResponse res = makePostRequest(
                    '/services/data/' + API_VERSION + '/ssot/query-sql?dataspace=default',
                    '{"sql":"SELECT COUNT() FROM ' + dmo + '"}'
                );
                coverage.put(dmo, extractCount(res));
            } catch (Exception e) {
                coverage.put(dmo, 0);
            }
        }
        return coverage;
    }

    public static String getDataTransforms() {
        HttpResponse res = makeGetRequest('/services/data/' + API_VERSION + '/ssot/data-transforms');
        if (res.getStatusCode() == 200) return res.getBody();
        throw new CalloutException('Failed to get data transforms: ' + res.getStatus() + ' ' + res.getBody());
    }

    public static String getDataStreams() {
        HttpResponse res = makeGetRequest('/services/data/' + API_VERSION + '/ssot/data-streams');
        if (res.getStatusCode() == 200) return res.getBody();
        throw new CalloutException('Failed to get data streams: ' + res.getStatus() + ' ' + res.getBody());
    }

    public static Map<String, Integer> getOrgContactPointCoverage() {
        Map<String, Integer> results = new Map<String, Integer>();
        results.put('total', 0);
        results.put('withEmail', 0);
        results.put('withPhone', 0);
        try {
            String totalSql = 'SELECT COUNT() FROM UnifiedIndividual__dlm';
            results.put('total', extractCount(makePostRequest('/services/data/' + API_VERSION + '/ssot/query-sql?dataspace=default', '{"sql":"' + totalSql.escapeJava() + '"}')));
        } catch (Exception e) {}
        try {
            String emailSql = 'SELECT COUNT() FROM UnifiedIndividual__dlm ui ' +
                'LEFT JOIN IndividualIdentityLink__dlm lnk ON ui.ssot__Id__c = lnk.UnifiedRecordId__c ' +
                'LEFT JOIN ssot__ContactPointEmail__dlm cpe ON lnk.SourceRecordId__c = cpe.ssot__PartyId__c ' +
                'WHERE cpe.ssot__Id__c IS NOT NULL';
            results.put('withEmail', extractCount(makePostRequest('/services/data/' + API_VERSION + '/ssot/query-sql?dataspace=default', '{"sql":"' + emailSql.escapeJava() + '"}')));
        } catch (Exception e) {}
        try {
            String phoneSql = 'SELECT COUNT() FROM UnifiedIndividual__dlm ui ' +
                'LEFT JOIN IndividualIdentityLink__dlm lnk ON ui.ssot__Id__c = lnk.UnifiedRecordId__c ' +
                'LEFT JOIN ssot__ContactPointPhone__dlm cpp ON lnk.SourceRecordId__c = cpp.ssot__PartyId__c ' +
                'WHERE cpp.ssot__Id__c IS NOT NULL';
            results.put('withPhone', extractCount(makePostRequest('/services/data/' + API_VERSION + '/ssot/query-sql?dataspace=default', '{"sql":"' + phoneSql.escapeJava() + '"}')));
        } catch (Exception e) {}
        return results;
    }
}
